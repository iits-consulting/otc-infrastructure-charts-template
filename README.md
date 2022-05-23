# This is a blueprint to start easy and fast with OTC GitOps

## Requirements

You setup the infrastructure with this Github Template: https://github.com/iits-consulting/otc-terraform-template

Send me please the ELB Public IP. You can get this one by executing "getElbPublicIp" inside the terminal.
I will make a DNS A Entry for you and give you the domain name.

## Access ArgoCD UI

Since you source the shell-helper.sh you should be able to just execute "argo" inside the shell.

It will print out the Username and the Password on the first line and the browser should open automatically.
If not open your browser and open this url: http://localhost:8080/argocd

You should see that ArgoCD automaticly already installed infrastructure-charts,argocd-config, traefik and everyhting inside the root app folder

## Adjust services

Now lets adjust some service. Please change inside stages/dev/values.yaml the number of traefik replicas from 1 to 2 and refresh inside the ArgoCD UI.

See how the deployment scales up.

## The End

Congrats ! 

You have now a full working Terraform, ArgoCD GitOps Setup.

If you like try to deploy some new services and play a little bit with your new setup

