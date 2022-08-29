# Blueprint: OTC GitOps

This repository serves as a blueprint to start fast and easy with OTC GitOps

## Requirements

1. Set up the infrastructure according to the README with this Github Template: https://github.com/iits-consulting/otc-terraform-template  
2. After you sourced the `shell-helper.sh` you can run `getElbPublicIp`. Please send me this IP.
3. I will create a DNS A Entry for you and give you the domain name

## Access ArgoCD UI

If you didn't source the `shell-helper.sh` in the https://github.com/iits-consulting/otc-terraform-template project please do so by running:

```shell
source shell-helper.sh
```

Now you are able to execute the `argo` command. Run the `argo` command. This will do the following:

1. Print out the Username and the Password on the first line
2. The browser should open automatically and open a tab to the ArgoCD UI. If it does not open a browser, you can do it yourself by opening this url: http://localhost:8080/argocd
3. You should see that ArgoCD automatically already installed:
    - infrastructure-charts
    - argocd-config
    - traefik 

## Deploy some services

1. In the `stages/dev/infrastructure-charts/values.yaml` set the value in `global.helmValues` for `dns.host` to the domain name which you received before.
2. You need to commit this change to the git repository such that ArgoCD detects the changes and applies them.
3. If you want to deploy some services you need to enter them in the `stages/dev/infrastructure-charts/values.yaml` in the same schema as the others. 
   The charts representing these services have to be either in `/apps` or in `/stages/dev/infrastructure-charts/apps`
4. Press refresh on all the services inside the ArgoCD UI. After some times you should get some certificates, and you can access your admin domain

## Adjust services

Now let's adjust some service. 

1. Please change inside `stages/dev/infrastructure-charts/values.yaml` the number of traefik replicas from 1 to 2
2. Commit your changes
3. Check the service in the ArgoCD UI and verify that it scaled up

## The End

Congrats! 

You have now a full working Terraform, ArgoCD GitOps Setup.

If you like try to deploy some new services and play a little bit with your new setup

