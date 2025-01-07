# Monitoring the application and the infrastructure

## Mandatory part

Monitoring the application and the infrastructure is crucial to understand the behavior of the system and to detect possible issues.

- Everything in monitoring folder
- Drove the usage of kustomize
- without Helm
- Prometheus
  - ClusterRole for seeing metrics from pods!! (problem no documentation)
  - exporters
    - node-exporter
      - stats at node level
      - DaemonSet!!
    - cadvisor
      - stats at pod level
      - DaemonSet!!
  - `prometheus-config.yml` has jobs to scrape metrics
- Grafana
  - provisioned from file
    - /etc/grafana/provisioning/datasources <- grafana-datasources configmap ...
      - configMapGenerator (!!) in kustomization.yaml
  - OBA Dashboard
    - show main metrics (cite them)
    - put some screenshots
    - took inspiration from:
      - 1860 node-exporter
      - 13946 cAdvisor
      - 763 redis
    - some **PromQL** queries does not work with all ranges
    - colors etc
  - admin:admin

## Bonus part

### Collecting more specific metrics

One could collect more specific metrics...

- redis
  - used for cart
  - oliver006/redis_exporter
  - added to the cart pod using a patch `redis-exporter.patch.yaml`
  - Screenshot of dashboard
- gRPC
  - tried otel but not really implemented in the existent code
  - metrics extracted from checkoutservice (as example) Server
  - added using patches (explain patches)
  - built new image `albertopasqualetto/checkoutservice:monitoring`
  - we are new to golang
  - in `github.com/grpc-ecosystem/go-grpc-middleware/providers/prometheus` also Client metrics available
  - Then used for an example to get Placed Orders
  - need to start a server to expose metrics, used `github.com/prometheus/client_golang/prometheus/promhttp`
  - Screenshot of dashboard ?
- custom exporter
  - easy with golang libraries
  - used in productcatalogservice
  - added using patches (explain patches as above)
  - new image `albertopasqualetto/productcatalogservice:monitoring`
  - using `github.com/prometheus/client_golang/prometheus/promauto` to create custom metric of a counter
  - counter of retrieves of products
  - Screenshot of dashboard
  - ```go
    productRetrievalCounter = promauto.NewCounterVec(
      prometheus.CounterOpts{
          Name: "product_retrieval_count",
          Help: "Counter of retrieved products by ID",
      },
      []string{"product_id", "product_name"},
    )

    [...]

    productRetrievalCounter.WithLabelValues(found.Id, found.Name).Inc()
    ```
  - need to start a server to expose metrics, used `github.com/prometheus/client_golang/prometheus/promhttp`

### Raising alerts

- Alerts provisioned too in Grafana (should change to prometheus since it is named in the task text?)
- Send notifications to Telegram
  - [Bot](https://t.me/oba_grafana_alerts_bot)
  - [Channel](https://t.me/+GpjvzfmIGZM4NTk0)
- Alert are fired at startup because of no data
- list alerts... as examples
