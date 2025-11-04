# JFrog CLI Makefile
# Common development tasks

.PHONY: help build test fmt vet clean deps install coverage lint

# Default target
help:
	@echo "JFrog CLI - Development Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build       - Build the jf CLI binary"
	@echo "  make test        - Run all tests"
	@echo "  make fmt         - Format all Go code"
	@echo "  make vet         - Run go vet"
	@echo "  make lint        - Run static analysis (requires staticcheck)"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make deps        - Download dependencies"
	@echo "  make install     - Install jf CLI to GOPATH/bin"
	@echo "  make coverage    - Generate test coverage report"
	@echo "  make build-info  - Show build information"
	@echo ""

# Build the CLI
build:
	@echo "Building JFrog CLI..."
	@if [ -f build/build.sh ]; then \
		./build/build.sh; \
	else \
		go build -o jf .; \
	fi
	@echo "Build complete! Binary: ./jf"

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Run go vet
vet:
	@echo "Running go vet..."
	go vet ./...

# Run static analysis (requires staticcheck)
lint:
	@echo "Running static analysis..."
	@if command -v staticcheck >/dev/null 2>&1; then \
		staticcheck ./...; \
	else \
		echo "staticcheck not found. Install with: go install honnef.co/go/tools/cmd/staticcheck@latest"; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f jf jf.exe
	rm -rf .jfrog
	@echo "Clean complete!"

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy
	@echo "Dependencies updated!"

# Install to GOPATH/bin
install: build
	@echo "Installing to $(GOPATH)/bin..."
	@if [ -z "$(GOPATH)" ]; then \
		echo "GOPATH not set. Installing to ~/go/bin"; \
		cp jf ~/go/bin/jf 2>/dev/null || cp jf $(HOME)/go/bin/jf 2>/dev/null || echo "Could not install. Please set GOPATH or install manually."; \
	else \
		cp jf $(GOPATH)/bin/jf; \
	fi
	@echo "Installation complete!"

# Generate test coverage
coverage:
	@echo "Generating test coverage report..."
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Show build information
build-info:
	@echo "JFrog CLI Build Information"
	@echo "=========================="
	@echo "Go version: $(shell go version 2>/dev/null || echo 'Go not installed')"
	@echo "Git commit: $(shell git rev-parse --short HEAD 2>/dev/null || echo 'Not a git repo')"
	@echo "Git branch: $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'Not a git repo')"
	@echo "Build date: $(shell date)"

# Quick check (fmt + vet)
check: fmt vet
	@echo "Code check complete!"

# Full CI check (fmt + vet + test)
ci: fmt vet test
	@echo "CI checks complete!"
