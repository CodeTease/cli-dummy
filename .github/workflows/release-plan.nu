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

# Load Targets Matrix mapping
let all_targets = [
    { target: "aarch64-apple-darwin", os: "macos-latest" },
    { target: "x86_64-apple-darwin", os: "macos-latest" },
    { target: "x86_64-pc-windows-msvc", os: "windows-latest" },
    { target: "x86_64-pc-windows-gnu", os: "windows-latest" },
    { target: "aarch64-pc-windows-msvc", os: "windows-11-arm" },
    { target: "x86_64-unknown-linux-gnu", os: "ubuntu-24.04" },
    { target: "x86_64-unknown-linux-musl", os: "ubuntu-24.04" },
    { target: "aarch64-unknown-linux-gnu", os: "ubuntu-24.04" },
    { target: "aarch64-unknown-linux-musl", os: "ubuntu-24.04" },
    { target: "armv7-unknown-linux-gnueabihf", os: "ubuntu-24.04" },
    { target: "armv7-unknown-linux-musleabihf", os: "ubuntu-24.04" },
    { target: "riscv64gc-unknown-linux-gnu", os: "ubuntu-24.04" },
    { target: "loongarch64-unknown-linux-gnu", os: "ubuntu-24.04" },
    { target: "loongarch64-unknown-linux-musl", os: "ubuntu-24.04" },
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
