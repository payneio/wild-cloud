# Converting Helm Charts to Wild-Cloud Kustomize definitions

_(This guide is a work in progress)_

```bash
helm fetch --untar --untardir charts nginx-stable/nginx-ingress
helm template --output-dir base --namespace ingress --values values.yaml ingress-controller charts/nginx-ingress
cat <<EOF > base/nginx-ingress/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ingress
EOF
cd base/nginx-ingress
kustomize create --autodetect
kubectl apply -k base/nginx-ingress
```
