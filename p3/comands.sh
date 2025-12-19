k3d cluster list

kubectl cluster-info

kubectl cluster-info dump # for more info about my classters


kubectl get pods -n argocd #Check Argo CD pods


kubectl get svc -n argocd #Check Argo CD services


kubectl get applications -n argocd # get Argo CD applications


kubectl delete application moouaamm-app -n argocd # remove the app from argocd