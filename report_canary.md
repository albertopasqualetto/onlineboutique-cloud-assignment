# Canary releases (Mandatory)

- `istioctl manifest install --set profile=default` to install Istio
- `kubectl label namespace default istio-injection=enabled` to enable istio sidecar injection to all pods in the default namespace for simplicity (probably `kubectl apply -k .` should be run after this)
- `kubectl apply -k ./canary-version` to deploy the canary deployment, some things are already in the main deployment
  - label v1 is needed for 75/25 split
- `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/prometheus.yaml` not using the same as monitoring because it is easier and already has the necessary configuration
- `kubectl set image deployment/frontend server=albertopasqualetto/oba-frontend:v2` to trigger Flagger to start the canary deployment
- describe files
- A useful dashboard: `kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/release-1.24/samples/addons/kiali.yaml`; `kubectl rollout status deployment/kiali -n istio-system`; `istioctl dashboard kiali`


- whent rollout is automatic with flagger, the canary version is deployed slowly to an increasing percentage of requests; when requests are not happening, canary deployment is paused