#!/usr/bin/env nu

# Description:
# Validates release.toml and outputs the matrix for the release job.

let config_file = "release.toml"

if not ($config_file | path exists) {
    print $"Error: ($config_file) not found."
    exit 1
}

let config = (open $config_file)

# Validate metadata
if not ("metadata" in $config) {
    print "Error: 'metadata' section missing in release.toml"
    exit 1
}

let bin = (try { $config.metadata.bin } catch { "" })
let version = (try { $config.metadata.version } catch { "" })

if ($bin | is-empty) or ($version | is-empty) {
    print "Error: 'metadata.bin' or 'metadata.version' is missing or empty in release.toml"
    exit 1
}

print $"Validated metadata: bin=($bin), version=($version)"

# Validate Git Tag (if running in GitHub Actions and it's a tag push)
let github_ref = ($env.GITHUB_REF? | default "")
let github_event_name = ($env.GITHUB_EVENT_NAME? | default "")
let is_tag = ($github_ref | str starts-with "refs/tags/")

if $is_tag and $github_event_name != "workflow_dispatch" {
    let tag_name = ($github_ref | str replace 'refs/tags/' '')
    let tag_version = ($tag_name | str replace --regex '^v' '')
    if $tag_version != $version {
        print $"Error: release.toml version ($version) does not match Git tag ($tag_name)"
        exit 1
    }
    print $"Validated Git tag: ($tag_name) matches config version ($version)"
}

# Validate installer configuration and templates
let use_installer = (try { $config.installer.enable } catch { false })
if $use_installer {
    let repo = (try { $config.installer.repository } catch { "" })
    if ($repo | is-empty) {
        print "Error: 'installer.repository' missing or empty in release.toml"
        exit 1
    }

    let features = (try { $config.installer.features } catch { [] })
    
    if "sh" in $features {
        let p_linux = (try { $config.installer.path } catch { "" })
        if ($p_linux | is-empty) {
            print "Error: 'installer.path' missing or empty in release.toml"
            exit 1
        }
        if not (".github/workflows/installer.template.sh" | path exists) {
            print "Error: .github/workflows/installer.template.sh missing"
            exit 1
        }
    }
    
    if "ps1" in $features {
        let p_win = (try { $config.installer.path-win } catch { "" })
        if ($p_win | is-empty) {
            print "Error: 'installer.path-win' missing or empty in release.toml"
            exit 1
        }
        if not (".github/workflows/installer.template.ps1" | path exists) {
            print "Error: .github/workflows/installer.template.ps1 missing"
            exit 1
        }
    }
    print "Validated installer configuration."
}

# Load Targets Matrix mapping
let all_targets = [
    { target: "aarch64-apple-darwin", os: "macos-latest", display_name: "macOS ARM64" },
    { target: "x86_64-apple-darwin", os: "macos-latest", display_name: "macOS x64" },
    { target: "x86_64-pc-windows-msvc", os: "windows-latest", display_name: "Windows x64" },
    { target: "i686-pc-windows-msvc", os: "windows-latest", display_name: "Windows x86" },
    { target: "x86_64-pc-windows-gnu", os: "windows-latest", display_name: "Windows x64 (GNU)" },
    { target: "aarch64-pc-windows-msvc", os: "windows-11-arm", display_name: "Windows ARM64" },
    { target: "x86_64-unknown-linux-gnu", os: "ubuntu-24.04", display_name: "Linux x64" },
    { target: "i686-unknown-linux-gnu", os: "ubuntu-24.04", display_name: "Linux x86" },
    { target: "x86_64-unknown-linux-musl", os: "ubuntu-24.04", display_name: "Linux x64 (musl)" },
    { target: "aarch64-unknown-linux-gnu", os: "ubuntu-24.04", display_name: "Linux ARM64" },
    { target: "aarch64-unknown-linux-musl", os: "ubuntu-24.04", display_name: "Linux ARM64 (musl)" },
    { target: "armv7-unknown-linux-gnueabihf", os: "ubuntu-24.04", display_name: "Linux ARMv7" },
    { target: "armv7-unknown-linux-musleabihf", os: "ubuntu-24.04", display_name: "Linux ARMv7 (musl)" },
    { target: "riscv64gc-unknown-linux-gnu", os: "ubuntu-24.04", display_name: "Linux RISC-V 64" },
    { target: "loongarch64-unknown-linux-gnu", os: "ubuntu-24.04", display_name: "Linux LoongArch64" },
    { target: "loongarch64-unknown-linux-musl", os: "ubuntu-24.04", display_name: "Linux LoongArch64 (musl)" },
    { target: "s390x-unknown-linux-gnu", os: "ubuntu-24.04", display_name: "Linux s390x" },
    { target: "powerpc64le-unknown-linux-gnu", os: "ubuntu-24.04", display_name: "Linux ppc64le" },
]

# Read enabled targets
if not ("targets" in $config) {
    print "Error: 'targets' section missing in release.toml"
    exit 1
}

let target_config = $config.targets

let active_targets = ($all_targets | where {|it| 
    # Check if target is explicitly enabled in release.toml
    let is_enabled = (try { $target_config | get $it.target } catch { false })
    $is_enabled == true
})

if ($active_targets | length) == 0 {
    print "Error: No targets enabled in release.toml"
    exit 1
}

let has_i686 = ($active_targets | any {|it| $it.target | str starts-with "i686" })
if $has_i686 {
    print $"(char nl)Warning: i686 is an older architecture. Support might be limited or deprecated in the future."
}

let has_s390x = ($active_targets | any {|it| $it.target | str starts-with "s390x" })
if $has_s390x {
    print $"(char nl)Warning: s390x is a Big Endian risk architecture. Proceed with caution as some libraries may assume Little Endian."
}

print $"(char nl)Enabled targets:"
$active_targets | each {|it| print $"  - ($it.target) on ($it.os)" }

# Output matrix for GitHub Actions
if ("GITHUB_OUTPUT" in $env) {
    let matrix_json = ($active_targets | to json -r)
    echo $"matrix=($matrix_json)(char nl)" o>> $env.GITHUB_OUTPUT
    print $"(char nl)Exported matrix to GITHUB_OUTPUT"
} else {
    print $"(char nl)Generated matrix JSON:"
    print ($active_targets | to json -r)
}
