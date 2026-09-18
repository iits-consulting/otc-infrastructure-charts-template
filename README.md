# Blueprint: T Cloud Public GitOps charts

<table>
<tr>
<td width="290" valign="top">
<img src="documentation/kumo-gitops.webp" alt="Kumo deploys charts with GitOps" width="270" />
</td>
<td valign="top">

This is the charts side of the workshop. The cluster already exists, ArgoCD is already
running, and from here on every service is deployed by committing YAML into this
repository.

The _infrastructure-charts_ helm chart is installed by OpenTofu and follows the
[app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern):
every entry you add turns into an ArgoCD Application.

**Plan about 30 minutes**, most of it waiting for ArgoCD to sync.

</td>
</tr>
</table>

> [!IMPORTANT]
> This workshop just teaches the basics. For a proper and secure production setup
> please contact us at kontakt@iits-consulting.de

## Contents

1. [What this repository does](#1-what-this-repository-does)
   - [How this repository is laid out](#how-this-repository-is-laid-out)
2. [Requirements](#2-requirements)
3. [Access the ArgoCD UI](#3-access-the-argocd-ui)
4. [Deploy some charts and services](#4-deploy-some-charts-and-services)
5. [Change the values of a chart](#5-change-the-values-of-a-chart)
6. [Hand over variables from OpenTofu to ArgoCD](#6-hand-over-variables-from-opentofu-to-argocd)
7. [Integrate business apps](#7-integrate-business-apps)
- [Appendix A: try out the setup](#appendix-a-try-out-the-setup)

---

## 1. What this repository does

OpenTofu installs exactly one helm chart, _infrastructure-charts_. That chart does not
deploy any workload itself, it only creates ArgoCD Applications out of the entries below
the `charts:` key in its `values.yaml`. ArgoCD then pulls each chart from wherever the
entry points to and keeps it in sync with this repository.

So the loop is always the same: edit `values.yaml`, commit, push, wait 2 to 3 minutes.

### How this repository is laid out

| Path | What it holds |
| --- | --- |
| `infrastructure-charts/values.yaml` | The list of services under `charts:`, plus the global helm registry and the parameters injected into every chart |
| `infrastructure-charts/values-dev.yaml` | Stage specific overrides, picked up through the `stage` value handed over by OpenTofu |
| `infrastructure-charts/value-files/` | A complete `values.yaml` per chart, referenced by `valueFile:` |
| `infrastructure-charts/templates/applications.yaml` | Turns every entry under `charts:` into an ArgoCD Application |
| `local-charts/` | Charts that live in this repository, for example _basic-auth_ |

> [!TIP]
> [Helm tpl](https://helm.sh/docs/howto/charts_tips_and_tricks/#using-the-tpl-function) is
> supported inside `values.yaml` and inside the files under `value-files/`, so you can
> reuse values like `{{.Values.projectValues.stageDomain}}` anywhere.

---

## 2. Requirements

1. Create a fork of this repository first, because the OpenTofu setup points ArgoCD at
   your fork
2. Set up the infrastructure according to the README within
   [this Github Template](https://github.com/iits-consulting/otc-terraform-template)
3. Replace the `repoURL` inside `infrastructure-charts/values.yaml` with the URL of your
   fork, it is marked with `# Replace this with yours!`

---

## 3. Access the ArgoCD UI

If you did not source the `shell-helper.sh` in the
https://github.com/iits-consulting/otc-terraform-template project please do so by running:

```shell
source shell-helper.sh
```

Now you are able to execute the `argo` command. It does the following:

1. Print out the username and the password on the first line
2. Open a browser tab with the ArgoCD UI. If no browser opens, use this url yourself:
   http://localhost:8080/argocd
3. Show you that ArgoCD already installed multiple charts

If all services are up and running you can also reach your admin domain like this:
`https://admin.YOUR-DOMAIN-NAME`

---

## 4. Deploy some charts and services

There are three ways to point an entry at a chart:

| Source | What you set | Deployed like this |
| --- | --- | --- |
| The global helm registry, configured under `global.helm.repoURL` (here https://charts.iits.tech/) | Nothing extra, the entry name is the chart name | _kafka_ |
| Another helm registry | Its own `repoURL` | _akhq_, and the commented out _bitnami-kafka_ |
| This git repository | `repoURL` of the repository plus `path` | _basic-auth_, _kumoops-admin-dashboard_ |

Now it is time to deploy a service yourself. In this example we install an elastic stack
(kibana, elasticsearch, filebeat):

1. Open `infrastructure-charts/values.yaml`
2. Add a new service under the existing `charts:` key:

   ```yaml
   charts:
     # ... the entries which are already there
     elastic-operator:
       namespace: monitoring
       targetRevision: 9.0.5-bitnamilegacy
       parameters:
         ingress.kibana.host: "admin.{{.Values.projectValues.stageDomain}}"
   ```

3. Commit and push. ArgoCD detects the change and applies it after around 2 to 3 minutes

After the deployment, update the admin dashboard in
`infrastructure-charts/value-files/admin-dashboard/values.yaml` so the new tile shows up.
The chart ships one tile per service and this repository switches off everything it does
not deploy, so remove the `kibana` entry from the disabled block, or set it to `true`:

```yaml
defaultDashboard:
  tiles:
    kibana:
      enabled: true
```

Elasticsearch itself gets no tile, it has no ingress of its own and is reached through
Kibana.

> [!WARNING]
> `enabled` has to be a real boolean. The string `"false"` is truthy in helm templates,
> so a tile written as `enabled: "false"` shows up anyway.

> [!TIP]
> If you do not want to search for icons, the full tile list is in the chart itself:
> `local-charts/kumoops-admin-dashboard/values.yaml`

---

## 5. Change the values of a chart

You have three ways of changing the values of a chart:

| Way | When to use it |
| --- | --- |
| Change the values inside the remote or local helm chart itself | The chart is yours |
| Set `parameters:` in `infrastructure-charts/values.yaml` | You need to template values, or you only have a few of them |
| Point `valueFile:` at a file under `value-files/` | You have a lot of static values which are not stage dependent |

Parameters look like this:

```yaml
charts:
  kafka:
    namespace: kafka
    targetRevision: 22.2.0-bitnamilegacy
    parameters:
      "kafka.replicaCount": "1"
```

A values file looks like this:

```yaml
charts:
  kumoops-admin-dashboard:
    namespace: admin
    repoURL: "https://github.com/iits-consulting/otc-infrastructure-charts-template.git"
    targetRevision: "main"
    path: "local-charts/kumoops-admin-dashboard"
    # values files needs to be inside this chart
    valueFile: "value-files/admin-dashboard/values.yaml"
```

Now let's change a value:

1. Change the `"kafka.replicaCount"` parameter of the _kafka_ chart in
   `infrastructure-charts/values.yaml` from 1 to 2
2. Commit and push your changes
3. Check the _kafka_ service in the ArgoCD UI and verify that it scaled up

---

## 6. Hand over variables from OpenTofu to ArgoCD

Since this setup is built on top of the otc-terraform-template, you can hand over
information from OpenTofu to ArgoCD like this:

```terraform
resource "helm_release" "argocd" {
  ...
  values = [
    yamlencode({
      projects = {
        infrastructure-charts = {
          projectValues = {
            # Set this to enable the stage file values-$STAGE.yaml
            stage       = var.stage
            stageDomain = var.domain_name
          }
          ...
        }
      }
    })
  ]
}
```

All `projectValues` variables are given over to ArgoCD and can be reused here, in this
example _stage_ and _stageDomain_.

---

## 7. Integrate business apps

1. Copy the whole content of this project into another git repository
2. Rename the folder _infrastructure-charts_ to something you like, for example
   _app-charts_
3. Change all the other occurrences of _infrastructure-charts_ to _app-charts_
4. Register _app-charts_ as an app-of-apps project inside OpenTofu:

   ```terraform
   resource "helm_release" "argocd" {
     ...
     values = [
       yamlencode({
         projects = {
           infrastructure-charts = {
             ...
           }
           app-charts = {
             projectValues = {
               # Set this to enable the stage file values-$STAGE.yaml
               stage     = var.stage
               appDomain = var.domain_name
             }

             git = {
               password = var.git_token
               repoUrl  = "https://my-git-repo-for-apps.git"
             }
           }
         }
       })
     ]
   }
   ```

5. ArgoCD now does the same with the _app-charts_ as with the _infrastructure-charts_

> [!NOTE]
> For each team we recommend an own git repository and AppProject. Only then you can fully
> make use of RBAC.

---

## Appendix A: try out the setup

Now we go a little bit freestyle. Pick one of the topics below or choose one which you are
interested in. Talk with your teammates and your tutor about it and try to find the best
way to implement it.

1. **Set up an RDS database**
   - How would you create an RDS? Is there maybe a repository or website which helps you
     with that?
   - How would you initialize the database with users, tables and so on?
   - How can you avoid working with IPs? Think about having to set a private IP inside the
     microservice every time.

2. **Deploy a third party helm chart like keycloak**
   - Do you need forward-auth?
   - Do you need persistence? If yes, where do you store the data, file storage or a
     database?
   - How do you configure Keycloak, its realms and clients? No, we will not do it manually!

3. **Deploy a prometheus-stack**
   - Do you need forward-auth?
   - Do you need persistence? If yes, where do you store the data, file storage or a
     database?
   - How do you configure the scrape targets, dashboards and alert rules? No, we will not
     do it manually!

4. **Deploy a third party helm chart like elastic-stack**
   - Do you need forward-auth?
   - Do you need persistence? If yes, where do you store the data, file storage or a
     database?
   - How do you configure the index lifecycle and the dashboards? No, we will not do it
     manually!

5. **Security**
   - Take a look at kyverno and think about how to add more security to your cluster
   - Which steps are needed to make third party helm images secure? Hint: take a look at
     the iits charts.

---

## The End

<img src="documentation/kumo-the-end.gif" alt="Kumo closes the laptop and waves goodbye under a THE END sign" width="480" />

[Download the clip as mp4](documentation/kumo-the-end.mp4)
