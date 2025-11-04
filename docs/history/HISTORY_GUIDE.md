# JFrog CLI Command History Guide

## Overview

The JFrog CLI Command History feature tracks and stores command execution data, enabling users to analyze their CLI usage patterns, troubleshoot issues, and improve their workflows.

## Features

- **Command Tracking**: Automatically records executed commands
- **Execution Metrics**: Tracks success/failure and execution time
- **Statistics**: Provides insights into most-used commands
- **Filtering**: Filter by success/failure status
- **Privacy**: All data stored locally, never transmitted

---

## Usage

### Viewing History

```bash
# View recent commands (default: last 50)
jf history

# View last 20 commands
jf history --limit 20

# View only failed commands
jf history --failed

# View only successful commands
jf history --success

# View statistics
jf history --stats

# View top 10 most used commands
jf history --stats --limit 10

# Clear all history
jf history --clear
```

### History Output Format

```
Command History (showing 50 of 150 entries):
================================================================================
  1. [2024-01-15 14:23:45] ✓ jf rt upload file.jar repo-local --build-name=mybuild --build-number=1 (1.2s)
  2. [2024-01-15 14:22:10] ✗ jf rt download repo-local/file.jar ./ (2.5s)
  3. [2024-01-15 14:20:30] ✓ jf config show (0.1s)
```

**Legend**:
- `✓` = Successful command
- `✗` = Failed command
- Time in parentheses = Execution duration

---

## Storage Location

### Unix/Linux
```
~/.jfrog/command-history.json
```

### Windows
```
%USERPROFILE%\.jfrog\command-history.json
```

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

## Privacy & Security

### Data Storage
- All history data is stored **locally** on your machine
- No data is transmitted to JFrog servers
- History files are stored in plain JSON (readable for analysis)

### Sensitive Data Filtering

**Important**: The history feature automatically filters sensitive arguments:
- Passwords (`--password`, `--password-stdin`)
- Access tokens (`--access-token`)
- SSH passphrases (`--ssh-passphrase`)

Filtered commands appear as:
```
jf config add myserver --url=https://artifactory.com --user=admin --password=***
```

### Opt-Out

To disable history tracking, you can:
1. Set environment variable: `JFROG_CLI_HISTORY_DISABLED=true`
2. Regularly clear history: `jf history --clear`
3. Manually delete the history file

---

## Statistics & Analysis

### Most Used Commands

```bash
jf history --stats
```

Output:
```
Most Used Commands:
================================================================================
 1. jf rt upload                          145 times
 2. jf rt download                         89 times
 3. jf config show                         67 times
 4. jf rt build-publish                    45 times
 5. jf rt search                           32 times
```

### Filtering Statistics

```bash
# Most common failed commands
jf history --failed --stats

# Most common successful commands
jf history --success --stats
```

---

## Integration Examples

### CI/CD Integration

Track command usage in CI/CD pipelines:

```bash
#!/bin/bash
# In your CI script
START_TIME=$(date +%s.%N)
jf rt upload artifacts/ repo-local --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
EXIT_CODE=$?
END_TIME=$(date +%s.%N)
DURATION=$(echo "$END_TIME - $START_TIME" | bc)

# History will automatically record this (if enabled)
exit $EXIT_CODE
```

### Automated Analysis

Use history data for automated reporting:

```bash
# Get failure rate
FAILED_COUNT=$(jf history --failed --limit 1000 | grep -c "✗")
TOTAL_COUNT=$(jf history --limit 1000 | wc -l)
FAILURE_RATE=$(echo "scale=2; $FAILED_COUNT * 100 / $TOTAL_COUNT" | bc)
echo "Failure rate: ${FAILURE_RATE}%"
```

---

## Advanced Usage

### Export History

```bash
# Export to CSV (using jq - requires jq tool)
jf history --limit 1000 | jq -r '.entries[] | [.timestamp, .command, .success, .execution_time_ms] | @csv' > history.csv
```

### Search History

```bash
# Search for specific command (using grep)
jf history | grep "rt upload"

# Search in JSON file directly
cat ~/.jfrog/command-history.json | jq '.entries[] | select(.command | contains("upload"))'
```

### Custom Analysis Scripts

See `tools/history/` directory for analysis scripts.

---

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JFROG_CLI_HISTORY_DISABLED` | Disable history tracking | `false` |
| `JFROG_CLI_HISTORY_MAX_ENTRIES` | Maximum entries to store | `1000` |
| `JFROG_CLI_HISTORY_FILE` | Custom history file path | `~/.jfrog/command-history.json` |

### History Limits

- **Maximum Entries**: 1000 (oldest entries are removed automatically)
- **Default Display**: 50 entries
- **Maximum Display**: No limit (but may be slow for very large histories)

---

## Troubleshooting

### History Not Recording

1. Check if history is disabled:
   ```bash
   echo $JFROG_CLI_HISTORY_DISABLED
   ```

2. Check file permissions:
   ```bash
   ls -la ~/.jfrog/command-history.json
   ```

3. Check disk space:
   ```bash
   df -h ~/.jfrog/
   ```

### Large History File

If your history file becomes too large:

```bash
# Clear old entries (keeps last 100)
jf history --limit 100 > /tmp/recent_history.json
jf history --clear
# Manually restore if needed
```

### Corrupted History File

If the history file is corrupted:

```bash
# Backup corrupted file
cp ~/.jfrog/command-history.json ~/.jfrog/command-history.json.bak

# Clear and start fresh
jf history --clear
```

---

## Best Practices

1. **Regular Cleanup**: Periodically clear old history
   ```bash
   # Add to cron or scheduled task
   0 0 * * 0 jf history --clear  # Weekly cleanup
   ```

2. **Backup Important History**: Export before clearing
   ```bash
   cp ~/.jfrog/command-history.json ~/backups/history-$(date +%Y%m%d).json
   ```

3. **Monitor Usage**: Use statistics to understand patterns
   ```bash
   jf history --stats > usage-report.txt
   ```

4. **Privacy**: Be aware of sensitive commands in history
   - Use `--password-stdin` instead of `--password`
   - Clear history after sensitive operations

---

## API Reference

### Internal API (for developers)

See `utils/cliutils/history.go` for implementation details.

**Key Functions**:
- `AddCommandToHistory(command, success, duration)` - Add entry
- `GetCommandHistory(limit, filterSuccess)` - Retrieve entries
- `GetMostUsedCommands(limit)` - Get statistics
- `ClearHistory()` - Clear all entries

---

## Examples

### Example 1: Weekly Usage Report

```bash
#!/bin/bash
# Generate weekly report
REPORT_FILE="usage-report-$(date +%Y-%m-%d).txt"

echo "JFrog CLI Usage Report - Week of $(date +%Y-%m-%d)" > $REPORT_FILE
echo "========================================" >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "Most Used Commands:" >> $REPORT_FILE
jf history --stats --limit 10 >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "Failed Commands:" >> $REPORT_FILE
jf history --failed --limit 20 >> $REPORT_FILE

cat $REPORT_FILE
```

### Example 2: Find Slow Commands

```bash
# Using jq to find commands taking > 5 seconds
cat ~/.jfrog/command-history.json | jq -r '.entries[] | select(.execution_time_ms > 5000) | "\(.timestamp) - \(.command) - \(.execution_time_ms)ms"'
```

### Example 3: Command Success Rate

```bash
# Calculate success rate
TOTAL=$(jf history --limit 1000 | grep -c "\[")
SUCCESS=$(jf history --success --limit 1000 | grep -c "\[")
RATE=$(echo "scale=1; $SUCCESS * 100 / $TOTAL" | bc)
echo "Success rate: ${RATE}%"
```

---

## FAQ

**Q: Does history slow down command execution?**
A: No, history tracking is asynchronous and adds minimal overhead (<1ms).

**Q: Can I disable history for specific commands?**
A: Currently, history is all-or-nothing. Use `JFROG_CLI_HISTORY_DISABLED=true` to disable completely.

**Q: How much disk space does history use?**
A: Approximately 1KB per entry. With 1000 entries max, ~1MB total.

**Q: Can I export history to other formats?**
A: Yes, use tools like `jq` to convert JSON to CSV, JSONL, etc. See tools/history/ for examples.

**Q: Is history synchronized across machines?**
A: No, history is local to each machine. You can manually copy the history file if needed.

---

## Related Documentation

- [Architecture Documentation](../ARCHITECTURE.md)
- [Code Patterns](../../CODE_PATTERNS.md)
- [Plugin Development Guide](../../guides/jfrog-cli-plugins-developer-guide.md)

---

*Last Updated: $(date)*
