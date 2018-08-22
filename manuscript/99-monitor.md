# Monitoring

## Cluster

* [gke-scale.sh](TODO): TODO
* [eks-scale.sh](TODO): TODO
* [aks-scale.sh](TODO): TODO
* [docker-scale.sh](TODO): TODO
* [minikube-scale.sh](TODO): TODO
* [minishift-scale.sh](TODO): TODO

## Prometheus Chart

```bash
PROM_ADDR=mon.$LB_IP.nip.io

echo $PROM_ADDR

helm install stable/prometheus \
    --name prom \
    --namespace metrics \
    --set server.ingress.enabled=true \
    --set server.ingress.hosts={$PROM_ADDR}

kubectl -n metrics \
    rollout status \
    deploy prom-prometheus-server

open "http://$PROM_ADDR/config"

open "http://$PROM_ADDR/targets"

open "http://$PROM_ADDR/graph"

# kube_node_status_allocatable_cpu_cores

# kube_node_status_allocatable_memory_bytes

# kube_node_status_allocatable_pods

# TODO: Understand the metrics from the targets

GD5_ADDR=go-demo-5.$LB_IP.nip.io

echo $GD5_ADDR

helm upgrade -i go-demo-5 \
    ../go-demo-5/helm/go-demo-5 \
    --namespace go-demo-5 \
    --set ingress.host=$GD5_ADDR

kubectl -n go-demo-5 \
    rollout status deployment go-demo-5

for i in {1..100}; do
    curl "http://$GD5_ADDR/demo/hello"
done

open "http://$MON_ADDR/graph"

# container_memory_usage_bytes{pod_name!=""}

# container_memory_usage_bytes{pod_name!=""} / container_spec_memory_limit_bytes{pod_name!=""}

# container_memory_usage_bytes{namespace="go-demo-5"}

# sum(container_memory_usage_bytes{namespace="go-demo-5"})

# container_memory_usage_bytes{pod_name=~"go-demo-5-db.+"}

# container_memory_usage_bytes{pod_name=~"go-demo-5-db.+", container_name="db"}

# container_memory_usage_bytes{pod_name=~"go-demo-5-db.+", container_name="db"} / container_spec_memory_limit_bytes{pod_name=~"go-demo-5-db.+", container_name="db"}

# nginx_ingress_controller_requests

# nginx_ingress_controller_requests{ingress="go-demo-5", namespace="go-demo-5"}

# rate(nginx_ingress_controller_requests{ingress="go-demo-5", namespace="go-demo-5"}[5m])

for i in {1..30}; do
    DELAY=$[ $RANDOM % 6000 ]
    curl "http://$GD5_ADDR/demo/hello?delay=$DELAY"
done

# nginx_ingress_controller_response_duration_seconds_bucket{ingress="go-demo-5", namespace="go-demo-5"}

# nginx_ingress_controller_response_duration_seconds_bucket{ingress="go-demo-5", namespace="go-demo-5", le="0.5"}

# rate(nginx_ingress_controller_response_duration_seconds_bucket{ingress="go-demo-5", namespace="go-demo-5", le="0.5"}[5m])

# nginx_ingress_controller_response_duration_seconds_count{ingress="go-demo-5", namespace="go-demo-5"}

# rate(nginx_ingress_controller_response_duration_seconds_count{ingress="go-demo-5", namespace="go-demo-5"}[5m])

# rate(nginx_ingress_controller_response_duration_seconds_sum{ingress="go-demo-5", namespace="go-demo-5"}[5m]) / rate(nginx_ingress_controller_response_duration_seconds_count{ingress="go-demo-5", namespace="go-demo-5"}[5m])

# node_memory_MemTotal_bytes

# node_memory_MemFree_bytes

# node_memory_MemAvailable_bytes

# up

# sum(up{job="kubernetes-nodes", kubernetes_io_role="master"})
```

# Instrumentation

```bash
# http_server_resp_time_count

# sum(rate(http_server_resp_time_count[5m]))

# http_server_resp_time_sum / http_server_resp_time_count

for i in {1..30}; do
    DELAY=$[ $RANDOM % 6000 ]
    curl "http://$GD5_ADDR/demo/hello?delay=$DELAY"
done

# http_server_resp_time_sum / http_server_resp_time_count

# rate(http_server_resp_time_sum[5m]) / rate(http_server_resp_time_count[5m])

# rate(http_server_resp_time_sum{service="go-demo"}[5m]) / rate(http_server_resp_time_count{service="go-demo"}[5m])

# rate(http_server_resp_time_sum{kubernetes_name="go-demo-5", kubernetes_namespace="go-demo-5"}[5m]) / rate(http_server_resp_time_count{kubernetes_name="go-demo-5", kubernetes_namespace="go-demo-5"}[5m])

# sum(rate(http_server_resp_time_sum[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_sum[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name) > 0.1

# sum(rate(http_server_resp_time_bucket{le="0.1"}[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_bucket{kubernetes_name="go-demo-5",le="0.1"}[5m])) / sum(rate(http_server_resp_time_count{kubernetes_name="go-demo-5"}[5m]))

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name)

for i in {1..300}; do
    curl "http://$GD5_ADDR/demo/random-error"
done

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name)
```

## Using Prometheus To Better Define Resources

TODO: Code

## Alertmanager

TODO: Code

## PushGateway

TODO: Core

## Grafana Chart

TODO: Verify

```bash
GRAFANA_ADDR="grafana.$LB_IP.xip.io"

helm install stable/grafana \
    --name grafana \
    --namespace mon \
    --set ingress.enabled=true \
    --set ingress.hosts="{$GRAFANA_ADDR}" \
    --set persistence.enabled=true \
    --set persistence.accessModes="{ReadWriteOnce}" \
    --set persistence.size=1Gi

kubectl -n mon \
    rollout status deploy grafana

# Automate Prometheus config

open "http://$GRAFANA_ADDR"

echo $(kubectl get secret \
    -n mon grafana \
    -o go-template \
    --template="{.data.admin-password | base64decode}")

echo "http://$MON_ADDR"

# Import dashboards 3131, 1621
```

## Something

```bash
TODO: Operator

TODO: tools

TODO: tools-production

TODO: heapster

TODO: best-practices

TODO: prometheus-fast

TODO: prometheus-2

TODO: prom-repo

TODO: gs-repo

TODO: prom-operator

TODO: https://github.com/stakater/IngressMonitorController
```

## Destroying The Cluster

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```