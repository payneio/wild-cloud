# Your Wild-Cloud

## Getting started

### Install wild-cloud tools

```
# TBD
```

### Set up wild-cloud hardware

TBD

### Create your wild-cloud

```bash
wild init         # Creates a .wildcloud dir and copies templates.
wild update       # Updates templates
wild cluster init # Copies cluster templates

# Make your config and secrets changes.

wild cluster build
wild cluster apply
# Optional: Check in cluster files.
```

### Install Wild-Cloud apps

```bash
wild apps list
wild apps get <app>
wild apps build <app>
wild apps apply <app>
# Optional: Check in app templates.
```
