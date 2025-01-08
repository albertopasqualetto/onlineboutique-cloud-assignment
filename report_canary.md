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
