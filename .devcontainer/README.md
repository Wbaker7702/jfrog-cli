# VS Code Dev Container for JFrog CLI

This directory contains configuration for a VS Code Dev Container, providing a consistent development environment for JFrog CLI.

## Prerequisites

- Docker Desktop (or Docker Engine)
- VS Code with the "Dev Containers" extension installed

## Usage

1. Open VS Code in the repository root
2. Press `F1` or `Ctrl+Shift+P` (Windows/Linux) / `Cmd+Shift+P` (Mac)
3. Select "Dev Containers: Reopen in Container"
4. Wait for the container to build and start

## What's Included

- **Go 1.23** - Latest Go version
- **Git** - Version control
- **GitHub CLI** - For GitHub operations
- **VS Code Extensions**:
  - Go extension with formatting and linting
  - GitLens for enhanced Git features
  - Makefile tools
  - Code spell checker

## Development Commands

Once inside the container, you can use:

```bash
# Build the CLI
make build

# Run tests
make test

# Format code
make fmt

# Run checks
make check

# Full CI checks
make ci
```

## Manual Setup

If you prefer not to use Dev Containers, ensure you have:

- Go 1.23.2 or higher
- Git
- (Optional) staticcheck: `go install honnef.co/go/tools/cmd/staticcheck@latest`
