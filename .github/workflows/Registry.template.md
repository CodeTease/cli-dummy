# Package Registry Setup Guide

?IF_cloudsmith.enable?This project automatically publishes packages to [Cloudsmith](https://cloudsmith.io/~{{repo_path}}/). 
?IF_cloudsmith.enable?To easily install `{{bin}}` and receive future updates naturally through your system's package manager, run the relevant setup script for your environment.

?IF_cloudsmith.enable?## Linux Distributions
?IF_cloudsmith.enable?
?IF_cloudsmith.enable?### Debian & Ubuntu (APT)
?IF_cloudsmith.enable?To configure the APT repository and install the package:
?IF_cloudsmith.enable?```bash
?IF_cloudsmith.enable?curl -1sLf 'https://dl.cloudsmith.io/public/{{repo_path}}/setup.deb.sh' | sudo -E bash
?IF_cloudsmith.enable?sudo apt install {{bin}}
?IF_cloudsmith.enable?```
?IF_cloudsmith.enable?
?IF_cloudsmith.enable?### RHEL, CentOS & Fedora (RPM)
?IF_cloudsmith.enable?To configure the YUM/DNF repository and install the package:
?IF_cloudsmith.enable?```bash
?IF_cloudsmith.enable?curl -1sLf 'https://dl.cloudsmith.io/public/{{repo_path}}/setup.rpm.sh' | sudo -E bash
?IF_cloudsmith.enable?sudo dnf install {{bin}}
?IF_cloudsmith.enable?```
?IF_cloudsmith.enable?
?IF_cloudsmith.enable?### Alpine Linux (APK)
?IF_cloudsmith.enable?To configure the APK repository and install the package:
?IF_cloudsmith.enable?```bash
?IF_cloudsmith.enable?curl -1sLf 'https://dl.cloudsmith.io/public/{{repo_path}}/setup.alpine.sh' | sudo -E bash
?IF_cloudsmith.enable?apk add {{bin}}
?IF_cloudsmith.enable?```

?IF_archlinux.enable?### Arch Linux (PKGBUILD)
?IF_archlinux.enable?You can build and install the package using the provided `PKGBUILD` artifact from GitHub Releases.
?IF_archlinux.enable?```bash
?IF_archlinux.enable?curl -LO {{repository}}/releases/download/v{{version}}/{{bin}}-{{version}}-archlinux-pkgbuild.tar.gz
?IF_archlinux.enable?tar -xzf {{bin}}-{{version}}-archlinux-pkgbuild.tar.gz
?IF_archlinux.enable?makepkg -si
?IF_archlinux.enable?```

?IF_nuget.enable?## Windows (NuGet)
?IF_nuget.enable?To install the package via NuGet in PowerShell, register the Cloudsmith feed and install it:
?IF_nuget.enable?```powershell
?IF_nuget.enable?Register-PackageSource -Name '{{repo_path}}' -ProviderName NuGet -Location "https://nuget.cloudsmith.io/{{repo_path}}/v3/index.json"
?IF_nuget.enable?Install-Package {{bin}} -Source '{{repo_path}}'
?IF_nuget.enable?```
?IF_nuget.enable?
?IF_nuget.enable?Chocolatey:
?IF_nuget.enable?```powershell
?IF_nuget.enable?choco source add -n {{repo_path}} -s https://nuget.cloudsmith.io/{{repo_path}}/v3/index.json
?IF_nuget.enable?choco install {{bin}} -s {{repo_path}}
?IF_nuget.enable?```
?IF_nuget.enable?
?IF_nuget.enable?PowerShell:
?IF_nuget.enable?```powershell
?IF_nuget.enable?Register-PackageSource -Name '{{repo_path}}' -ProviderName NuGet -Location "https://nuget.cloudsmith.io/{{repo_path}}/v2/" -Trusted
?IF_nuget.enable?Register-PSRepository -Name '{{repo_path}}' -SourceLocation "https://nuget.cloudsmith.io/{{repo_path}}/v2/" -InstallationPolicy 'trusted'
?IF_nuget.enable?
?IF_nuget.enable?Install-Package {{bin}} -Source '{{repo_path}}'
?IF_nuget.enable?# Or
?IF_nuget.enable?Install-Module {{bin}} -Repository '{{repo_path}}'
?IF_nuget.enable?```

?IF_docker.enable?## Docker
?IF_docker.enable?
!!REWRITE_ghcr_and_cloudsmith!!Multi-architecture Docker images are available. You can pull the images from GitHub Container Registry (GHCR) or Cloudsmith.
!!REWRITE_ghcr_only!!Multi-architecture Docker images are available on GitHub Container Registry (GHCR).
!!REWRITE_cloudsmith_only!!Multi-architecture Docker images are available on Cloudsmith registry.
?IF_docker.enable?
?IF_docker.enable?### Alpine (Default)
?IF_docker.enable?Minimal size image based on Alpine Linux.
?IF_docker.enable?```bash
?IF_ghcr.enable?docker pull ghcr.io/{{github_org}}/{{bin}}:{{version}}
!!REWRITE_ghcr_and_cloudsmith!!# OR
?IF_docker.cloudsmith.enable?docker pull docker.cloudsmith.io/{{repo_path}}/{{bin}}:{{version}}
?IF_docker.enable?```
?IF_docker.enable?
?IF_docker.enable?### Debian Slim
?IF_docker.enable?Compatible image based on Debian Bookworm Slim.
?IF_docker.enable?```bash
?IF_ghcr.enable?docker pull ghcr.io/{{github_org}}/{{bin}}:{{version}}-debian-slim
!!REWRITE_ghcr_and_cloudsmith!!# OR
?IF_docker.cloudsmith.enable?docker pull docker.cloudsmith.io/{{repo_path}}/{{bin}}:{{version}}-debian-slim
?IF_docker.enable?```
?IF_docker.enable?
?IF_docker.enable?### Dockerfile
?IF_docker.enable?To refer image after pulling, use this in your `Dockerfile`:
?IF_docker.enable?```dockerfile
?IF_docker.enable?# Alpine
!!REWRITE_ghcr.enable!!FROM ghcr.io/{{github_org}}/{{bin}}:{{version}}
!!REWRITE_cloudsmith_only!!FROM docker.cloudsmith.io/{{repo_path}}/{{bin}}:{{version}}
?IF_docker.enable?
?IF_docker.enable?# Debian Slim
!!REWRITE_ghcr.enable!!FROM ghcr.io/{{github_org}}/{{bin}}:{{version}}-debian-slim
!!REWRITE_cloudsmith_only!!FROM docker.cloudsmith.io/{{repo_path}}/{{bin}}:{{version}}-debian-slim
?IF_docker.enable?```
