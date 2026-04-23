
# Tiannara MindCache Prosthetic Project

## Local setup on Windows

Step 0:
- Install Python 3.10+
- Install Rust
- Install Node.js if you want to run `tiannara_gui`
- Install VS Code
- Open the folder directly in VS Code
- Run `mindcache/orchestrator.py`

This project does not require WSL for normal local development.

## About the "no WSL distro found" message

That error usually appears when VS Code tries to open the optional `.devcontainer` environment on Windows before a WSL distro is installed.

If you want the quickest path, skip the dev container and work locally with Python, Rust, and Node.js installed on Windows.

If you specifically want to use the dev container, install:
- Docker Desktop
- WSL 2
- A Linux distro such as Ubuntu from the Microsoft Store

## Next step

- Develop memory and contextual processing modules.
