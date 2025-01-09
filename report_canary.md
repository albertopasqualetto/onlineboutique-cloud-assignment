# TODO da sistemare
# Canary releases (Mandatory)

## 75/25 split

- `istioctl manifest install --set profile=default` to install Istio
- `kubectl label namespace default istio-injection=enabled` to enable istio sidecar injection to all pods in the default namespace for simplicity (probably `kubectl apply -k .` should be run after this)
- this driven the always use of Istio
- `cat .\canary-version\static-split\deploy.run | pwsh -` (or other shell-dependent command) to deploy the split canary deployment, some things are already in the main deployment
  - label v1 is needed for 75/25 split

## Flagger

- `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/prometheus.yaml` not using the same as monitoring because it is easier and already has the necessary configuration

When wanting to deploy a canary release:

- `kubectl apply -f .\canary-version\flagger-canary.yaml` to setup Flagger Canary, then wait for *frontend-primary* pod to be created and *frontend* to be deleted (`kubectl wait --for=delete pod -l app=frontend --timeout=300s`)
- `kubectl set image deployment/frontend server=albertopasqualetto/oba-frontend:v2` to trigger Flagger to start the canary deployment, this version of the frontend has an additional endpoint: `/v2.txt`, which is used to differentiate the versions, the dockerfile is in the canary folder
- describe files
- Can check progress with `kubectl describe canary/frontend`
- A useful dashboard: `kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/release-1.24/samples/addons/kiali.yaml`; `kubectl rollout status deployment/kiali -n istio-system`; `istioctl dashboard kiali`

- when rollout is automatic with flagger, the canary version is deployed slowly to an increasing percentage of requests; when requests are not happening, canary deployment is paused


## Canary Release

We deployed a Canary Release strategy to introduce a new version of the microservice `frontend`. This strategy ensures a gradual and safe transition from `v1` to `v2` of the service while monitoring system performance and user experience.

### Steps

#### 1. Dockerfile Version

We created new Docker images (`albertopasqualetto/oba-frontend:v2`, `albertopasqualetto/oba-frontend:v3`) with small differences between each version.

#### 2. Setting Up Istio with Helm

We installed and set up Istio as outlined in the documentation:

```bash
# Add Istio Helm repository
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Install Istio base
helm install istio-base istio/base -n istio-system

# Install Istiod
helm install istio-base istio/base -n istio-system

# Install Ingress Gateway
helm install istio-ingressgateway istio/gateway -n istio-system --wait
```

#### 3. Setting Up Prometheus with Helm

We installed Prometheus to analyze the traffic:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus --namespace istio-system
```

#### 4. Setting Up Grafana

We installed Grafana to plot the results provided by Prometheus queries:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

#### 5. Deploying Frontend Versions

- **Deploy Primary Frontend Version:**

  ```bash
  kubectl apply -k .
  ```

- **Deploy Frontend v2:**

  ```bash
  kubectl apply -f ./canary-version/frontend-v2
  ```

#### 6. Configuring Istio

- **Istio Gateway Configuration:**

  ```bash
  kubectl apply -f gateway.yaml
  ```

- **VirtualService Configuration:**
  
  Configured to split traffic, with 75% routed to `v1` and 25% routed to `v2` initially:

  ```bash
  kubectl apply -f ./canary-release/frontend-virtualservice.yaml
  ```

- **DestinationRule Configuration:**

  Defined subsets for `v1` and `v2` using appropriate labels:

  ```bash
  kubectl apply -f ./canary-release/frontend-destinationrule.yaml
  ```

#### 7. Generating Traffic

We used Locust to generate traffic and test the Canary Release deployment.

- **Locustfile:**

  ```python
  from locust import HttpUser, task, between

  class FrontendUser(HttpUser):
      host = "http://34.27.165.38"
      wait_time = between(1, 5)

      @task
      def index(self):
          self.client.get("/")

      @task(2)
      def product_page(self):
          self.client.get("/product/OLJCESPC7Z")
  ```

- **Using Locust Interface:**

  In the Locust interface, we set the number of users to generate requests per second and monitored the system’s performance.

  ![Locust Interface](./images/locust-interface.png)

- **Monitoring with Prometheus and Grafana:**

  We analyzed traffic and performance metrics using Prometheus queries and Grafana dashboards.

#### 8. Automating the Canary Release with Flagger

- **Flagger Installation:**

  ```bash
  kubectl apply -k github.com/fluxcd/flagger/kustomize/istio
  ```

- **Flagger Canary Configuration:**

  ```yaml
  apiVersion: flagger.app/v1beta1
  kind: Canary
  metadata:
    name: frontend
    namespace: default
  spec:
    provider: istio
    targetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: frontend
    service:
      port: 80
      hosts:
        - "*"
    analysis:
      interval: 1m
      threshold: 5
      maxWeight: 50
      stepWeight: 10
      metrics:
        - name: request-success-rate
          threshold: 99
        - name: request-duration
          threshold: 500
  ```

- **Monitoring Canary Progress:**

  We monitored the progress by analyzing metrics and gradually shifting traffic:

  ```bash
  kubectl get canaries
  ```

---

### Results

- **Traffic Generation with Locust:**

  Traffic was generated correctly, as shown in the Locust interface:

  ![Requests](./images/requests.png)

- **Prometheus Metrics:**

  Queries showed the expected traffic distribution:

  ![Prometheus Query](./images/prom-perc-query.png)

- **Grafana Dashboard:**

  The plotted data demonstrated the performance of both versions:

  ![Grafana Plot](./images/grafana-plot.png)

