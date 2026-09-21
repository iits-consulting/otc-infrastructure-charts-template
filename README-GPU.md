# Bonus: your LLM, deployed by ArgoCD

You added a GPU node pool in the
[terraform template](https://github.com/iits-consulting/otc-terraform-template/blob/main/README-GPU.md)
and ran a model on it with `kubectl apply`. Now let ArgoCD own it instead.

Every step is a task. Try it yourself, then open the solution.

**Before you start:** the GPU node reports `nvidia.com/gpu`, the `ai` DNS record exists,
and you deleted the hand-applied stack (`kubectl delete -f documentation/gpu-llm-stack.yaml`).

---

## Task 1: register the chart

`local-charts/gpu-llm/` is the same workload as the manifest, packaged as a chart: Ollama
on the GPU node plus Open WebUI in front of it. Make ArgoCD deploy it.

<details>
<summary>Solution</summary>

Add an entry under `charts:` in `infrastructure-charts/values.yaml`. It is a local chart,
so it only needs a `path`, like _basic-auth_. Repo and branch come from `global.git`:

```yaml
charts:
  # ... the entries which are already there
  gpu-llm:
    namespace: ai
    path: "local-charts/gpu-llm"
```

Commit and push. ArgoCD picks it up after 2 to 3 minutes.

`ingress.stageDomain` comes for free, `global.helm.parameters` injects it into every chart.

</details>

---

## Task 2: watch it come up and use it

The first sync is slow, and that is not ArgoCD's fault.

<details>
<summary>Solution</summary>

```shell
kubectl -n ai get pods -w
```

The Ollama image is 3.7 GB and the `postStart` hook then pulls the model, so the
Application sits in _Progressing_ for a few minutes. No ArgoCD problem, just bytes.

Then open `https://ai.YOUR-DOMAIN-NAME` and create an account, the first one becomes the
admin. Confirm the card is doing the work:

```shell
kubectl -n ai exec deploy/ollama -- ollama ps
```

</details>

---

## Task 3: swap the model without touching the cluster

Serve a different model. Do it the GitOps way, no `kubectl edit`.

<details>
<summary>Solution</summary>

```yaml
  gpu-llm:
    namespace: ai
    path: "local-charts/gpu-llm"
    parameters:
      model: "llama3.2:3b"
```

Commit, push, watch ArgoCD roll the deployment. That is the whole point of the exercise:
the model a GPU serves is a line in git, not something someone changed on a cluster at
02:00.

</details>

---

## Task 4: put it on the admin dashboard

The dashboard should link to it like every other service.

<details>
<summary>Solution</summary>

Add a tile in `infrastructure-charts/value-files/admin-dashboard/values.yaml`. The full
tile list is in the chart itself, `local-charts/kumoops-admin-dashboard/values.yaml`.
There is no tile for a self hosted LLM, so add your own under `defaultDashboard.tiles`
with `enabled: true` plus `href`, `imgSrc`, `imgAlt` and `category`, the chart's
`values.schema.json` requires all four.

</details>

---

## Freestyle

Pick one, talk it through with your tutor:

- **Scale the GPU pool to zero.** Set `node_scaling_enabled = true` and
  `node_count = 0` in `gpu_node_pool.tf`. The autoscaler boots a GPU node only
  when a pod is pending. What breaks, and how long does the first request take?
- **Add RAG.** Pull an embedding model such as `nomic-embed-text` and point Open WebUI at
  it for document search. Where does the vector store live?
- **Share the card.** One T4, several teams. Time slicing, MIG, or a queue in front of
  Ollama. Which one fits here?
- **Protect it properly.** Right now anyone who can sign up gets your GPU. Put the
  `oidc-forward-auth` middleware in front of the IngressRoute instead.

---

> [!CAUTION]
> The GPU node keeps billing. When you are done, delete the `gpu-llm` entry, push, and
> follow task 5 in the terraform template README.
