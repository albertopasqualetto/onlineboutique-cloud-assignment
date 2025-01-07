# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# adds prometheus metrics export

FROM golang:1.23.2-alpine@sha256:9dd2625a1ff2859b8d8b01d8f7822c0f528942fe56cfe7a1e7c38d3b8d72d679 AS builder

WORKDIR /src

# Download source code
ADD https://github.com/GoogleCloudPlatform/microservices-demo.git#v0:src/productcatalogservice/ .

# Apply patches to code
RUN apk add --no-cache patch
COPY productcatalogservice.patch .
RUN patch -p1 < productcatalogservice.patch

# restore dependencies
RUN go mod download
RUN go get github.com/prometheus/client_golang/prometheus && \
go get github.com/prometheus/client_golang/prometheus/promauto && \
go get github.com/prometheus/client_golang/prometheus/promhttp

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS
RUN CGO_ENABLED=0 GOOS=linux go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /productcatalogservice .

FROM scratch

WORKDIR /src
COPY --from=builder /productcatalogservice ./server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /src/products.json .

# Definition of this variable is used by 'skaffold debug' to identify a golang binary.
# Default behavior - a failure prints a stack trace for the current goroutine.
# See https://golang.org/pkg/runtime/
ENV GOTRACEBACK=single

EXPOSE 3550
EXPOSE 9090
ENTRYPOINT ["/src/server"]
