# JFrog CLI Architecture

## Overview

JFrog CLI is a modular command-line interface built in Go that provides unified access to the JFrog Platform ecosystem. This document describes the architectural decisions and patterns used in the codebase.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User Input                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  main.go                                 │
│  - Command registration                                  │
│  - Typo detection                                        │
│  - Trace ID generation                                   │
│  - Error handling                                        │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌───────────┐ ┌───────────┐ ┌───────────┐
│Embedded   │ │Core       │ │External   │
│Plugins    │ │Commands   │ │Plugins    │
│           │ │           │ │           │
│- Security │ │- Artifactory│- User     │
│- Artifactory│- Distribution│installed │
│- Platform │ │- Mission   │           │
│  Services │ │  Control   │           │
└───────────┘ └───────────┘ └───────────┘
        │            │            │
        └────────────┼────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              jfrog-cli-core                             │
│  - Configuration management                             │
│  - HTTP client utilities                                │
│  - Common utilities                                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              jfrog-client-go                             │
│  - REST API clients                                     │
│  - Authentication                                       │
│  - Request/Response handling                            │
└─────────────────────────────────────────────────────────┘
```

## Command Registration Pattern

All commands follow a consistent registration pattern:

### 1. Command Namespace Definition

Each service/feature defines its commands in a `cli.go` file:

```go
// Example: artifactory/cli.go
func GetCommands() []cli.Command {
    return []cli.Command{
        {
            Name: "upload",
            Action: upload.UploadCmd,
            // ... other fields
        },
        // ... more commands
    }
}
```

### 2. Main Registration

Commands are registered in `main.go`:

```go
func getCommands() ([]cli.Command, error) {
    commands := []cli.Command{
        {
            Name: "rt",
            Subcommands: artifactory.GetCommands(),
            Category: commandNamespacesCategory,
        },
        // ... more namespaces
    }
    return commands, nil
}
```

### 3. Command Execution Flow

```
User Input
    │
    ▼
CLI Framework (urfave/cli)
    │
    ▼
Command Handler (e.g., upload.UploadCmd)
    │
    ├─► Input Validation
    ├─► Configuration Loading
    ├─► Business Logic
    └─► Output Formatting
```

## Plugin System Architecture

### Embedded Plugins

Embedded plugins are compiled directly into the CLI binary:

- **Security Plugin** (`jfrog-cli-security`)
- **Artifactory Plugin** (`jfrog-cli-artifactory`)
- **Platform Services Plugin** (`jfrog-cli-platform-services`)

These are converted from plugin format to CLI commands using `ConvertEmbeddedPlugin()`.

### External Plugins

External plugins are dynamically loaded:

1. **Discovery**: Plugins are installed in `~/.jfrog/plugins/`
2. **Execution**: Plugins run as separate processes
3. **Communication**: Via CLI arguments and environment variables
4. **Registry**: Public plugins are registered in `jfrog-cli-plugins-reg`

### Plugin Lifecycle

```
Installation
    │
    ├─► Download from registry
    ├─► Verify signature/hash
    ├─► Extract to plugin directory
    └─► Register in plugin manifest

Execution
    │
    ├─► Load plugin binary
    ├─► Execute with context
    ├─► Capture output
    └─► Handle errors
```

## Configuration Management

### Configuration Storage

Configurations are stored in:
- **Unix/Linux**: `~/.jfrog/jfrog-cli.conf`
- **Windows**: `%USERPROFILE%\.jfrog\jfrog-cli.conf`

### Configuration Structure

```yaml
servers:
  - serverId: "server1"
    url: "https://artifactory.example.com"
    user: "admin"
    password: "***"  # Encrypted
    # ... other fields
```

### Configuration Loading

1. Load from file
2. Decrypt sensitive fields
3. Merge with environment variables
4. Validate configuration
5. Return configuration object

## Error Handling

### Error Propagation

```
Command Handler
    │
    ├─► Validation Errors → User-friendly message
    ├─► Network Errors → Retry logic
    ├─► Authentication Errors → Re-authenticate prompt
    └─► Unknown Errors → Log with trace ID
```

### Trace ID System

Every command execution generates a unique trace ID:

1. **Generation**: 16-character hexadecimal string
2. **Storage**: Set as HTTP header (`X-Trace-Id`)
3. **Logging**: Included in error messages
4. **Purpose**: Correlate CLI operations with server logs

## Build Tools Integration

### Integration Pattern

Each build tool follows a similar pattern:

```
Build Tool Command (e.g., mvn, gradle, npm)
    │
    ├─► Wrapper Script Injection
    ├─► Environment Variable Setup
    ├─► Execute Build Tool
    ├─► Collect Build Info
    └─► Upload to Artifactory
```

### Build Info Collection

Build info is collected using the `build-info-go` library:

1. **Start Build**: Create build info object
2. **Track Dependencies**: Monitor dependency resolution
3. **Track Artifacts**: Monitor artifact creation
4. **Finish Build**: Finalize build info
5. **Publish**: Upload to Artifactory/Xray

## Security Considerations

### Credential Storage

- **Encryption**: Credentials are encrypted at rest
- **OS Integration**: (Future) Integration with OS credential stores
- **Token Rotation**: Support for token refresh

### Authentication Methods

1. **Username/Password**: Basic auth
2. **Access Tokens**: API tokens
3. **SSH Keys**: For SSH connections
4. **Certificate Authentication**: Client certificates

### Network Security

- **TLS Verification**: Validates certificates
- **Proxy Support**: HTTP/HTTPS proxy configuration
- **Connection Pooling**: Efficient connection reuse

## Performance Optimizations

### Concurrent Operations

- **Multithreading**: Parallel upload/download
- **Thread Pool**: Configurable thread count
- **Connection Pooling**: Reuse HTTP connections

### Checksum Optimization

- **Skip Upload**: If checksum matches
- **Partial Downloads**: Resume interrupted downloads
- **Checksum Verification**: Verify file integrity

## Testing Strategy

### Test Types

1. **Unit Tests**: Test individual functions
2. **Integration Tests**: Test with real services
3. **Build Tool Tests**: Test build tool integrations
4. **Plugin Tests**: Test plugin system

### Test Infrastructure

- **Test Containers**: Docker containers for integration tests
- **Test Data**: Extensive testdata directory
- **Mock Services**: Mock HTTP servers for unit tests

## Extension Points

### Adding New Commands

1. Create command file in appropriate package
2. Implement command handler function
3. Register in `GetCommands()` function
4. Add documentation in `docs/` directory

### Adding New Build Tool

1. Create package in `buildtools/`
2. Implement wrapper script
3. Integrate with build-info-go
4. Add tests
5. Update documentation

### Creating Plugins

1. Use plugin template
2. Implement plugin commands
3. Add tests
4. Publish to registry

## Future Architecture Considerations

### Proposed Enhancements

1. **Command History**: Track and suggest commands
2. **Configuration Templates**: Pre-defined configs
3. **Batch Operations**: Execute multiple commands
4. **Command Aliases**: User-defined shortcuts
5. **Metrics Collection**: Usage analytics (opt-in)
6. **Structured Logging**: JSON log output
7. **Credential Store Integration**: OS credential managers

### Technical Debt

- **Dependency Management**: Some dependencies pinned to specific versions
- **Error Messages**: Some errors could be more user-friendly
- **Documentation**: Some internal APIs lack documentation
- **Test Coverage**: Some areas need more tests

## References

- [CLI Documentation](https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli)
- [Plugin Developer Guide](../guides/jfrog-cli-plugins-developer-guide.md)
- [Contributing Guide](../CONTRIBUTING.md)
