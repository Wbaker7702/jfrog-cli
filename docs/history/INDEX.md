# JFrog CLI History Documentation Index

Complete documentation for the JFrog CLI Command History feature.

## 📚 Documentation

### User Guides

1. **[HISTORY_GUIDE.md](HISTORY_GUIDE.md)**
   - Complete user guide
   - Usage examples
   - Privacy & security
   - Troubleshooting
   - Best practices

2. **[API_REFERENCE.md](API_REFERENCE.md)**
   - Programmatic API documentation
   - Function reference
   - Code examples
   - Type definitions

---

## 🛠️ Tools

Located in `tools/history/`:

### Analysis Tools

1. **`analyze_history.sh`** - Analyze history and provide insights
   - Text, JSON, or CSV output
   - Statistics and trends
   - Performance analysis

2. **`export_history.sh`** - Export history to various formats
   - CSV, JSONL, JSON, Markdown
   - Custom output files
   - Batch exports

3. **`search_history.sh`** - Search and filter history
   - Text search
   - Success/failure filtering
   - Configurable result count

4. **`generate_report.sh`** - Generate comprehensive reports
   - Markdown reports
   - Time period filtering
   - Executive summaries

### Code Examples

- **`api_examples.go`** - Go code examples
  - How to use the API
  - Common patterns
  - Integration examples

### Tool Documentation

- **[tools/history/README.md](../../tools/history/README.md)** - Complete tool documentation

---

## 🚀 Quick Start

### For Users

1. **Read the Guide**: Start with [HISTORY_GUIDE.md](HISTORY_GUIDE.md)
2. **Try Basic Commands**:
   ```bash
   jf history
   jf history --stats
   jf history --failed
   ```
3. **Use Analysis Tools**: Check out `tools/history/`

### For Developers

1. **Read API Reference**: Start with [API_REFERENCE.md](API_REFERENCE.md)
2. **Review Examples**: See `tools/history/api_examples.go`
3. **Check Implementation**: See `utils/cliutils/history.go`

---

## 📖 Documentation Structure

```
docs/history/
├── INDEX.md              # This file
├── HISTORY_GUIDE.md      # User guide
└── API_REFERENCE.md      # API documentation

tools/history/
├── README.md             # Tool documentation
├── analyze_history.sh    # Analysis tool
├── export_history.sh     # Export tool
├── search_history.sh     # Search tool
├── generate_report.sh    # Report generator
└── api_examples.go       # Code examples
```

---

## 🎯 Use Cases

### 1. Usage Analysis

**Goal**: Understand command usage patterns

**Tools**:
- `jf history --stats`
- `analyze_history.sh`
- `generate_report.sh`

**Example**:
```bash
# Quick stats
jf history --stats

# Detailed analysis
./tools/history/analyze_history.sh text

# Weekly report
./tools/history/generate_report.sh weekly_report.md week
```

### 2. Troubleshooting

**Goal**: Find failed commands and issues

**Tools**:
- `jf history --failed`
- `search_history.sh`

**Example**:
```bash
# View failed commands
jf history --failed

# Search for specific failures
./tools/history/search_history.sh "upload" false
```

### 3. Performance Analysis

**Goal**: Identify slow commands

**Tools**:
- `analyze_history.sh`
- Custom scripts using API

**Example**:
```bash
# Find slow commands
./tools/history/analyze_history.sh json | jq '.slowest_commands'
```

### 4. Reporting

**Goal**: Generate usage reports

**Tools**:
- `generate_report.sh`
- `export_history.sh`

**Example**:
```bash
# Generate monthly report
./tools/history/generate_report.sh monthly_report.md month

# Export to CSV for analysis
./tools/history/export_history.sh csv usage_data.csv
```

### 5. Integration

**Goal**: Integrate history into workflows

**Tools**:
- API (programmatic access)
- Export tools
- Custom scripts

**Example**:
```go
// Using the API
entries, err := cliutils.GetCommandHistory(100, nil)
// Process entries...
```

---

## 🔍 Finding Information

### By Topic

- **Getting Started**: [HISTORY_GUIDE.md](HISTORY_GUIDE.md) - Overview & Usage
- **Privacy & Security**: [HISTORY_GUIDE.md](HISTORY_GUIDE.md) - Privacy & Security section
- **API Usage**: [API_REFERENCE.md](API_REFERENCE.md)
- **Tool Usage**: [tools/history/README.md](../../tools/history/README.md)
- **Code Examples**: [tools/history/api_examples.go](../../tools/history/api_examples.go)

### By Question

- **"How do I view my history?"** → [HISTORY_GUIDE.md](HISTORY_GUIDE.md) - Usage section
- **"How do I export history?"** → [tools/history/README.md](../../tools/history/README.md) - export_history.sh
- **"How do I use the API?"** → [API_REFERENCE.md](API_REFERENCE.md)
- **"How do I analyze history?"** → [tools/history/README.md](../../tools/history/README.md) - analyze_history.sh
- **"Is my data secure?"** → [HISTORY_GUIDE.md](HISTORY_GUIDE.md) - Privacy & Security section

---

## 📊 Feature Matrix

| Feature | CLI Command | Analysis Tool | Export Tool | API |
|---------|-------------|---------------|-------------|-----|
| View history | ✅ | ✅ | ✅ | ✅ |
| Filter by status | ✅ | ✅ | ❌ | ✅ |
| Statistics | ✅ | ✅ | ❌ | ✅ |
| Search | ❌ | ❌ | ✅ | ✅ |
| Export formats | ❌ | ❌ | ✅ | ✅ |
| Reports | ❌ | ✅ | ✅ | ✅ |
| Performance analysis | ❌ | ✅ | ❌ | ✅ |

---

## 🎓 Learning Path

### Beginner
1. Read [HISTORY_GUIDE.md](HISTORY_GUIDE.md) - Overview & Usage sections
2. Try basic commands: `jf history`, `jf history --stats`
3. Explore analysis tools

### Intermediate
1. Read [HISTORY_GUIDE.md](HISTORY_GUIDE.md) - Complete guide
2. Use analysis and export tools
3. Generate reports

### Advanced
1. Read [API_REFERENCE.md](API_REFERENCE.md)
2. Review code examples
3. Integrate into custom workflows
4. Build custom tools

---

## 🔗 Related Documentation

- [Main README](../../README.md)
- [Architecture Documentation](../ARCHITECTURE.md)
- [Code Patterns](../../CODE_PATTERNS.md)
- [Contributing Guide](../../CONTRIBUTING.md)

---

## 📝 Quick Reference

### Common Commands

```bash
# View history
jf history

# View statistics
jf history --stats

# View failed commands
jf history --failed

# Clear history
jf history --clear
```

### Common Tools

```bash
# Analyze history
./tools/history/analyze_history.sh text

# Export to CSV
./tools/history/export_history.sh csv

# Search history
./tools/history/search_history.sh "upload"

# Generate report
./tools/history/generate_report.sh report.md week
```

### Common API Calls

```go
// Get history
entries, _ := cliutils.GetCommandHistory(50, nil)

// Get statistics
mostUsed, _ := cliutils.GetMostUsedCommands(10)

// Add to history
cliutils.AddCommandToHistory("command", true, time.Second)
```

---

## 🆘 Support

### Getting Help

1. **Documentation**: Check relevant docs above
2. **Examples**: See `tools/history/api_examples.go`
3. **Issues**: Report on GitHub

### Troubleshooting

See [HISTORY_GUIDE.md](HISTORY_GUIDE.md) - Troubleshooting section

---

*Last Updated: $(date)*
