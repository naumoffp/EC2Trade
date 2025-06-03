# EC2Trade
A tool to launch and persist low-cost dev environments in seconds

## Requirements

This text-based (TUI) application requires the following:

- An Amazon Web Services (AWS) account
- Docker 20.x

## How To Run

```docker run -it ghcr.io/naumoffp/ec2trade:0.0.1```

## Notable Features:
- Develop an alternative to GitHub Codespaces that is 354% cheaper when comparing equivalent
32 vCPU/128 GiB Memory instances. Leverage EC2 Spot-Instance pricing to reduce compute spending.
- Use Terraform to architect persistent storage, access polices, and spot-fleet instance requests on AWS cloud services. Wrap all functionality in a portable terminal application, written in Golang

## Rust Prototype

`ec2trade-rs` is now a portable terminal application written in Rust. It reads the same sample price data used by the original Go version and displays it in a table. Start it with:

```bash
cd ec2trade-rs
cargo run
```

Quit the interface with `q` or `Esc`. Terraform configuration still relies on AWS credentials provided through the standard environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, etc.).
