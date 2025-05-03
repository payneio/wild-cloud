# Sovereign Cloud

> Take control of your digital life with your own personal cloud infrastructure

## Why Build Your Own Cloud?

In a world where our digital lives are increasingly controlled by large corporations, having your own personal cloud puts you back in control:

- **Privacy**: Your data stays on your hardware, under your control
- **Ownership**: No subscription fees or sudden price increases
- **Freedom**: Run the apps you want, the way you want them
- **Learning**: Gain valuable skills in modern cloud technologies
- **Resilience**: Reduce reliance on third-party services that can disappear

## What is This Project?

This project provides a complete, production-ready Kubernetes infrastructure designed for personal use. It combines enterprise-grade technologies in an easy-to-deploy package, allowing you to:

- Host your own services like web apps, databases, and more
- Access services securely from anywhere with automatic HTTPS
- Keep some services private on your home network
- Deploy new applications with a single command
- Manage everything through a slick web dashboard

## What Can You Run?

The possibilities are endless! Here are just a few ideas:

- **Personal Websites & Blogs** (WordPress, Ghost, Hugo)
- **Photo Storage & Sharing** (PhotoPrism, Immich)
- **Document Management** (Paperless-ngx)
- **Media Servers** (Jellyfin, Plex)
- **Home Automation** (Home Assistant)
- **Password Managers** (Bitwarden, Vaultwarden)
- **Note Taking Apps** (Joplin, Trilium)
- **Productivity Tools** (Nextcloud, Gitea, Plausible Analytics)
- **Database Servers** (PostgreSQL, MariaDB, MongoDB)
- **And much more!**

## Key Features

- **One-Command Setup**: Get a complete Kubernetes infrastructure with a single script
- **Secure by Default**: Automatic HTTPS certificates for all services
- **Split-Horizon DNS**: Access services internally or externally with the same domain
- **Custom Domains**: Use your own domain name for all services
- **Service Templates**: Deploy new applications with a simple command
- **Dashboard**: Web UI for monitoring and managing your infrastructure
- **No Cloud Vendor Lock-in**: Run on your own hardware, from a Raspberry Pi to old laptops

## Getting Started

For detailed instructions, check out our documentation:

- [**Setup Guide**](./docs/SETUP.md) - Step-by-step instructions for setting up your infrastructure
- [**Applications Guide**](./docs/APPS.md) - How to deploy and manage applications on your cloud
- [**Charts Guide**](./charts/README.md) - Working with Helm charts and custom applications
- [**Maintenance Guide**](./docs/MAINTENANCE.md) - Troubleshooting, backups, updates, and security

After setup, visit your dashboard at `https://dashboard.internal.yourdomain.com` to start exploring your new personal cloud infrastructure!

## Project Structure

```
.
├── bin/                      # Helper scripts
├── apps/                     # Apps
├── docs/                     # Documentation
│   ├── SETUP.md              # Setup instructions
│   ├── APPS.md               # Application deployment guide
│   ├── MAINTENANCE.md        # Maintenance and troubleshooting
│   ├── OPS.md                # Operations guide
│   └── INGRESS.md            # Network configuration guide
├── infrastructure_setup/     # Infrastructure setup scripts
├── services/                 # Custom service templates and deployed services
└── load-env.sh               # Environment variable loader
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

TBD
