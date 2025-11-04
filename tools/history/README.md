# JFrog CLI History Tools

A collection of tools for analyzing, exporting, and reporting on JFrog CLI command history.

## Tools

### 1. `analyze_history.sh` - History Analyzer

Analyzes command history and provides insights.

**Usage:**
```bash
./analyze_history.sh [text|json|csv]
```

**Examples:**
```bash
# Human-readable analysis
./analyze_history.sh text

# JSON output
./analyze_history.sh json

# CSV export
./analyze_history.sh csv > analysis.csv
```

**Output includes:**
- Total commands, success/failure counts
- Success rate
- Average execution time
- Top 10 most used commands
- Slowest commands (> 5 seconds)
- Most common failures
- Time distribution (fast/medium/slow)

---

### 2. `export_history.sh` - History Exporter

Exports command history to various formats.

**Usage:**
```bash
./export_history.sh [csv|jsonl|json|markdown] [output_file]
```

**Examples:**
```bash
# Export to CSV (default)
./export_history.sh csv

# Export to JSON Lines
./export_history.sh jsonl history.jsonl

# Export to Markdown
./export_history.sh markdown report.md

# Export to JSON
./export_history.sh json full_history.json
```

**Formats:**
- **CSV**: Comma-separated values, suitable for Excel/Google Sheets
- **JSONL**: JSON Lines format, one command per line
- **JSON**: Pretty-printed JSON with full structure
- **Markdown**: Markdown table format with summary

---

### 3. `search_history.sh` - History Search

Search and filter command history.

**Usage:**
```bash
./search_history.sh <search_term> [success_only] [count]
```

**Examples:**
```bash
# Search for upload commands
./search_history.sh upload

# Search for successful upload commands only
./search_history.sh upload true 10

# Search for failed build commands
./search_history.sh "build-publish" false 20
```

**Parameters:**
- `search_term`: Text to search for (required)
- `success_only`: `true` for successful only, `false` for failed only, omit for all
- `count`: Number of results to show (default: 20)

---

### 4. `generate_report.sh` - Report Generator

Generates comprehensive usage reports in Markdown format.

**Usage:**
```bash
./generate_report.sh [output_file] [period]
```

**Examples:**
```bash
# Generate report for all time
./generate_report.sh

# Generate weekly report
./generate_report.sh weekly_report.md week

# Generate monthly report
./generate_report.sh monthly_report.md month
```

**Periods:**
- `all` - All history (default)
- `week` - Last 7 days
- `month` - Last 30 days
- `year` - Last 365 days

**Report includes:**
- Executive summary
- Top commands by usage
- Most common failures
- Slowest commands
- Performance analysis
- Recommendations

---

## Prerequisites

All tools require:
- **bash** (Unix/Linux/macOS)
- **jq** - JSON processor
  - macOS: `brew install jq`
  - Ubuntu/Debian: `apt-get install jq`
  - RHEL/CentOS: `yum install jq`
- **bc** - Calculator (usually pre-installed)

## Installation

1. Make scripts executable:
```bash
chmod +x tools/history/*.sh
```

2. Add to PATH (optional):
```bash
export PATH="$PATH:$(pwd)/tools/history"
```

## Environment Variables

All tools support these environment variables:

- `JFROG_CLI_HISTORY_FILE` - Custom history file path
  - Default: `~/.jfrog/command-history.json`

## Examples

### Daily Usage Check

```bash
# Quick analysis
./analyze_history.sh text
```

### Weekly Report

```bash
# Generate weekly report
./generate_report.sh weekly_report_$(date +%Y%m%d).md week

# Email report (example)
./generate_report.sh weekly_report.md week | mail -s "JFrog CLI Weekly Report" admin@example.com
```

### Find Problematic Commands

```bash
# Find slow commands
./analyze_history.sh json | jq '.slowest_commands'

# Find most common failures
./analyze_history.sh json | jq '.most_failed'
```

### Export for Analysis

```bash
# Export to CSV for Excel
./export_history.sh csv history.csv

# Export failed commands only
jq '[.entries[] | select(.success == false)]' ~/.jfrog/command-history.json > failures.json
```

### Integration with CI/CD

```bash
#!/bin/bash
# In your CI pipeline

# Generate report
./tools/history/generate_report.sh ci_report.md week

# Upload report artifact
# (implementation depends on your CI system)
```

## Output Examples

### Analyze Output (text)

```
JFrog CLI History Analysis
==========================

Summary:
  Total Commands: 145
  Successful: 132 (91.0%)
  Failed: 13
  Average Execution Time: 1234.56ms

Top 10 Most Used Commands:
---------------------------
 145 jf rt upload
  89 jf rt download
  67 jf config show
  45 jf rt build-publish
  32 jf rt search
```

### Report Output (markdown)

See `generate_report.sh` output for full Markdown report example.

## Troubleshooting

### "jq: command not found"

Install jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# RHEL/CentOS
sudo yum install jq
```

### "History file not found"

Ensure you've run some JFrog CLI commands first:
```bash
jf config show
jf history
```

### "Permission denied"

Make scripts executable:
```bash
chmod +x tools/history/*.sh
```

## Contributing

When adding new tools:

1. Follow existing script patterns
2. Use `jq` for JSON processing
3. Support `JFROG_CLI_HISTORY_FILE` environment variable
4. Provide clear error messages
5. Add examples to this README

## Related Documentation

- [History Guide](../../docs/history/HISTORY_GUIDE.md)
- [Main README](../../README.md)
- [Architecture Documentation](../../docs/ARCHITECTURE.md)

---

*Last Updated: $(date)*
