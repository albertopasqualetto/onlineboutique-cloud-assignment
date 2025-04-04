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

# https://github.com/GoogleCloudPlatform/microservices-demo

# modified from the original to add new v3 endpoint to frontend and additional delay

FROM golang:1.23.2-alpine@sha256:9dd2625a1ff2859b8d8b01d8f7822c0f528942fe56cfe7a1e7c38d3b8d72d679 AS builder

# Download source code
RUN apk add --no-cache git
RUN git clone --depth 1 --branch v0 https://github.com/GoogleCloudPlatform/microservices-demo.git
RUN mv microservices-demo/src/frontend /src

WORKDIR /src

# restore dependencies
# COPY go.mod go.sum ./
RUN go mod download
# COPY . .

# version v2
RUN sed -i '/r := mux.NewRouter()/a\\tr.HandleFunc(baseUrl + "/v2.txt", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "THIS IS VERSION v2") })' main.go

# version v3
RUN sed -i '/r := mux.NewRouter()/a\\tr.HandleFunc(baseUrl + "/v3.txt", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "THIS IS VERSION v3") })' main.go
RUN sed -i '/import (/a\\t"strings"' main.go
RUN sed -i '/r := mux.NewRouter()/a\\tr.Use(func(next http.Handler) http.Handler { return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { if !strings.Contains(r.URL.Path, "_healthz") { time.Sleep(3 * time.Second) }; next.ServeHTTP(w, r) }) })' main.go

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS
RUN CGO_ENABLED=0 GOOS=linux go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /go/bin/frontend .

FROM scratch
WORKDIR /src
COPY --from=builder /go/bin/frontend /src/server
COPY --from=builder ./src/templates ./templates
COPY --from=builder ./src/static ./static
# COPY ./templates ./templates
# COPY ./static ./static

# Definition of this variable is used by 'skaffold debug' to identify a golang binary.
# Default behavior - a failure prints a stack trace for the current goroutine.
# See https://golang.org/pkg/runtime/
ENV GOTRACEBACK=single

EXPOSE 8080
ENTRYPOINT ["/src/server"]