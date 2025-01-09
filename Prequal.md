# Prequal

This paper presents **Prequal**, a load balancer for distributed multi-tenant systems aimed at minimizing real-time request latency. Unlike traditional systems that focus on equalizing CPU utilization across servers, Prequal uses **Requests-In-Flight (RIF)** and **latency** as its primary metrics to dynamically assign workloads. Prequal applies the **Power of d Choices paradigm (PodC)** to optimize server selection.

### Innovations
1. Combines **RIF** and **latency** using the **hot-cold lexicographic rule (HCL)**.
2. Introduces a novel **asynchronous probing mechanism**, which reduces overhead while maintaining fresh probing signals.

### Deployment Success
Prequal has been successfully deployed in real-world systems such as **YouTube**, achieving significant reductions in:
- Tail latency.
- Resource utilization.


## Weighted Round Robin (WRR)
The authors explore the operational environment of large-scale services like **YouTube**, comprising a network of jobs issuing millions of queries to distributed replicas.
They show that traditional load balancers like **Weighted Round Robin (WRR)** are insufficient for such systems, as they fail to account for the complexities of distributed systems and Prequal is proposed as a solution.

### How WRR Works
**Weighted Round Robin (WRR)** uses smoothed historical statistics for each replica to periodically compute weights. These include:
- **Goodput** (successful query rate).
- **CPU utilization**.
- **Error rate**.

The weight for each replica, \( w_i \), is calculated as:

\[
w_i = \frac{q_i}{u_i}
\]

Where:
- \( q_i \): Queries per second (QPS) for replica \( i \).
- \( u_i \): CPU utilization of replica \( i \).

### Limitation of WRR
While WRR performs well if all replicas stay within their CPU allocations, overload is common and occurs even at small timescales. In such cases, WRR fails to handle the complexities of distributed systems, particularly under high-load spikes, leading to:
- Increased tail latencies.
- Service-level objective (SLO) violations.


## System Design
Prequal dynamically adjusts load balancing by combining two key signals:
1. **Requests-In-Flight (RIF)**.
2. **Latency**.

### Probing Rate
Prequal issues a specified number of probes (\( r_{\text{probe}} \)) triggered by each query. More probes may be issued after a maximum idle time. The **probing rate** is linked to the **query rate**, ensuring up-to-date information while minimizing redundant probes.

Probing targets are sampled randomly from available replicas to avoid the **thundering herd phenomenon**, where multiple clients inundate a single replica with low latency, leading to queuing and increased delays.

### Load Signals
When responding to a probe:
- **RIF**: Checked from the counter, providing an instantaneous signal.
- **Latency**: Estimated from recently completed queries. The median latency for recent queries with similar RIF values is returned.

### Probe Pool
Prequal maintains a **probe pool** containing responses for selecting replicas. Key features:
- Maximum size is capped (e.g., 16, as this proved optimal).
- Probes are replaced based on age and relevance to ensure freshness.

### Replica Selection
Prequal uses the **Hot-Cold Lexicographic (HCL) Rule**:
- **Hot** replicas: RIF exceeds a quantile threshold \( Q_{\text{RIF}} \).
- **Cold** replicas: RIF below \( Q_{\text{RIF}} \).

**Selection logic**:
1. If all replicas are hot, select the one with the lowest RIF.
2. If at least one is cold, select the cold replica with the lowest latency.
3. If the pool is empty, fallback to a random selection.

This approach balances load effectively while minimizing latency.


## Error Handling
### Sinkholing Prevention
A problematic replica may process queries quickly by returning errors, making it seem less loaded. This behavior, known as **sinkholing**, can attract more traffic, exacerbating issues. Prequal avoids this using heuristic-based safeguards.


## Performance Evaluation
### Observed Improvements
Prequal consistently outperformed WRR in both real-world deployments (e.g., YouTube) and test environments:
- **2x reduction** in tail latency and CPU utilization.
- **5–10x reduction** in tail RIF.
- **10–20% reduction** in memory usage.
- Near-elimination of errors due to load imbalances.

### Robustness
Prequal proved beneficial regardless of whether other services in the network used it. It works efficiently across diverse job types and query processing requirements (e.g., CPU, RAM, latency).


## Key Innovations of Prequal
1. **Asynchronous Probing**: Ensures real-time updates without impacting query processing.
2. **Hot-Cold Lexicographic Rule**: Balances the trade-off between load and latency.
3. **Error Aversion**: Safeguards against issues like sinkholing.
4. **Optimized Resource Usage**: Reduces tail latencies and overhead while enabling higher utilization.


## Canary Release and load balancer
The load balancer is stright related to the Canary Release that we had to build during the project.

A canary release is a deployment strategy where a new version of an application or service is gradually rolled out to a subset of users before a full-scale release.

In our example, we introduced a new version of the frontend service. Initially, we configured the load balancer with static weights to gradually route traffic between versions. Later, we automated this process using Flagger.

We monitored the results through the load balancer, which allowed us to collect metrics for comparison. In the event of errors or degraded performance, the load balancer facilitated an automatic rollback to ensure system stability.

The load balancer is central to implementing a canary release:

- The load balancer splits incoming traffic between the existing version and the new version  of the application.
    - For example in our case, 75% of traffic might go to the stable version (V1), while 25% is routed to the new version (V2) of the frontend.

- The load balancer allows you to monitor the performance of the new version in real-time by isolating the subset of traffic it handles.
If issues are detected in the canary deployment, the load balancer can instantly stop routing traffic to the new version, reverting all traffic to the stable version.

- As confidence in the new version grows, the load balancer can progressively increase the proportion of traffic routed to the canary version until it eventually serves 100% of the traffic. As we did with Flugger in our example.

More specifically in our approach Istio's Ingress Gateway was used as a load balancer to route traffic between the two versions of the frontend service. The Istio Gateway and VirtualService resources were configured to split traffic between the two versions declared in DestinationRule resources based on the weight assigned to each; Flagger operates automatically generating the cited resources.

### Future Works taking inspiration from Prequal

Prequal system may be implemented in the load balancer which selects which release (primary or canary) to distribute at each request, but since the release of a canary version is rare, the improvements could not be so noticeable.

Instead, Prequal dynamics can be implemented with more effectiveness in the load balancing system used to manage more pods hosting the same microservice version managed by HorizonalPodAutoscaler in Kubernetes.

#### Leveraging Prequal for Autoscaling in Kubernetes

Traditional Kubernetes autoscaling relies on metrics such as CPU and memory utilization. However, these metrics may not capture key load signals for applications that must respond to real-time traffic spikes. By utilizing signals provided by Prequal, such as Requests-in-Flight (RIF) and estimated latency, we can design a more responsive and optimized auto scaling system tailored for the project.

##### Development Plan

1. Prometheus Configuration:
        Set up Prometheus to collect Prequal signals such as the number of Requests-in-Flight and estimated latency.

2. Horizontal Pod Autoscaler (HPA):
        Configure the HPA to respond to custom metrics based on Prequal signals.

3. Load Variation Monitoring:
        Observe how the HPA responds to changes in load and traffic patterns.

4. Performance Analysis:
        Evaluate the effectiveness of the implementation and identify potential improvements.
