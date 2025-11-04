#!/bin/bash
# JFrog CLI History Exporter
# Exports command history to various formats

set -e

HISTORY_FILE="${JFROG_CLI_HISTORY_FILE:-$HOME/.jfrog/command-history.json}"
OUTPUT_FORMAT="${1:-csv}"  # csv, jsonl, json, markdown
OUTPUT_FILE="${2:-}"

if [ ! -f "$HISTORY_FILE" ]; then
    echo "Error: History file not found at $HISTORY_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for export. Install it first:"
    echo "  macOS: brew install jq"
    echo "  Linux: apt-get install jq or yum install jq"
    exit 1
fi

# Generate output filename if not provided
if [ -z "$OUTPUT_FILE" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    case "$OUTPUT_FORMAT" in
        csv) OUTPUT_FILE="jfrog_history_${TIMESTAMP}.csv" ;;
        jsonl) OUTPUT_FILE="jfrog_history_${TIMESTAMP}.jsonl" ;;
        json) OUTPUT_FILE="jfrog_history_${TIMESTAMP}.json" ;;
        markdown) OUTPUT_FILE="jfrog_history_${TIMESTAMP}.md" ;;
    esac
fi

export_csv() {
    echo "timestamp,command,success,execution_time_ms,execution_time_formatted" > "$OUTPUT_FILE"
    jq -r '.entries[] | [
        .timestamp,
        .command | gsub("\""; "\"\""),
        .success,
        .execution_time_ms,
        (if .execution_time_ms > 0 then "\(.execution_time_ms)ms" else "" end)
    ] | @csv' "$HISTORY_FILE" >> "$OUTPUT_FILE"
    echo "Exported to $OUTPUT_FILE"
}

export_jsonl() {
    jq -c '.entries[]' "$HISTORY_FILE" > "$OUTPUT_FILE"
    echo "Exported to $OUTPUT_FILE"
}

export_json() {
    jq '.' "$HISTORY_FILE" > "$OUTPUT_FILE"
    echo "Exported to $OUTPUT_FILE"
}

export_markdown() {
    {
        echo "# JFrog CLI Command History"
        echo ""
        echo "Export Date: $(date)"
        echo ""
        echo "## Summary"
        echo ""
        TOTAL=$(jq '.entries | length' "$HISTORY_FILE")
        SUCCESS=$(jq '[.entries[] | select(.success == true)] | length' "$HISTORY_FILE")
        FAILED=$(jq '[.entries[] | select(.success == false)] | length' "$HISTORY_FILE")
        SUCCESS_RATE=$(echo "scale=1; $SUCCESS * 100 / $TOTAL" | bc)
        echo "- Total Commands: $TOTAL"
        echo "- Successful: $SUCCESS ($SUCCESS_RATE%)"
        echo "- Failed: $FAILED"
        echo ""
        echo "## Commands"
        echo ""
        echo "| Timestamp | Command | Status | Duration |"
        echo "|-----------|---------|--------|----------|"
        jq -r '.entries[] | "| \(.timestamp) | `\(.command)` | \(if .success then "✓" else "✗" end) | \(if .execution_time_ms > 0 then "\(.execution_time_ms)ms" else "-" end) |"' "$HISTORY_FILE" >> "$OUTPUT_FILE"
    } > "$OUTPUT_FILE"
    echo "Exported to $OUTPUT_FILE"
}

case "$OUTPUT_FORMAT" in
    csv)
        export_csv
        ;;
    jsonl)
        export_jsonl
        ;;
    json)
        export_json
        ;;
    markdown)
        export_markdown
        ;;
    *)
        echo "Usage: $0 [csv|jsonl|json|markdown] [output_file]"
        echo ""
        echo "Formats:"
        echo "  csv      - CSV format (default)"
        echo "  jsonl    - JSON Lines format (one JSON object per line)"
        echo "  json     - Pretty-printed JSON"
        echo "  markdown - Markdown table format"
        echo ""
        echo "Examples:"
        echo "  $0 csv"
        echo "  $0 csv my_history.csv"
        echo "  $0 jsonl history.jsonl"
        exit 1
        ;;
esac
