# Canary releases (Mandatory)

- `istioctl manifest install --set profile=default` to install istio
- `kubectl label namespace default istio-injection=enabled` to enable istio sidecar injection to all pods in the default namespace for simplicity
- `kubectl apply -k ./canary-version` to deploy the canary deployment, some things are already in the main deployment
  - label v1 is needed for 75/25 split
- `kubectl set image deployment/frontend server=albertopasqualetto/oba-frontend:v2` to trigger Flagger to start the canary deployment
- describe files
- `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/prometheus.yaml` # TODO check if can use the same as in monitoring
