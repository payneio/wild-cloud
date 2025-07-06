# Wild Cloud App Workflow

The Wild Cloud app workflow consists of three steps:

1. **Fetch** - Download raw app templates to cache
2. **Config** - Apply your local configuration to templates  
3. **Deploy** - Deploy configured app to Kubernetes

## Commands

To list all available apps:

```bash
wild-apps-list
```

To fetch an app template to cache:

```bash
wild-app-fetch <app>
```

To apply your configuration to a cached app (automatically fetches if not cached):

```bash
wild-app-config <app>
```

To deploy a configured app to Kubernetes:

```bash
wild-app-deploy <app>
```

## Quick Setup

For a complete app setup and deployment:

```bash
wild-app-config <app>  # Fetches if needed, then configures
wild-app-deploy <app>  # Deploys to Kubernetes
```

## App Directory Structure

Your wild-cloud apps are stored in the `apps/` directory. You can change them however you like. You should keep them all in git and make commits anytime you change something. Some `wild` commands will overwrite files in your app directory (like when you are updating apps, or updating your configuration) so you'll want to review any changes made to your files after using them using `git`.