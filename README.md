# Blueprint: OTC GitOps

This repository serves as a blueprint to start fast and easy with OTC GitOps

## Requirements

First setup the infrastructure according to the README within [this Github Template](https://github.com/iits-consulting/otc-terraform-template)  
then create a fork from this repository.

## Introduction

This helm chart _infrastructure-charts_ is automatically installed by terraform. It then creates
multiple other applications in the format of [app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern)

Within `infrastructure-charts/values.yaml` you can add new services and customize them. [Helm tpl](https://helm.sh/docs/howto/charts_tips_and_tricks/#using-the-tpl-function) is supported within the _values.yaml_ file

## Access ArgoCD UI

If you didn't source the `shell-helper.sh` in the https://github.com/iits-consulting/otc-terraform-template project please do so by running:

```shell
source shell-helper.sh
```

Now you are able to execute the `argo` command. Run the `argo` command. This will do the following:

1. Print out the Username and the Password on the first line
2. The browser should open automatically and open a tab to the ArgoCD UI. If it does not open a browser, you can do it yourself by opening this url: http://localhost:8080/argocd
3. You should see that ArgoCD automatically already installed multiple charts

If all services are up and running you should also be able to access your admin domain like this: https://admin.YOUR-DOMAIN-NAME

## How to deploy some charts/services

You have 3 options to deploy some services.

1. Chart from a global helm chart registry which is configured in line number 12 (in this example we use https://charts.iits.tech/). 
   Charts deployed like this: 
   _argocd-config_, _otc-storage-classes_, _traefik_, _cert-manager_, _basic-auth-gateway_, _kafka_, _admin-dashboard_

     
2. Chart from a non global helm chart registry. Charts deployed like this: _bitnami-kafka_ 
3. Chart which resides inside this git repository. Charts deployed like this: _akhq_


Let's deploy some additional chart. Now it is time for you deploy some charts/services by yourself.
In this example we will install an elastic stack (kibana/elasticsearch/filebeat) 
   * Open _infrastructure-charts/values.yaml_
   * Add a new service like this:
     ```yaml
     elastic-stack:
       namespace: monitoring
       targetRevision: "7.17.3-route-bugfix"
     ```
You need to commit and push this change now. Argo detects the changes and applies them after around 2-3 minutes.

After deployment please update the admin dashboard (infrastructure-charts/values-files/admin-dashboard/values.yaml) with the new links.
* /kibana
* /elasticsearch

## How to change values of the charts

You have 3 ways of changing the values of a chart

1. You change the values inside the remote/local helm chart itself
2. You set parameters inside the "infrastructure-charts/values.yaml" like shown between line number 55 till 57. 
   We would recommend this approach if you need to template values or if you have just a few values which needs to be set.
3. You specify the location of a _values.yaml_ file like shown on line number 82.
   We would recommend this approach only if you have a lot of static values which are not stage dependent.

Now let's change some values: 

1. Please change inside `/infrastructure-charts/values.yaml` the number of traefik replicas from 1 to 2
2. Commit and push your changes
3. Check the service in the ArgoCD UI and verify that it scaled up

## Handover variables from Terraform to ArgoCD

Since this setup is build on top of the otc-terraform-template you can hand over information from terraform to argo like this:

```terraform
resource "helm_release" "argocd" {
  ...
  values                = [
    yamlencode({
      projects = {
        infrastructure-charts = {
          projectValues = {
            # Set this to enable stage $STAGE-values.yaml
            stage        = var.stage
            traefikElbId = module.terraform_secrets_from_encrypted_s3_bucket.secrets["elb_id"]
            adminDomain  = "admin.${var.domain_name}"
            storageClassKmsKeyId = module.terraform_secrets_from_encrypted_s3_bucket.secrets["storage_class_kms_key_id"]
          }
      ...
    }
    )
  ]
}
```
All _projectValues_ variables are given over to argo, and we can reuse them here.

In this example the _stage_, _traefikElbId_, _adminDomain_ _storageClassKmsKeyId_ variables are handed over to argo.

## How to integrate Business Apps

1. First copy the whole content of this project to some other git repository
2. Change then the folder _infrastructure-charts_ to something you like for example _app-charts_
3. Change also all the other occurrences from _infrastructure-charts_ to _app-charts_
4. Register the _app-charts_ as a App of Apps project inside terraform like this:
```terraform
resource "helm_release" "argocd" {
  ...
  values                = [
    yamlencode({
      projects = {
        infrastructure-charts = {
        ....
        }
        app-charts = {
          projectValues = {
            # Set this to enable stage $STAGE-values.yaml
            stage        = var.stage
            appDomain  = "${var.domain_name}"
          }

          git = {
            password = var.git_token
            repoUrl  = "https://my-git-repo-for-apps.git"
          }
        }
    }
    )
  ]
}
```
5. Argo will now do the same with the _app-charts_ as with the _infrastructure-charts_

For each team we recommend to create a own git repo and AppProject. Then you will be able to fully make use of RBAC.

## (Optional) Try to deploy your own services

Try to deploy your own services like nextcloud, prometheus-stack, keycloak or zitadel

## The End

![](https://media.giphy.com/media/lD76yTC5zxZPG/giphy.gif)