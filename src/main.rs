use anyhow::{Context, Result};
use clap::Parser;
use reqwest::Client;
use std::time::Duration;

#[derive(Parser, Debug)]
#[command(author, version, about = "A simple CLI to test TLS connections across architectures")]
struct Args {
    /// The URL to fetch and test
    url: String,

    /// Timeout in seconds for the request
    #[arg(short, long, default_value_t = 10)]
    timeout: u64,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    println!("Testing connection to: {}", args.url);

    // Build the client specifically with rustls to avoid native dependency issues during cross-builds
    let client = Client::builder()
        .use_rustls_tls()
        .timeout(Duration::from_secs(args.timeout))
        .build()
        .context("Failed to build reqwest client")?;

    match client.get(&args.url).send().await {
        Ok(response) => {
            println!("Success!");
            println!("Status: {}", response.status());
            println!("Version: {:?}", response.version());
        }
        Err(e) => {
            // Print the full error chain to help identify specific TLS handshake or cert issues
            eprintln!("Error encountered during fetch:");
            let mut chain = e.chain();
            while let Some(cause) = chain.next() {
                eprintln!("  - caused by: {}", cause);
            }
            
            if e.is_connect() {
                eprintln!("\nHint: This might be a connection or DNS issue.");
            } else if e.is_timeout() {
                eprintln!("\nHint: The request timed out.");
            } else {
                eprintln!("\nHint: Check if the target architecture has the correct root certificates.");
            }
            
            std::process::exit(1);
        }
    }

    Ok(())
}