# JFrog CLI History API Reference

Programmatic API for accessing and manipulating command history.

## Package

```go
import "github.com/jfrog/jfrog-cli/utils/cliutils"
```

---

## Functions

### AddCommandToHistory

Adds a command execution to the history.

```go
func AddCommandToHistory(command string, success bool, executionTime time.Duration) error
```

**Parameters:**
- `command` - Full command string (e.g., "jf rt upload file.jar repo-local")
- `success` - Whether the command succeeded
- `executionTime` - Command execution duration

**Returns:**
- `error` - Error if operation fails

**Example:**
```go
err := cliutils.AddCommandToHistory(
    "jf rt upload file.jar repo-local",
    true,
    1*time.Second,
)
```

**Notes:**
- Thread-safe (uses mutex locking)
- Automatically limits to 1000 entries (removes oldest)
- History file location: `~/.jfrog/command-history.json`

---

### GetCommandHistory

Retrieves command history entries with optional filtering.

```go
func GetCommandHistory(limit int, filterSuccess *bool) ([]CommandHistoryEntry, error)
```

**Parameters:**
- `limit` - Maximum number of entries to return (0 = all)
- `filterSuccess` - Filter by success status:
  - `nil` - Return all commands
  - `&true` - Return only successful commands
  - `&false` - Return only failed commands

**Returns:**
- `[]CommandHistoryEntry` - Array of history entries (sorted by timestamp, newest first)
- `error` - Error if operation fails

**Example:**
```go
// Get last 50 commands
entries, err := cliutils.GetCommandHistory(50, nil)

// Get last 20 successful commands
successOnly := true
entries, err := cliutils.GetCommandHistory(20, &successOnly)

// Get all failed commands
failedOnly := false
entries, err := cliutils.GetCommandHistory(0, &failedOnly)
```

---

### GetMostUsedCommands

Returns statistics about most frequently used commands.

```go
func GetMostUsedCommands(limit int) (map[string]int, error)
```

**Parameters:**
- `limit` - Maximum number of commands to return (0 = all)

**Returns:**
- `map[string]int` - Map of command -> count (sorted by frequency)
- `error` - Error if operation fails

**Example:**
```go
mostUsed, err := cliutils.GetMostUsedCommands(10)
for cmd, count := range mostUsed {
    fmt.Printf("%s: %d times\n", cmd, count)
}
```

**Notes:**
- Commands are sorted by frequency (most used first)
- Returns up to `limit` commands

---

### ClearHistory

Removes all history entries.

```go
func ClearHistory() error
```

**Returns:**
- `error` - Error if operation fails

**Example:**
```go
err := cliutils.ClearHistory()
if err != nil {
    log.Fatal(err)
}
```

**Warning:**
- This operation is irreversible
- Consider exporting history before clearing

---

## Types

### CommandHistoryEntry

Represents a single command execution in history.

```go
type CommandHistoryEntry struct {
    Command       string        `json:"command"`
    Timestamp     time.Time     `json:"timestamp"`
    Success       bool          `json:"success"`
    ExecutionTime time.Duration `json:"execution_time_ms,omitempty"`
}
```

**Fields:**
- `Command` - Full command string
- `Timestamp` - When the command was executed
- `Success` - Whether the command succeeded
- `ExecutionTime` - Command execution duration (may be 0 if not tracked)

**Example:**
```go
entry := cliutils.CommandHistoryEntry{
    Command:       "jf rt upload file.jar repo-local",
    Timestamp:     time.Now(),
    Success:       true,
    ExecutionTime: 1 * time.Second,
}
```

---

## Constants

### maxHistoryEntries

Maximum number of entries stored in history.

```go
const maxHistoryEntries = 1000
```

When this limit is reached, oldest entries are automatically removed.

---

## Storage

### File Location

- **Unix/Linux**: `~/.jfrog/command-history.json`
- **Windows**: `%USERPROFILE%\.jfrog\command-history.json`

### File Format

```json
{
  "entries": [
    {
      "command": "jf rt upload file.jar repo-local",
      "timestamp": "2024-01-15T14:23:45Z",
      "success": true,
      "execution_time_ms": 1200
    }
  ]
}
```

---

## Thread Safety

All API functions are **thread-safe** and use mutex locking to prevent race conditions.

**Example:**
```go
// Safe to call from multiple goroutines
go func() {
    cliutils.AddCommandToHistory("cmd1", true, time.Second)
}()

go func() {
    cliutils.AddCommandToHistory("cmd2", true, time.Second)
}()
```

---

## Error Handling

All functions return errors that should be checked:

```go
entries, err := cliutils.GetCommandHistory(50, nil)
if err != nil {
    // Handle error
    log.Fatal(err)
}
```

**Common Errors:**
- File system errors (permissions, disk full)
- JSON parsing errors (corrupted file)
- Invalid arguments

---

## Examples

### Complete Example

```go
package main

import (
    "fmt"
    "time"
    "github.com/jfrog/jfrog-cli/utils/cliutils"
)

func main() {
    // Add a command to history
    err := cliutils.AddCommandToHistory(
        "jf rt upload file.jar repo-local",
        true,
        1*time.Second,
    )
    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }

    // Get history
    entries, err := cliutils.GetCommandHistory(10, nil)
    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }

    // Print history
    for i, entry := range entries {
        status := "✓"
        if !entry.Success {
            status = "✗"
        }
        fmt.Printf("%d. [%s] %s %s\n",
            i+1,
            entry.Timestamp.Format("2006-01-02 15:04:05"),
            status,
            entry.Command,
        )
    }

    // Get statistics
    mostUsed, err := cliutils.GetMostUsedCommands(5)
    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }

    fmt.Println("\nMost Used Commands:")
    for cmd, count := range mostUsed {
        fmt.Printf("  %s: %d times\n", cmd, count)
    }
}
```

### Filtering Example

```go
// Get only successful commands
successOnly := true
successful, err := cliutils.GetCommandHistory(0, &successOnly)

// Get only failed commands
failedOnly := false
failed, err := cliutils.GetCommandHistory(0, &failedOnly)

// Get all commands
all, err := cliutils.GetCommandHistory(0, nil)
```

### Statistics Example

```go
entries, err := cliutils.GetCommandHistory(0, nil)
if err != nil {
    return err
}

total := len(entries)
successful := 0
totalTime := time.Duration(0)
timeCount := 0

for _, entry := range entries {
    if entry.Success {
        successful++
    }
    if entry.ExecutionTime > 0 {
        totalTime += entry.ExecutionTime
        timeCount++
    }
}

successRate := float64(successful) * 100 / float64(total)
avgTime := totalTime / time.Duration(timeCount)

fmt.Printf("Success Rate: %.1f%%\n", successRate)
fmt.Printf("Average Time: %v\n", avgTime)
```

---

## Best Practices

1. **Check Errors**: Always check returned errors
2. **Limit Results**: Use reasonable limits when retrieving history
3. **Handle Empty Results**: Check if slice is empty before processing
4. **Thread Safety**: API is thread-safe, but be careful with concurrent writes
5. **File Permissions**: Ensure history file has proper permissions

---

## Limitations

1. **Maximum Entries**: Limited to 1000 entries (oldest removed automatically)
2. **Local Storage**: History is stored locally, not synchronized
3. **No Encryption**: History file is stored in plain JSON
4. **Sensitive Data**: Commands with passwords should be filtered (implementation pending)

---

## Related Documentation

- [History Guide](HISTORY_GUIDE.md)
- [Code Examples](../../tools/history/api_examples.go)
- [Architecture Documentation](../ARCHITECTURE.md)

---

*Last Updated: $(date)*
