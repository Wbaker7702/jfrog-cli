# JFrog CLI - Code Patterns & Quick Reference

A quick reference guide for common patterns, code snippets, and implementation examples found in the JFrog CLI codebase.

---

## 📋 Table of Contents

1. [Command Registration](#command-registration)
2. [Flag Extraction](#flag-extraction)
3. [Error Handling](#error-handling)
4. [Configuration Management](#configuration-management)
5. [Build Tool Integration](#build-tool-integration)
6. [File Operations](#file-operations)
7. [HTTP Client Usage](#http-client-usage)
8. [Plugin Development](#plugin-development)

---

## Command Registration

### Basic Command Structure

```go
{
    Name:         "command-name",
    Aliases:      []string{"alias1", "alias2"},
    Usage:        "Command description",
    HelpName:     corecommon.CreateUsage("command-name", description, usage),
    UsageText:    "Argument descriptions",
    ArgsUsage:    common.CreateEnvVars(),
    BashComplete: corecommon.CreateBashCompletionFunc(),
    Category:     "Category Name",
    Flags:        cliutils.GetCommandFlags(cliutils.CommandKey),
    Action:       CommandHandler,
}
```

### Command with Skip Flag Parsing

```go
{
    Name:            "mvn",
    SkipFlagParsing: true,  // Pass all args to handler
    Action:          MvnCmd,
}
```

### Command Handler Pattern

```go
func CommandHandler(c *cli.Context) error {
    // 1. Show help if needed
    if show, err := cliutils.ShowCmdHelpIfNeeded(c, c.Args()); show || err != nil {
        return err
    }
    
    // 2. Validate arguments
    if c.NArg() != expectedCount {
        return cliutils.WrongNumberOfArgumentsHandler(c)
    }
    
    // 3. Extract configuration
    rtDetails, err := cliutils.CreateArtifactoryDetailsByFlags(c)
    if err != nil {
        return err
    }
    
    // 4. Execute command
    cmd := NewCommand()
    cmd.SetServerDetails(rtDetails)
    return commands.Exec(cmd)
}
```

---

## Flag Extraction

### Extract CLI Flags from Build Tool Args

```go
// Extract insecure TLS flag
filteredArgs, insecureTls, err := coreutils.ExtractInsecureTlsFromArgs(args)

// Extract build configuration
filteredArgs, buildConfig, err := build.ExtractBuildDetailsFromArgs(filteredArgs)

// Extract thread count
filteredArgs, threads, err := extractThreadsFlag(filteredArgs)

// Extract Xray scan flag
filteredArgs, xrayScan, err := coreutils.ExtractXrayScanFromArgs(filteredArgs)
```

### Extract Command Arguments

```go
// Extract full command (all args after command name)
args := cliutils.ExtractCommand(c)

// Get specific argument
arg1 := c.Args().Get(0)
arg2 := c.Args().Get(1)

// Check if flag is set
if c.IsSet("flag-name") {
    value := c.String("flag-name")
}
```

---

## Error Handling

### Standard Error Handling Pattern

```go
func SomeFunction() error {
    if err := doSomething(); err != nil {
        return errorutils.CheckError(err)
    }
    return nil
}
```

### Error with User-Friendly Message

```go
if err != nil {
    return cliutils.PrintHelpAndReturnError(
        "Custom error message",
        c,
    )
}
```

### Accumulate Errors (Non-Fatal)

```go
var finalErr error
for _, item := range items {
    if err := process(item); err != nil {
        finalErr = err  // Continue processing, keep last error
        log.Error("Failed to process item:", err)
    }
}
return finalErr
```

### Trace ID on Error

```go
func logTraceIdOnFailure(err error) {
    if err == nil || traceID == "" {
        return
    }
    clientlog.Info(traceIdLogMsg, traceID)
}
```

---

## Configuration Management

### Create Server Details from Flags

```go
rtDetails, err := cliutils.CreateArtifactoryDetailsByFlags(c)
if err != nil {
    return err
}
```

### Get Server Configuration

```go
// Get default server
rtDetails, err := config.GetDefaultServerConf()

// Get specific server
rtDetails, err := config.GetSpecificConfig(serverId, false, true)
```

### Handle Secret Input

```go
password, err := handleSecretInput(c, password, passwordStdin)
// Supports both --password and --password-stdin
```

### Configuration File Structure

```yaml
servers:
  - serverId: "server1"
    url: "https://artifactory.example.com"
    user: "admin"
    password: "***"  # Encrypted
    accessToken: "***"  # Or use token
```

---

## Build Tool Integration

### Maven Command Pattern

```go
func MvnCmd(c *cli.Context) error {
    // Extract CLI flags
    args := cliutils.ExtractCommand(c)
    filteredArgs, buildConfig, err := build.ExtractBuildDetailsFromArgs(args)
    
    // Create Maven command
    mvnCmd := mvn.NewMvnCommand()
        .SetConfiguration(buildConfig)
        .SetGoals(filteredArgs)
        .SetThreads(threads)
        .SetXrayScan(xrayScan)
    
    // Execute
    err = commands.Exec(mvnCmd)
    result := mvnCmd.Result()
    defer cliutils.CleanupResult(result, &err)
    
    // Print summary
    return cliutils.PrintCommandSummary(result, detailedSummary, printDeploymentView, false, err)
}
```

### Build Configuration

```go
buildConfig := cliutils.CreateBuildConfiguration(c)
buildConfig.ValidateBuildParams()

// With module
buildConfig := cliutils.CreateBuildConfigurationWithModule(c)
```

### Upload Configuration

```go
uploadConfig := &artifactoryUtils.UploadConfiguration{
    MinSplitSizeMB: 200,
    SplitCount:     5,
    ChunkSizeMB:    20,
    Threads:        3,
}
```

### Download Configuration

```go
downloadConfig := &artifactoryUtils.DownloadConfiguration{
    MinSplitSize: 5120,  // KB
    SplitCount:    3,
    Threads:       3,
    SkipChecksum:  false,
}
```

---

## File Operations

### File Existence Check

```go
exists, err := fileutils.IsFileExists(filePath, false)
if err != nil {
    return err
}
if !exists {
    return errorutils.CheckErrorf("file not found")
}
```

### Directory Operations

```go
// Check if directory exists
exists, err := fileutils.IsDirExists(dirPath, false)

// Create directory if needed
if !exists {
    err = os.MkdirAll(dirPath, 0755)
}

// Check if directory is empty
empty, err := fileutils.IsDirEmpty(dirPath)
```

### Read/Write Files

```go
// Read file
content, err := fileutils.ReadFile(filePath)

// Write file
err = os.WriteFile(filePath, content, 0644)

// Read JSON
data, err := os.ReadFile(jsonPath)
var config Config
err = json.Unmarshal(data, &config)

// Write JSON
data, err := json.MarshalIndent(config, "", "  ")
err = os.WriteFile(jsonPath, data, 0644)
```

---

## HTTP Client Usage

### Create HTTP Client

```go
client, err := httpclient.ClientBuilder().Build()
if err != nil {
    return err
}
```

### Make HTTP Request

```go
req, err := http.NewRequest(http.MethodPost, url, bytes.NewBuffer(body))
if err != nil {
    return err
}

req.Header.Set("Content-Type", "application/json")
req.Header.Set("X-Trace-Id", traceID)

resp, err := client.GetClient().Do(req)
if err != nil {
    return err
}
defer resp.Body.Close()

// Check status
if err = errorutils.CheckResponseStatus(resp, http.StatusOK); err != nil {
    return err
}

// Read body
body, err := io.ReadAll(resp.Body)
```

### Retry Logic

```go
retries := 3
retryWaitMs := 0

for i := 0; i < retries; i++ {
    resp, err := client.Do(req)
    if err == nil && resp.StatusCode == http.StatusOK {
        return resp, nil
    }
    if i < retries-1 {
        time.Sleep(time.Duration(retryWaitMs) * time.Millisecond)
    }
}
return nil, err
```

---

## Plugin Development

### Plugin Signature Structure

```go
type PluginSignature struct {
    Name     string   `json:"name"`
    Usage    string   `json:"usage"`
    Commands []string `json:"commands,omitempty"`
}
```

### Execute Plugin Command

```go
cmd := exec.Command(pluginExecPath, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
cmd.Stdin = os.Stdin
return cmd.Run()
```

### Get Plugin Signatures

```go
pluginsDir, err := coreutils.GetJfrogPluginsDir()
plugins, err := coreutils.GetPluginsDirContent()

for _, p := range plugins {
    execPath := filepath.Join(pluginsDir, pluginName, "exec", pluginName)
    output, err := gofrogcmd.RunCmdOutput(&PluginExecCmd{
        execPath,
        []string{"signature"},
    })
    
    var sig PluginSignature
    json.Unmarshal([]byte(output), &sig)
}
```

---

## Utility Functions

### Get Environment Variable with Default

```go
value := getOrDefaultEnv(flagValue, envVarName)
```

### Ask Yes/No Question

```go
if !coreutils.AskYesNo("Continue?", false) {
    return nil
}
```

### Print Messages

```go
log.Output("Message")
log.Info("Info message")
log.Debug("Debug message")
log.Error("Error message")
log.Warn("Warning message")

// Formatted output
log.Output(coreutils.PrintTitle("Title"))
log.Output(coreutils.PrintBoldTitle("Bold Title"))
log.Output(coreutils.PrintComment("Comment"))
log.Output(coreutils.PrintLink("https://example.com"))
```

### Quiet Mode Check

```go
quiet := cliutils.GetQuietValue(c)
// Returns true if --quiet or CI=true
```

### Interactive Mode Check

```go
interactive := cliutils.GetInteractiveValue(c)
// Returns false if CI=true, true otherwise
```

---

## Command Result Handling

### Result Pattern

```go
cmd := NewCommand()
err = commands.Exec(cmd)
result := cmd.Result()
defer cliutils.CleanupResult(result, &err)

// Access result
successCount := result.SuccessCount()
failCount := result.FailCount()

// Print summary
err = cliutils.PrintCommandSummary(
    result,
    detailedSummary,
    printDeploymentView,
    false,
    err,
)
```

### Cleanup Pattern

```go
defer func() {
    if cleanupErr := fileutils.CleanOldDirs(); cleanupErr != nil {
        log.Warn("Cleanup failed:", cleanupErr)
    }
}()
```

---

## Testing Patterns

### Test Helper Pattern

```go
func initArtifactoryTest(t *testing.T, testName string) {
    // Setup test environment
    authenticate(false)
    // ...
}

func cleanArtifactoryTest() {
    // Cleanup test data
}
```

### Test Command Execution

```go
jfrogCli := coretests.NewJfrogCli(execMain, "jfrog", "")
err := jfrogCli.Exec("rt", "upload", "file", "repo/path")
assert.NoError(t, err)
```

### Run with Retries

```go
func runCmdWithRetries(t *testing.T, cmd func() error) {
    for i := 0; i < 3; i++ {
        if err := cmd(); err == nil {
            return
        }
        time.Sleep(time.Second)
    }
    t.Fail()
}
```

---

## Common Constants

### Default Values

```go
const (
    Retries = 3
    RetryWaitMilliSecs = 0
    UploadMinSplitMb = 200
    UploadSplitCount = 5
    UploadChunkSizeMb = 20
    DownloadMinSplitKb = 5120
    DownloadSplitCount = 3
)
```

### File Paths

```go
// JFrog home directory
homeDir, err := coreutils.GetJfrogHomeDir()
// ~/.jfrog or %USERPROFILE%\.jfrog

// Plugins directory
pluginsDir, err := coreutils.GetJfrogPluginsDir()
// ~/.jfrog/plugins

// Dependencies directory
depsDir, err := coreutils.GetJfrogDependenciesDir()
// ~/.jfrog/dependencies
```

---

## Best Practices

### 1. Always Validate Input

```go
if c.NArg() != expectedCount {
    return cliutils.WrongNumberOfArgumentsHandler(c)
}
```

### 2. Handle Errors Properly

```go
if err != nil {
    return errorutils.CheckError(err)
}
```

### 3. Clean Up Resources

```go
defer func() {
    if cleanupErr := cleanup(); cleanupErr != nil {
        log.Warn("Cleanup failed:", cleanupErr)
    }
}()
```

### 4. Provide Helpful Messages

```go
return cliutils.PrintHelpAndReturnError(
    "Clear error message with suggestion",
    c,
)
```

### 5. Use Trace IDs

```go
httpclient.SetUberTraceIdToken(traceID)
// Automatically added to HTTP requests
```

---

## Quick Checklist for New Commands

- [ ] Register command in appropriate `GetCommands()` function
- [ ] Add command flags to `commandsflags.go`
- [ ] Implement command handler
- [ ] Add input validation
- [ ] Handle errors properly
- [ ] Add cleanup if needed
- [ ] Print command summary
- [ ] Add tests
- [ ] Add documentation in `docs/` directory
- [ ] Update help text

---

*Quick reference for JFrog CLI development*
*Based on codebase patterns*
