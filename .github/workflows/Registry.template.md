# Package Registry Setup Guide

This project automatically publishes packages to [Cloudsmith](https://cloudsmith.io/~{{repo_path}}/). 
To easily install `{{bin}}` and receive future updates naturally through your system's package manager, run the relevant setup script for your environment.

## Linux Distributions

### Debian & Ubuntu (APT)
To configure the APT repository and install the package:
```bash
curl -1sLf 'https://dl.cloudsmith.io/public/{{repo_path}}/setup.deb.sh' | sudo -E bash
sudo apt install {{bin}}
```

### RHEL, CentOS & Fedora (RPM)
To configure the YUM/DNF repository and install the package:
```bash
curl -1sLf 'https://dl.cloudsmith.io/public/{{repo_path}}/setup.rpm.sh' | sudo -E bash
sudo dnf install {{bin}}
```

### Alpine Linux (APK)
To configure the APK repository and install the package:
```bash
curl -1sLf 'https://dl.cloudsmith.io/public/{{repo_path}}/setup.alpine.sh' | sudo -E bash
apk add {{bin}}
```

### Arch Linux (PKGBUILD)
You can build and install the package using the provided `PKGBUILD` artifact from GitHub Releases.
```bash
curl -LO {{repository}}/releases/download/v{{version}}/{{bin}}-{{version}}-archlinux-pkgbuild.tar.gz
tar -xzf {{bin}}-{{version}}-archlinux-pkgbuild.tar.gz
makepkg -si
```

## Windows (NuGet)
To install the package via NuGet in PowerShell, register the Cloudsmith feed and install it:
```powershell
Register-PackageSource -Name Cloudsmith -ProviderName NuGet -Location "https://nuget.cloudsmith.io/{{repo_path}}/v3/index.json"
Install-Package {{bin}} -Source Cloudsmith
```

Chocolatey:
```powershell
choco source add -n {{repo_path}} -s https://nuget.cloudsmith.io/{{repo_path}}/v3/index.json
choco install {{bin}} -s {{repo_path}}
```

PowerShell:
```powershell
Register-PackageSource -Name '{{repo_path}}' -Location "https://nuget.cloudsmith.io/{{repo_path}}/v2" -Trusted
Register-PSRepository -Name '{{repo_path}}' -SourceLocation "https://nuget.cloudsmith.io/{{repo_path}}/v2" -InstallationPolicy 'trusted'

Install-Package {{bin}} -Source '{{repo_path}}'
# Or
Install-Module {{bin}} -Repository '{{repo_path}}'
```
