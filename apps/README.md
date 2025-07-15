# Wild Cloud-maintained apps

This is the Wild Cloud apps repository. 

This repository contains a collection of apps that can be deployed using Wild Cloud scripts. Wild Cloud apps follow a specific structure and naming convention to ensure compatibility with the Wild Cloud ecosystem.

## App Structure

Each subdirectory in this directory represents a Wild Cloud app. Each app directory contains a `manifest.yaml` file and other necessary Kustomize files.

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

### Kustomize Files

Wild Cloud apps use Kustomize as kustomize files are simple, transparent, and easier to manage in a Git repository. 

#### Configuration (templates)

The only non-standard feature of Wild Cloud apps is the use of Wild Cloud configuration variables in the Kustomize files, such as `{{ .cloud.domain }}` for the domain name. This allows for dynamic configuration based on the operator's Wild Cloud configuration and secrets. All configuration variables need to exist in the operator's `config.yaml`, so they should be defined in the app's `manifest.yaml` under `defaultConfig`.

When `wild-app-add` is run, the app's Kustomize files will be compiled with the operator's Wild Cloud configuration and secrets resulting in standard Kustomize files being placed in the Wild Cloud home directory. This makes modifying the app's configuration straightforward, as operators can customize their app files as needed. When changes are pulled from upstream, the operator can run `wild-app-add` again to update their local configuration and Kustomize files and then view the changes with `git status` to see what has changed.

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


# Converting Helm Charts to Wild Cloud Kustomize definitions

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

After running these commands against your own Helm chart, you will have a Kustomize directory structure that can be used as a Wild Cloud app. All you need to do then, usually, is add a `manifest.yaml` file and replace any hardcoded values with Wild Cloud variables, such as `{{ .cloud.domain }}` for the domain name.

