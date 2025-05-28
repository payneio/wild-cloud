# Wild Cloud-maintained apps

## Usage

`generate-config <app-name>`
`kubectl apply -k apps/<app-name>`

## Best Practices

- `*.yaml`, not `*.yml`.
- Keep the service and deployment names the same as the app for easy DNS lookup.
- A starting `kustomization.yaml` for every app:

  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  namespace: postgres
  labels:
    - includeSelectors: true
      pairs:
        app: <app>
        managedBy: kustomize
        partOf: wild-cloud
  ```
