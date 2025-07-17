# Wild Cloud-maintained apps

This is the Wild Cloud apps repository. 

This repository contains a collection of apps that can be deployed using Wild Cloud scripts. Wild Cloud apps follow a specific structure and naming convention to ensure compatibility with the Wild Cloud ecosystem.

## App Structure

Each subdirectory in this directory represents a Wild Cloud app. Each app directory contains an "app manifest" (`manifest.yaml`), a "kustomization" (`kustomization.yaml`), and one or more "configurations" (yaml files containing definitions/configurations of Kubernetes objects/resources).

### App Manifest

The required `manifest.yaml` file contains metadata about the app.

This is the contents of an example `manifest.yaml` file for an app named "immich":

```yaml
name: immich
description: Immich is a self-hosted photo and video backup solution that allows you to store, manage, and share your media files securely.
version: 1.0.0
icon: https://immich.app/assets/images/logo.png
requires:
  - name: redis
  - name: postgres
defaultConfig:
  serverImage: ghcr.io/immich-app/immich-server:release
  mlImage: ghcr.io/immich-app/immich-machine-learning:release
  timezone: UTC
  serverPort: 2283
  mlPort: 3003
  storage: 250Gi
  cacheStorage: 10Gi
  redisHostname: redis.redis.svc.cluster.local
  dbHostname: postgres.postgres.svc.cluster.local
  dbUsername: immich
  domain: immich.{{ .cloud.domain }}
requiredSecrets:
  - apps.immich.dbPassword
  - apps.postgres.password
```

Explanation of the fields:

- `name`: The name of the app, used for identification.
- `description`: A brief description of the app.
- `version`: The version of the app. This should generally follow the versioning scheme of the app itself.
- `icon`: A URL to an icon representing the app.
- `requires`: A list of other apps that this app depends on. Each entry should be the name of another app.
- `defaultConfig`: A set of default configuration values for the app. When an app is added using `wild-app-add`, these values will be added to the Wild Cloud `config.yaml` file.
- `requiredSecrets`: A list of secrets that must be set in the Wild Cloud `secrets.yaml` file for the app to function properly. These secrets are typically sensitive information like database passwords or API keys. Keys with random values will be generated automatically when the app is added.

### Kustomization

Each app directory should also contain a `kustomization.yaml` file. This file defines how the app's Kubernetes resources are built and deployed. It can include references to other Kustomize files, patches, and configurations.

Here is an example `kustomization.yaml` file for the "immich" app:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: immich
labels:
  - includeSelectors: true
    pairs:
      app: immich
      managedBy: kustomize
      partOf: wild-cloud
resources:
  - deployment-server.yaml
  - deployment-machine-learning.yaml
  - deployment-microservices.yaml
  - ingress.yaml
  - namespace.yaml
  - pvc.yaml
  - service.yaml
  - db-init-job.yaml
  ```

Kustomization requirements:

- Every Wild Cloud kustomization should include the Wild Cloud labels in its `kustomization.yaml` file. This allows the Wild Cloud to identify and manage the app correctly. The labels should be defined under the `labels` key, as shown in the example above.
- The `app` label and `namespace` keys should the app's name/directory.

#### Standard Wild Cloud Labels

Wild Cloud uses a consistent labeling strategy across all apps:

```yaml
labels:
  - includeSelectors: true
    pairs:
      app: myapp              # The app name (matches directory)
      managedBy: kustomize    # Managed by Kustomize
      partOf: wild-cloud      # Part of Wild Cloud ecosystem
```

The `includeSelectors: true` setting automatically applies these labels to all resources AND their selectors, which means:

1. **Resource labels** - All resources get the standard Wild Cloud labels
2. **Selector labels** - All selectors automatically include these labels for robust selection

This allows individual resources to use simple, component-specific selectors:

```yaml
selector:
  matchLabels:
    component: web
```

Which Kustomize automatically expands to:

```yaml
selector:
  matchLabels:
    app: myapp
    component: web
    managedBy: kustomize
    partOf: wild-cloud
```

### Configuration Files

Wild Cloud apps use Kustomize as kustomize files are simple, transparent, and easier to manage in a Git repository. 

#### Templates

For operators, Wild Cloud apps use standard configuration files. This makes modifying the app's configuration straightforward, as operators can customize their app files as needed. They can choose to manage modifications and updates directly on the configuration files using `git` tools, or they can use Kustomize patches or overlays. As a convenience for operators, when adding an app (using `wild-app-add`), the app's configurations will be compiled with the operator's Wild Cloud configuration and secrets. This results in standard Kustomize files being placed in the Wild Cloud home directory, which can then be modified as needed. This means the configuration files in this repository are actually templates, but they will be compiled into standard Kustomize files when the app is added to an operator's Wild Cloud home directory.

To reference operator configuration in the configuration files, use gomplate variables, such as `{{ .cloud.domain }}` for the domain name. All configuration variables you use need to exist in the operator's `config.yaml`, so they should be either standard Wild Cloud operator variables, or be defined in the app's `manifest.yaml` under `defaultConfig`.

When `wild-app-add` is run, the app's Kustomize files will be compiled with the operator's Wild Cloud configuration and secrets resulting in standard Kustomize files being placed in the Wild Cloud home directory.

#### Secrets

Secrets are managed in the `secrets.yaml` file in the Wild Cloud home directory. The app's `manifest.yaml` should list any required secrets under `requiredSecrets`. When the app is added, default secret values will be generated and stored in the `secrets.yaml` file. Secrets are always stored and referenced in the `apps.<app-name>.<secret-name>` yaml path. When `wild-app-deploy` is run, a Secret resource will be created in the Kubernetes cluster with the name `<app-name>-secrets`, containing all secrets defined in the manifest's `requiredSecrets` key. These secrets can then be referenced in the app's Kustomize files using a `secretKeyRef`. For example, to mount a secret in an environment variable, you would use:

```yaml
env:
    - name: DB_PASSWORD
        valueFrom:
        secretKeyRef:
            name: immich-secrets
            key: dbPassword
```

`secrets.yaml` files should not be checked in to a git repository and are ignored by default in Wild Cloud home directories. Checked in kustomize files should only reference secrets, not compile them.

## App Lifecycle

Apps in Wild Cloud are managed by operators using a set of commands run from their Wild Cloud home directory.

- `wild-apps-list`: Lists all available apps.
- `wild-app-fetch <app-name>`: Fetches the latest app files from the Wild Cloud repository and stores them in your Wild Cloud cache.
- `wild-app-add <app-name>`: Adds the app manifest to your Wild Cloud home `apps` directory, updates missing values in `config.yaml` and `secrets.yaml` with the app's default configurations, and compiles the app's Kustomize files.
- `wild-app-deploy <app-name>`: Deploys the app to your Wild Cloud.

## Contributing

If you would like to contribute an app to the Wild Cloud, issue a pull request with the app's directory containing the `manifest.yaml` file and any necessary Kustomize files. Ensure that your app follows the structure outlined above.

## Tips for App Packagers

### Converting from Helm Charts

Wild Cloud apps use Kustomize as kustomize files are simpler, more transparent, and easier to manage in a Git repository than Helm charts. If you have a Helm chart that you want to convert to a Wild Cloud app, the following example steps can simplify the process for you:

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
```

After running these commands against your own Helm chart, you will have a Kustomize directory structure that can be used as a Wild Cloud app. All you need to do then, usually, is:

- add an app manifest (a `manifest.yaml` file).
- replace any hardcoded operator values with Wild Cloud operator variables, such as `{{ .cloud.domain }}` for the domain name.
- modify how secrets are referenced in the Kustomize files (see above)
- update labels and selectors to use the Wild Cloud standard:
  - Replace complex Helm labels (like `app.kubernetes.io/name`, `app.kubernetes.io/instance`) with simple component labels
  - Use `component: web`, `component: worker`, etc. in selectors and pod template labels
  - Let Kustomize handle the common labels (`app`, `managedBy`, `partOf`) automatically
- remove any Helm-specific labels from the Kustomize files, as Wild Cloud apps do not use Helm labels.
