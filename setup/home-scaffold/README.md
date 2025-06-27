# Your Wild-Cloud

## One-time Setup

Congratulations! Everything you need for setting up and managing your wild-cloud is in this directory.

The first step is to set up your configuration and secrets.

```bash
mv config.example.yaml config.yaml
mv secrets.example.yaml secrets.yaml
```

> Configuration instructions TBD.

Generate your custom setup:

```bash
wild-setup
```

Now, continue setup with your custom [setup instructions](./setup/README.md).

## Using your wild-cloud

### Installing Wild-Cloud apps

```bash
wild-apps-list
wild-app-fetch <app>
wild-app-config <app>
wild-app-deploy <app>
# Optional: Check in app templates.
```
