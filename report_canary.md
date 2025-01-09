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

- `kubectl apply -k github.com/fluxcd/flagger/kustomize/istio` to install Flagger.
- `kubectl apply -f .\canary-version\flagger-canary.yaml` to setup Flagger Canary, then wait for *frontend-primary* pod to be created and *frontend* to be deleted (`kubectl wait --for=delete pod -l app=frontend --timeout=300s`)
- `kubectl set image deployment/frontend server=albertopasqualetto/oba-frontend:v2` to trigger Flagger to start the canary deployment, this version of the frontend has an additional endpoint: `/v2.txt`, which is used to differentiate the versions, the dockerfile is in the canary folder
- describe files
- Can check progress with `kubectl describe canary/frontend`
- A useful dashboard: `kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/release-1.24/samples/addons/kiali.yaml`; `kubectl rollout status deployment/kiali -n istio-system`; `istioctl dashboard kiali`

- when rollout is automatic with flagger, the canary version is deployed slowly to an increasing percentage of requests; when requests are not happening, canary deployment is paused


## Canary Release

We deployed a Canary Release strategy to introduce a new version of the microservice `frontend`. This strategy ensures a gradual and safe transition from `v1` to `v2` of the service while monitoring system performance and user experience.

### Steps

#### Dockerfile Version

We created new Docker images (`albertopasqualetto/oba-frontend:v2`, `albertopasqualetto/oba-frontend:v3`) with small differences between each version.

#### 75/25 Traffic Split


1. **Install Istio**:
   - Installed Istio with the default profile:
     ```bash
     istioctl manifest install --set profile=default
     ```
   - Enabled sidecar injection for all pods in the `default` namespace:
     ```bash
     kubectl label namespace default istio-injection=enabled
     ```

2. **Deploy Initial Application**:
   - Deployed the initial `frontend` application with the necessary configurations for the traffic split:
     ```bash
     kubectl apply -k .
     ```

3. **Static Traffic Split Configuration**:
   - Deployed a static 75/25 split for the `frontend` service using the following command:
     ```bash
     cat ./canary-version/static-split/deploy.run | pwsh -
     ```
     - The static split requires labeling `v1` and `v2` versions correctly in the deployment configuration.

4. **Traffic Distribution**:
   - Configured Istio’s `VirtualService` and `DestinationRule` to direct 75% of the traffic to `v1` and 25% to `v2`.

#### Deploying Frontend Versions

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
  ##### Results

- **Traffic Generation with Locust:**

  Traffic was generated correctly, as shown in the Locust interface:

  ![Requests](./images/requests.png)

- **Prometheus Metrics:**

  Queries showed the expected traffic distribution:

  ![Prometheus Query](./images/prom-perc-query.png)

- **Grafana Dashboard:**

  The plotted data demonstrated the performance of both versions:

  ![Grafana Plot](./images/grafana-plot.png)

#### 8. Automating the Canary Release with Flagger


# Canary Releases with Flagger

## Flagger Configuration

To set up Flagger for canary releases, the following steps were followed:

1. Applied Prometheus configuration from Istio's addon samples:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/prometheus.yaml
   ```
   This was chosen instead of the custom monitoring setup because it is easier to use and already includes the necessary configurations for integration with Flagger.

2. Installed Flagger with Istio support:
   ```bash
   kubectl apply -k github.com/fluxcd/flagger/kustomize/istio
   ```

3. Configured Flagger Canary for the `frontend` service:
   ```bash
   kubectl apply -f ./canary-version/flagger-canary.yaml
   ```
   After this step, the `frontend-primary` pod is created, and the old `frontend` pod is deleted. The following command ensures the deletion of the old pod:
   ```bash
   kubectl wait --for=delete pod -l app=frontend --timeout=300s
   ```

4. Triggered the canary deployment:
   ```bash
   kubectl set image deployment/frontend server=albertopasqualetto/oba-frontend:v2
   ```
   - The new version (`v2`) of the `frontend` includes an additional endpoint `/v2.txt` to distinguish between versions.
   - The corresponding Dockerfile is located in the `canary` folder.

---

## Progress Monitoring

To monitor the canary deployment's progress, use:
```bash
kubectl describe canary/frontend
```

### Additional Visualization
- A useful dashboard for Istio and Flagger:
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/release-1.24/samples/addons/kiali.yaml
  kubectl rollout status deployment/kiali -n istio-system
  istioctl dashboard kiali
  ```

---

## Behavior of Automatic Rollouts with Flagger

When the rollout is managed by Flagger:
- The canary version is progressively deployed to an increasing percentage of requests.
- If no traffic is detected, the canary deployment is paused until requests are received.

---

This setup ensures smooth and controlled canary releases while providing real-time monitoring and progress tracking through Flagger and Istio dashboards.

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
