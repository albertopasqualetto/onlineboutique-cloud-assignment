# Autopilot

Autopilot is a GKE operation mode in which Google manages also the cluster configuration (nodes, scaling, security, ...).
As described in table at https://cloud.google.com/kubernetes-engine/docs/resources/autopilot-standard-feature-comparison "Autopilot manages nodes", "Autopilot automatically scales the quantity and size of nodes based on Pods in the cluster" and provides as node compute configuration a "General-purpose platform that is optimized for most workloads, hence it hides the cluster configuration to the user (compared to standard mode) and so it hides the problem of too low resources given by default GKE cluster setup in standard mode.

# Configuration explanation

In the `kubernetes-manifests.yaml` file, there is the configuration of all the Online Boutique services.

For each service there is the specification of the `Deployment`, 1 or more `Service`s and a `ServiceAccount`.

Below there is an extract of the file related to frontend service.

```
# [...]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
    spec:
      serviceAccountName: frontend
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000
      containers:
        - name: server
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            privileged: false
            readOnlyRootFilesystem: true
          image: gcr.io/google-samples/microservices-demo/frontend:v0.10.1
          ports:
          - containerPort: 8080
          readinessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 8080
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-readiness-probe"
          livenessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 8080
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-liveness-probe"
          env:
          - name: PORT
            value: "8080"
          - name: PRODUCT_CATALOG_SERVICE_ADDR
            value: "productcatalogservice:3550"
          - name: CURRENCY_SERVICE_ADDR
            value: "currencyservice:7000"
          - name: CART_SERVICE_ADDR
            value: "cartservice:7070"
          - name: RECOMMENDATION_SERVICE_ADDR
            value: "recommendationservice:8080"
          - name: SHIPPING_SERVICE_ADDR
            value: "shippingservice:50051"
          - name: CHECKOUT_SERVICE_ADDR
            value: "checkoutservice:5050"
          - name: AD_SERVICE_ADDR
            value: "adservice:9555"
          - name: SHOPPING_ASSISTANT_SERVICE_ADDR
            value: "shoppingassistantservice:80"
          # # ENV_PLATFORM: One of: local, gcp, aws, azure, onprem, alibaba
          # # When not set, defaults to "local" unless running in GKE, otherwies auto-sets to gcp
          # - name: ENV_PLATFORM
          #   value: "aws"
          - name: ENABLE_PROFILER
            value: "0"
          # - name: CYMBAL_BRANDING
          #   value: "true"
          # - name: ENABLE_ASSISTANT
          #   value: "true"
          # - name: FRONTEND_MESSAGE
          #   value: "Replace this with a message you want to display on all pages."
          # As part of an optional Google Cloud demo, you can run an optional microservice called the "packaging service".
          # - name: PACKAGING_SERVICE_URL
          #   value: "" # This value would look like "http://123.123.123"
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
  - name: http
    port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-external
  labels:
    app: frontend
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - name: http
    port: 80
    targetPort: 8080
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend
---
# [...]
```

- apiVersion: is the API version of the relative configuration specification piece.
- kind: is the type of the current object, here there are `Deployment`, `Service` and `ServiceAccount` kinds.
- metadata: configure the name and labels of the current object, in this piece of manifest all objects have "frontend" name except one service with "frontend-external" name and all objects have "app: frontend" label.
- spec: is the configuration specification for the object.

frontend Deployment spec:
- selector.matchLabels.app: frontend: defines which pods are affeted by this deployment and it must match the pod template's labels.
- template:
    - metadata:
        - labels.app: frontend: name of the app.
        - annotations: sidecar.istio.io/rewriteAppHTTPProbers: "true": tells a possible Istio instance (a sidecar software which provides observability, traffic management and security) to rewrite readiness and liveness probes to be redirected through Istio.
    - spec:
        - serviceAccountName: frontend: is the name of the ServiceAccount used by this deployment.
        - securityContext: pod-level security attributes. Adds an additional group to the all the containers in the pod (fsGroup: 1000), sets the user id (runAsUser: 1000) and the group id (runAsGroup: 1000) to run the entrypoint process of the containers with, and indicates that the container must run as non-root user (runAsNonRoot: true).
        - containers: define the list of containers belonging to the pod; "server" is the name of the only defined container.
            - securityContext: sets some security capabilities of the container in order to harden security.
                - allowPrivilegeEscalation: false: prevents processes to gain more privileges than parent processes. 
                - capabilities.drop: [ALL]: denies all POSIX capabilities https://man.archlinux.org/man/capabilities.7 which are related to a fine-grained "superuser" permissions system.
                - privileged: false: runs the container in non-privileged/root mode.
                - readOnlyRootFilesystem: true: sets the filesystem as read-only (container is stateless though).
            - image: specifies the container image to use
            - ports.containerPort: 8080: specifies the container's port to be exposed on the pod's IP address; 8080 is a common port for HTTP traffic.
            - readinessProbe: defines how to check if the container is ready. Readiness is used to indicate whether the container is ready to respond to requests; the container will not receive requests while it is not ready. It requires a delay after the container start (initialDelaySeconds: 10), it needs to execute an HTTP GET request (httpGet) to a specific endpoint (path: "/_healthz", port: 8080) with some specific headers ("Cookie":"shop_session-id=x-readiness-probe").
            - livenessProbe: defines how to check if the container is live. Liveness is used to kill and possibly restart the container if the probe tells the container is not live.
            It requires a delay after the container start (initialDelaySeconds: 10), it needs to execute an HTTP GET request (httpGet) to a specific endpoint (path: "/_healthz", port: 8080) with some specific headers ("Cookie":"shop_session-id=x-liveness-probe").
            - env: sets the environment variables needed for this image.
            - resources: sets the minimum (requests) and maximum (limits) CPU and memory usage; in this case between 100m and 200m CPU units and between 64Mi and 128Mi bytes of memory.

frontend Service spec:
    - type: ClusterIP: defines the type of this service; ClusterIP exposes the defined service on a cluster-internal IP. It is used for intra-cluster communication.
    - selector.app: frontend: routes service traffic to pods with matching labels; in this case the previously defined deployment.
    - ports: defines the ports exposed by this service; in this case it exposes the external port 80, binding it to internal port 8080 with name "http".
    
frontend-external Service spec:
    - type: LoadBalancer: defines the type of this service; LoadBalancer requests an external LoadBalancer (GCP provides one automatically) which has a public IP address and its own load balancing rules; and exposes the defined service to that load balancer. It is used to expose deployments to the internet.
    - selector.app: frontend: routes service traffic to pods with matching labels; in this case the previously defined deployment.
    - ports: defines the ports exposed by this service; in this case it exposes the external port 80, binding it to internal port 8080 with name "http".
    
frontend ServiceAccount has no spec definition. A ServiceAccount is a non-human user; it is used to interact with a distinct identity with Kubernetes.