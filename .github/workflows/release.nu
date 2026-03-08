#!/usr/bin/env nu

# Description:
# A generalized script for cross-compiling and packaging Rust projects.
# Optimized for general-purpose

def hr-line [--blank_line(-b)] {
    print $"(ansi g)---------------------------------------------------------------------------->(ansi reset)"
    if $blank_line { char nl }
}

def main [command?: string] {
    let cmd = ($command | default "build")
    match $cmd {
        "build" => { run_build }
        "publish" => { run_publish }
        _ => { print $"Unknown command: ($cmd)"; exit 1 }
    }
}

def run_build [] {
    let config_file = "release.toml"
    if not ($config_file | path exists) {
        print $"Error: ($config_file) not found."
        exit 1
    }
    let config = (open $config_file)

    let bin     = (try { $config.metadata.bin } catch { "" })
    let version = (try { $config.metadata.version } catch { "" })

    if ($bin | is-empty) or ($version | is-empty) {
        print "Error: 'metadata.bin' or 'metadata.version' is missing or empty in release.toml"
        exit 1
    }

    let os      = $env.OS
    let target  = $env.TARGET

    # Target Early Exit
    let is_target_enabled = (try { $config.targets | get $target } catch { false })
    if $is_target_enabled != true {
        print $"Target ($target) is not enabled in release.toml. Skipping build."
        exit 0
    }

    let src     = $env.GITHUB_WORKSPACE
    let dist    = $"($env.GITHUB_WORKSPACE)/output"

    print "Debugging info:"
    print { project: $bin, version: $version, os: $os, target: $target, src: $src, dist: $dist }
    hr-line -b

    let USE_UBUNTU = ($os | str starts-with "ubuntu")

    print $"(char nl)Packaging ($bin) v($version) for ($target)..."
    hr-line -b

    if not ('Cargo.lock' | path exists) {
        cargo generate-lockfile
    }

    let cargo_build_project = {
        print $"Building ($bin) for ($target)..."
        cargo build --release --all --target $target
    }

    # --- Build Environment Setup ---
    if $os in ['macos-latest'] or $USE_UBUNTU {
        if $USE_UBUNTU {
            sudo apt update
            # Generic dependencies for compilation
        }

        match $target {
            'aarch64-unknown-linux-gnu' => {
                sudo apt-get install gcc-aarch64-linux-gnu -y
                $env.CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = 'aarch64-linux-gnu-gcc'
                do $cargo_build_project
            }

            'riscv64gc-unknown-linux-gnu' => {
                sudo apt-get install gcc-riscv64-linux-gnu -y
                $env.CARGO_TARGET_RISCV64GC_UNKNOWN_LINUX_GNU_LINKER = 'riscv64-linux-gnu-gcc'
                do $cargo_build_project
            }

            's390x-unknown-linux-gnu' => {
                sudo apt-get install gcc-s390x-linux-gnu -y
                $env.CARGO_TARGET_S390X_UNKNOWN_LINUX_GNU_LINKER = 's390x-linux-gnu-gcc'
                do $cargo_build_project
            }

            'powerpc64le-unknown-linux-gnu' => {
                sudo apt-get install gcc-powerpc64le-linux-gnu -y
                $env.CARGO_TARGET_POWERPC64LE_UNKNOWN_LINUX_GNU_LINKER = 'powerpc64le-linux-gnu-gcc'
                do $cargo_build_project
            }

            'aarch64-unknown-linux-musl' => {
                aria2c https://github.com/nushell/integrations/releases/download/build-tools/aarch64-linux-musl-cross.tgz
                tar -xf aarch64-linux-musl-cross.tgz -C $env.HOME
                $env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/aarch64-linux-musl-cross/bin")
                $env.CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER = 'aarch64-linux-musl-gcc'
                do $cargo_build_project
            }

            'loongarch64-unknown-linux-gnu' => {
                aria2c https://github.com/loongson/build-tools/releases/download/2025.08.08/x86_64-cross-tools-loongarch64-binutils_2.45-gcc_15.1.0-glibc_2.42.tar.xz
                tar xf x86_64-cross-tools-loongarch64-*.tar.xz
                $env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.PWD)/cross-tools/bin")
                $env.CARGO_TARGET_LOONGARCH64_UNKNOWN_LINUX_GNU_LINKER = 'loongarch64-unknown-linux-gnu-gcc'
                $env.RUSTFLAGS = "-C target-feature=+crt-static"
                do $cargo_build_project
            }

            'loongarch64-unknown-linux-musl' => {
                aria2c https://github.com/LoongsonLab/oscomp-toolchains-for-oskernel/releases/download/loongarch64-linux-musl-cross-novec/loongarch64-linux-musl-cross-novec.tgz
                tar -xf loongarch64-linux-musl-cross-novec.tgz
                $env.PATH = ($env.PATH | split row (char esep) | prepend $'($env.PWD)/loongarch64-linux-musl-cross-novec/bin')
                $env.CARGO_TARGET_LOONGARCH64_UNKNOWN_LINUX_MUSL_LINKER = "loongarch64-linux-musl-gcc"
                # Workaround for Rust 1.87 TLS issues: abort strategy to bypass TLS-dependent panic handling
                $env.RUSTFLAGS = "-C panic=abort -C target-feature=+crt-static"
                do $cargo_build_project
            }

            'armv7-unknown-linux-gnueabihf' => {
                sudo apt-get install pkg-config gcc-arm-linux-gnueabihf -y
                $env.CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER = 'arm-linux-gnueabihf-gcc'
                do $cargo_build_project
            }

            'armv7-unknown-linux-musleabihf' => {
                aria2c https://github.com/nushell/integrations/releases/download/build-tools/armv7r-linux-musleabihf-cross.tgz
                tar -xf armv7r-linux-musleabihf-cross.tgz -C $env.HOME
                $env.PATH = ($env.PATH | split row (char esep) | prepend $'($env.HOME)/armv7r-linux-musleabihf-cross/bin')
                $env.CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER = 'armv7r-linux-musleabihf-gcc'
                do $cargo_build_project
            }

            'i686-unknown-linux-gnu' => {
                sudo apt-get install gcc-multilib -y
                do $cargo_build_project
            }

            _ => {
                if $USE_UBUNTU { sudo apt install musl-tools -y }
                do $cargo_build_project
            }
        }
    }

    # --- Windows Build ---
    if $os =~ 'windows' {
        match $target {
            'x86_64-pc-windows-gnu' => {
                print "Downloading MinGW toolchain..."
                curl.exe -L -o mingw.7z "https://github.com/niXman/mingw-builds-binaries/releases/download/15.2.0-rt_v13-rev1/x86_64-15.2.0-release-posix-seh-ucrt-rt_v13-rev1.7z"
                print "Extracting MinGW toolchain..."
                7z x mingw.7z -y -omingw | ignore
                $env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.PWD)/mingw/mingw64/bin")
                $env.CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER = 'gcc'
                do $cargo_build_project
            }
            _ => {
                do $cargo_build_project
            }
        }
    }

    # --- Packaging Artifacts ---
    let suffix = if $os =~ 'windows' { '.exe' } else { '' }
    let executable_pattern = $"target/($target)/release/($bin)*($suffix)"

    cd $src
    mkdir $dist

    # Clean up build artifacts
    rm -rf ...(glob $"target/($target)/release/*.d")

    print $"(char nl)Copying release files..."
    hr-line

    let assets = [LICENSE ...(glob $executable_pattern)]
    $assets | each {|it| if ($it | path exists) { cp -rv $it $dist } } | flatten

    # --- Create Archive ---
    cd $dist
    print $"(char nl)Creating release archive..."
    hr-line

    let release_name = $"($bin)-($version)-($target)"

    if $os in ['macos-latest'] or $USE_UBUNTU {
        let archive = $"($dist)/($release_name).tar.gz"
        mkdir $release_name
        let files_to_archive = (ls | where name != $release_name and name !~ '\.(deb|rpm|apk)$' | get name)
        $files_to_archive | each {|it| mv $it $release_name }
        tar -czf $archive $release_name
        echo $"archive=($archive)(char nl)" o>> $env.GITHUB_OUTPUT
    } else if $os =~ 'windows' {
        let archive = $"($dist)/($release_name).zip"
        # Exclude .msi and .zip files to prevent including the installer or the archive itself
        let files = (glob * | where ($it | path parse | get extension | $in not-in ['msi', 'zip']))
        7z a $archive ...$files
        if ($archive | path exists) {
            let normalized_archive = ($archive | str replace --all '\' '/')
            echo $"archive=($normalized_archive)(char nl)" o>> $env.GITHUB_OUTPUT
        }

        # Optional: Windows MSI packaging
        # Check if wix/ folder exists in source directory
        let wix_folder_exists = ($src | path join 'wix' | path exists)
        if $wix_folder_exists {
            let can_build_msi = [dotnet wix] | all { (which $in | length) > 0 }
            if $can_build_msi and (wix --version | split row . | first | into int) >= 6 {
                print $"(char nl)Building MSI package..."
                cd $src; cd wix; mkdir $bin
                # Copy only base assets to the target folder, excluding any existing archives or installers
                glob $"($dist)/*" | where ($it | path parse | get extension | $in not-in ['msi', 'zip']) | each {|it| cp -r $it $"($bin)/" }

                let arch = if $nu.os-info.arch =~ 'x86_64' { 'x64' } else { 'arm64' }
                ./($bin)/($bin).exe -c $"PROJECT_NAME=($bin) PROJECT_VERSION=($version) dotnet build -c Release -p:Platform=($arch)"

                let wix_msi   = (glob **/*.msi | where $it =~ bin | get 0)
                let final_msi = $"($dist)/($release_name).msi"
                mv $wix_msi $final_msi
                echo $"msi=($final_msi | str replace --all '\' '/')(char nl)" o>> $env.GITHUB_OUTPUT
            }
        }
    }

    # --- nFPM Linux Packaging (deb, rpm, apk) ---
    let nfpm_arch = match $target {
        'x86_64-unknown-linux-gnu' | 'x86_64-unknown-linux-musl' => 'amd64'
        'i686-unknown-linux-gnu' => '386'
        'aarch64-unknown-linux-gnu' | 'aarch64-unknown-linux-musl' => 'arm64'
        'armv7-unknown-linux-gnueabihf' | 'armv7-unknown-linux-musleabihf' => 'arm7'
        's390x-unknown-linux-gnu' => 's390x'
        'powerpc64le-unknown-linux-gnu' => 'ppc64le'
        _ => ''
    }

    let use_nfpm = (try { $config.nfpm.enable } catch { false })

    if $use_nfpm and ($target in ['x86_64-unknown-linux-gnu', 'i686-unknown-linux-gnu']) {
        if (which nfpm | is-not-empty) {
            print $"(char nl)[nFPM] Building Linux packages..."
            hr-line
            
            $env.ARCH = $nfpm_arch
            $env.VERSION = $version
            
            # Ensure binary is at project root for nfpm.yaml as specified in 'contents'
            let binary_path = $"($src)/target/($target)/release/($bin)"
            if ($binary_path | path exists) {
                cp -v $binary_path $"($src)/($bin)"
                
                cd $src
                ["deb", "rpm", "apk"] | each {|packager|
                    let pkg_file = $"($dist)/($bin)-($version)-($target).($packager)"
                    print $"[nFPM] Packaging ($packager) to ($pkg_file)..."
                    nfpm pkg --packager $packager --target $pkg_file
                }
            }
        }
    }
}

def run_publish [] {
    let config_file = "release.toml"
    if not ($config_file | path exists) {
        print $"Error: ($config_file) not found."
        exit 1
    }
    let config = (open $config_file)

    let is_tag = ($env.REF? | default "" | str starts-with "refs/tags/")
    
    let dist = $"($env.GITHUB_WORKSPACE)/output"
    if not ($dist | path exists) {
        print $"Error: Output directory ($dist) not found. Build is required or artifacts download failed."
        exit 1
    }
    # 0. Generate Installers
    let installer_enabled = (try { $config.installer.enable } catch { false })
    if $installer_enabled {
        print $"(char nl)[Installer] Generating installer scripts..."
        hr-line
        let bin = (try { $config.metadata.bin } catch { "" })
        let version = (try { $config.metadata.version } catch { "" })
        let repo = (try { $config.installer.repository } catch { "" })
        let features = (try { $config.installer.features } catch { [] })
        let p_linux = (try { $config.installer.path } catch { "~/.local/bin" })
        let p_win = (try { $config.installer.path-win } catch { "C:/bin/cli-dummy" })

        if "sh" in $features {
            let tpl_sh = ".github/workflows/installer.template.sh"
            if ($tpl_sh | path exists) {
                let content = (open --raw $tpl_sh | str replace --all "{{bin}}" $bin | str replace --all "{{version}}" $version | str replace --all "{{repository}}" $repo | str replace --all "{{path}}" $p_linux)
                $content | save --force $"($dist)/install.sh"
                print $"Generated ($dist)/install.sh"
            } else {
                print $"Warning: ($tpl_sh) not found."
            }
        }

        if "ps1" in $features {
            let tpl_ps1 = ".github/workflows/installer.template.ps1"
            if ($tpl_ps1 | path exists) {
                let content = (open --raw $tpl_ps1 | str replace --all "{{bin}}" $bin | str replace --all "{{version}}" $version | str replace --all "{{repository}}" $repo | str replace --all "{{path-win}}" $p_win)
                $content | save --force $"($dist)/install.ps1"
                print $"Generated ($dist)/install.ps1"
            } else {
                print $"Warning: ($tpl_ps1) not found."
            }
        }
    }

    # 1. GitHub Release
    if $is_tag {
        print $"(char nl)[GitHub] Creating Release Draft & Uploading Assets..."
        hr-line
        let tag_name = ($env.REF | str replace 'refs/tags/' '')
        
        let bin = (try { $config.metadata.bin } catch { "" })
        let version = (try { $config.metadata.version } catch { "" })
        let features = (try { $config.installer.features } catch { [] })

        let target_names = {
            "aarch64-apple-darwin": "macOS ARM64",
            "x86_64-apple-darwin": "macOS x64",
            "x86_64-pc-windows-msvc": "Windows x64",
            "i686-pc-windows-msvc": "Windows x86",
            "x86_64-pc-windows-gnu": "Windows x64 (GNU)",
            "aarch64-pc-windows-msvc": "Windows ARM64",
            "x86_64-unknown-linux-gnu": "Linux x64",
            "i686-unknown-linux-gnu": "Linux x86",
            "x86_64-unknown-linux-musl": "Linux x64 (musl)",
            "aarch64-unknown-linux-gnu": "Linux ARM64",
            "aarch64-unknown-linux-musl": "Linux ARM64 (musl)",
            "armv7-unknown-linux-gnueabihf": "Linux ARMv7",
            "armv7-unknown-linux-musleabihf": "Linux ARMv7 (musl)",
            "riscv64gc-unknown-linux-gnu": "Linux RISC-V 64",
            "loongarch64-unknown-linux-gnu": "Linux LoongArch64",
            "loongarch64-unknown-linux-musl": "Linux LoongArch64 (musl)",
            "s390x-unknown-linux-gnu": "Linux s390x",
            "powerpc64le-unknown-linux-gnu": "Linux ppc64le"
        }

        let assets_for_table = (ls $dist | where type == file | get name | where {|f|
            let base = ($f | path basename)
            not ($base in ['install.sh', 'install.ps1']) and not ($base | str ends-with ".sha256")
        })

        mut rows = ["| Operating System & Architecture | Format | Checksum (SHA256) |", "|---|---|---|"]
        
        mut has_i686 = false
        mut has_s390x = false

        for file in $assets_for_table {
            let base = ($file | path basename)
            let sha = (try { ^sha256sum $file | split row ' ' | first } catch { "UNKNOWN" })
            
            let ext = if ($base | str ends-with ".tar.gz") {
                ".tar.gz"
            } else if ($base | str ends-with ".zip") {
                ".zip"
            } else if ($base | str ends-with ".msi") {
                ".msi"
            } else if ($base | str ends-with ".deb") {
                ".deb"
            } else if ($base | str ends-with ".rpm") {
                ".rpm"
            } else if ($base | str ends-with ".apk") {
                ".apk"
            } else {
                ""
            }

            if $ext != "" {
                let without_prefix = ($base | str replace $"($bin)-($version)-" "")
                let target_str = ($without_prefix | str replace $ext "")
                
                if ($target_str | str starts-with "i686") { $has_i686 = true }
                if ($target_str | str starts-with "s390x") { $has_s390x = true }

                let os_arch = (try { $target_names | get $target_str } catch { $target_str })
                $rows = ($rows | append $"| ($os_arch) | `($ext)` | `($sha)` |")
            }
        }
        
        mut notes_lines = []
        $notes_lines = ($notes_lines | append "### 📦 Target List")
        $notes_lines = ($notes_lines | append "")
        $notes_lines = ($notes_lines | append $rows)
        $notes_lines = ($notes_lines | append "")

        if $installer_enabled {
            let github_repo = ($env.GITHUB_REPOSITORY? | default "OWNER/REPO")
            $notes_lines = ($notes_lines | append "### 🚀 Quick Installer Guide")
            $notes_lines = ($notes_lines | append "")
            
            if "ps1" in $features {
                $notes_lines = ($notes_lines | append "**Windows**:")
                $notes_lines = ($notes_lines | append "Instructions on using the command to execute `install.ps1`. This script automatically handles decompression and checks the CPU architecture (AMD64/ARM64).")
                $notes_lines = ($notes_lines | append "```powershell")
                $notes_lines = ($notes_lines | append $"irm https://github.com/($github_repo)/releases/latest/download/install.ps1 | iex")
                $notes_lines = ($notes_lines | append "```")
                $notes_lines = ($notes_lines | append "")
            }
            if "sh" in $features {
                $notes_lines = ($notes_lines | append "**Linux/macOS**:")
                $notes_lines = ($notes_lines | append "Instructions to execute the `install.sh`. This script automatically detects the OS (Linux/Darwin) and architecture to load the correct assets from the repository.")
                $notes_lines = ($notes_lines | append "```bash")
                $notes_lines = ($notes_lines | append $"curl -fsSL https://github.com/($github_repo)/releases/latest/download/install.sh | bash")
                $notes_lines = ($notes_lines | append "```")
                $notes_lines = ($notes_lines | append "")
            }
        }

        if $has_i686 or $has_s390x {
            $notes_lines = ($notes_lines | append "### ⚠️ Additional Information")
            $notes_lines = ($notes_lines | append "")
            if $has_i686 {
                $notes_lines = ($notes_lines | append "> **Note on `i686`**: This is an older legacy architecture. Support might be limited or deprecated in the future.")
                $notes_lines = ($notes_lines | append "")
            }
            if $has_s390x {
                $notes_lines = ($notes_lines | append "> **Note on `s390x`**: This is a Big Endian risk architecture. Proceed with caution as some libraries may assume Little Endian.")
                $notes_lines = ($notes_lines | append "")
            }
        }

        let notes_file = $"($dist)/RELEASE_NOTES.md"
        ($notes_lines | str join (char nl)) | save --force $notes_file

        # Check if release exists
        let release_exists = (try { gh release view $tag_name | complete } catch { {exit_code: 1} })
        if $release_exists.exit_code != 0 {
            gh release create $tag_name --draft --title $"Release ($tag_name)" --notes-file $notes_file
        } else {
            gh release edit $tag_name --notes-file $notes_file
        }
        
        # Upload all assets in dist
        let assets = (glob $"($dist)/*" | where {|f| ($f | path basename) != "RELEASE_NOTES.md"})
        if ($assets | is-not-empty) {
            gh release upload $tag_name ...$assets --clobber
        } else {
             print "No assets found to upload to GitHub."
        }
    } else {
        print "Not a tag push. Skipping GitHub Release."
    }

    # 2. Cloudsmith
    let cloudsmith_enabled = (try { $config.cloudsmith.enable } catch { false })
    let repo = (try { $config.cloudsmith.repo } catch { "codetease/tools" })
    let targets_mapping = (try { $config.cloudsmith.targets } catch { { deb: "ubuntu/noble", rpm: "el/9", apk: "alpine/any-version" } })

    let can_publish = $cloudsmith_enabled and ($env.CLOUDSMITH_API_KEY? | is-not-empty) and $is_tag

    if $can_publish {
        print $"(char nl)[Cloudsmith] Publishing Packages..."
        hr-line
        
        if (which cloudsmith | is-empty) {
            print "Cloudsmith CLI not found."
            exit 1
        }

        let pkgs = (try { ls ($dist | path join "*.{deb,rpm,apk}") | get name } catch { [] })

        if ($pkgs | is-not-empty) {
            for pkg in $pkgs {
                let ext = ($pkg | path parse | get extension)

                let fallback_path = $"($repo)/any/version"
                let target_path_suffix = (try { $targets_mapping | get $ext } catch { "" })
                let target_path = if ($target_path_suffix | is-empty) {
                    $fallback_path
                } else {
                    $"($repo)/($target_path_suffix)"
                }

                let pkg_type = if $ext == "apk" { "alpine" } else { $ext }
                
                print $"[Cloudsmith] Pushing ($ext) to ($target_path)..."
                cloudsmith push $pkg_type $target_path ($pkg | path expand) -k $env.CLOUDSMITH_API_KEY
            }
        } else {
            print "[Cloudsmith] Skipping publish: No linux packages found in output directory."
        }
    } else {
        print "[Cloudsmith] Skipping publish: Conditions not met (disabled, missing API key, or not a tag)."
    }
}