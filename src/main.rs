// A script to print literally anything, for nothing

use std::env;
use std::thread;
use std::time::SystemTime;

fn main() {
    // 1. Hello World
    println!("Hello World! 🦀");
    println!("========================================");

    // 2. Binary & Version (Available when building with Cargo)
    println!("Binary Name: {}", option_env!("CARGO_PKG_NAME").unwrap_or("standalone_binary"));
    println!("Version:     {}", option_env!("CARGO_PKG_VERSION").unwrap_or("0.1.0"));

    // 3. OS & 4. Architecture
    println!("OS:          {}", env::consts::OS);
    println!("Arch:        {}", env::consts::ARCH);

    // 5. Shell (Cross-platform check)
    let shell = env::var("SHELL")
        .or_else(|_| env::var("ComSpec"))
        .unwrap_or_else(|_| "Unknown".to_string());
    println!("Shell:       {}", shell);

    // --- Print everything else possible with std ---

    // Hardware info
    if let Ok(cpus) = thread::available_parallelism() {
        println!("CPUs:        {}", cpus.get());
    }

    // Platform family
    println!("Family:      {}", env::consts::FAMILY);
    
    // File system paths
    if let Ok(exe) = env::current_exe() {
        println!("Exe Path:    {}", exe.display());
    }
    if let Ok(cwd) = env::current_dir() {
        println!("Current Dir: {}", cwd.display());
    }

    // Time info
    if let Ok(now) = SystemTime::now().duration_since(SystemTime::UNIX_EPOCH) {
        println!("Unix Epoch:  {}s", now.as_secs());
    }

    // Language/Compilation info
    println!("Pointer size: {} bits", std::mem::size_of::<usize>() * 8);

    // Environment variables (The "heavy" part - prints all env vars)
    println!("--- Environment Variables ---");
    for (key, value) in env::vars() {
        println!("{}: {}", key, value);
    }
    
    println!("========================================");
}