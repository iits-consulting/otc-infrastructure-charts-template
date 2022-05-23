# Elastic Stack setup

This chart installs Elastic Stack (with Filebeat instead of Logstash) stack without ingress controller for Kibana.
The latter must be installed separately

## Setup

Register Elasticsearch repository in Helm

```bash
$ helm repo add elastic https://helm.elastic.co
```

Jump into Elastic Stack directory

```bash
$ cd elastic-stack
```

Download official charts of Elasticsearch, Filebeat, and Kibana

```bash
$ helm dependency update 
```

Install Elastic Stack stack via Helm

```bash
$ helm install . --name elastic-stack --namespace monitoring
```