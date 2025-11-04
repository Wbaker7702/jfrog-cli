package main

// JFrog CLI History API Examples
// This file demonstrates how to use the history API programmatically

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/jfrog/jfrog-cli/utils/cliutils"
)

// Example 1: Add a command to history
func ExampleAddCommand() {
	command := "jf rt upload file.jar repo-local"
	success := true
	executionTime := 1 * time.Second

	err := cliutils.AddCommandToHistory(command, success, executionTime)
	if err != nil {
		fmt.Printf("Error adding to history: %v\n", err)
		return
	}
	fmt.Println("Command added to history")
}

// Example 2: Retrieve command history
func ExampleGetHistory() {
	limit := 50
	var filterSuccess *bool // nil = all commands

	entries, err := cliutils.GetCommandHistory(limit, filterSuccess)
	if err != nil {
		fmt.Printf("Error retrieving history: %v\n", err)
		return
	}

	fmt.Printf("Found %d history entries:\n", len(entries))
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
}

// Example 3: Get most used commands
func ExampleGetMostUsed() {
	limit := 10

	mostUsed, err := cliutils.GetMostUsedCommands(limit)
	if err != nil {
		fmt.Printf("Error getting statistics: %v\n", err)
		return
	}

	fmt.Println("Most Used Commands:")
	for cmd, count := range mostUsed {
		fmt.Printf("  %s: %d times\n", cmd, count)
	}
}

// Example 4: Filter by success status
func ExampleFilterBySuccess() {
	limit := 100
	successOnly := true
	filterSuccess := &successOnly

	entries, err := cliutils.GetCommandHistory(limit, filterSuccess)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Printf("Found %d successful commands\n", len(entries))
}

// Example 5: Clear history
func ExampleClearHistory() {
	err := cliutils.ClearHistory()
	if err != nil {
		fmt.Printf("Error clearing history: %v\n", err)
		return
	}
	fmt.Println("History cleared")
}

// Example 6: Export history to JSON
func ExampleExportJSON() {
	entries, err := cliutils.GetCommandHistory(0, nil) // 0 = all entries
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	data, err := json.MarshalIndent(entries, "", "  ")
	if err != nil {
		fmt.Printf("Error marshaling: %v\n", err)
		return
	}

	err = os.WriteFile("history_export.json", data, 0644)
	if err != nil {
		fmt.Printf("Error writing file: %v\n", err)
		return
	}

	fmt.Println("History exported to history_export.json")
}

// Example 7: Calculate statistics
func ExampleCalculateStats() {
	entries, err := cliutils.GetCommandHistory(0, nil)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	total := len(entries)
	successful := 0
	failed := 0
	totalTime := time.Duration(0)
	timeCount := 0

	for _, entry := range entries {
		if entry.Success {
			successful++
		} else {
			failed++
		}
		if entry.ExecutionTime > 0 {
			totalTime += entry.ExecutionTime
			timeCount++
		}
	}

	successRate := float64(successful) * 100 / float64(total)
	avgTime := time.Duration(0)
	if timeCount > 0 {
		avgTime = totalTime / time.Duration(timeCount)
	}

	fmt.Printf("Statistics:\n")
	fmt.Printf("  Total: %d\n", total)
	fmt.Printf("  Successful: %d (%.1f%%)\n", successful, successRate)
	fmt.Printf("  Failed: %d\n", failed)
	fmt.Printf("  Average Execution Time: %v\n", avgTime)
}

// Example 8: Find slow commands
func ExampleFindSlowCommands() {
	entries, err := cliutils.GetCommandHistory(0, nil)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	threshold := 5 * time.Second
	fmt.Printf("Commands slower than %v:\n", threshold)

	for _, entry := range entries {
		if entry.ExecutionTime > threshold {
			fmt.Printf("  %s: %v\n", entry.Command, entry.ExecutionTime)
		}
	}
}

// Example 9: Group commands by day
func ExampleGroupByDay() {
	entries, err := cliutils.GetCommandHistory(0, nil)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	byDay := make(map[string]int)
	for _, entry := range entries {
		day := entry.Timestamp.Format("2006-01-02")
		byDay[day]++
	}

	fmt.Println("Commands per day:")
	for day, count := range byDay {
		fmt.Printf("  %s: %d\n", day, count)
	}
}

// Example 10: Custom analysis
func ExampleCustomAnalysis() {
	entries, err := cliutils.GetCommandHistory(0, nil)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	// Count commands by prefix
	prefixCounts := make(map[string]int)
	for _, entry := range entries {
		// Extract command prefix (e.g., "jf rt", "jf config")
		words := splitCommand(entry.Command)
		if len(words) >= 2 {
			prefix := words[0] + " " + words[1]
			prefixCounts[prefix]++
		}
	}

	fmt.Println("Commands by namespace:")
	for prefix, count := range prefixCounts {
		fmt.Printf("  %s: %d\n", prefix, count)
	}
}

// Helper function to split command string
func splitCommand(cmd string) []string {
	// Simple split - in real implementation, handle quoted strings
	var words []string
	current := ""
	for _, char := range cmd {
		if char == ' ' {
			if current != "" {
				words = append(words, current)
				current = ""
			}
		} else {
			current += string(char)
		}
	}
	if current != "" {
		words = append(words, current)
	}
	return words
}

// Main function demonstrating all examples
func main() {
	fmt.Println("JFrog CLI History API Examples")
	fmt.Println("==============================")
	fmt.Println()

	fmt.Println("Example 1: Add command to history")
	ExampleAddCommand()
	fmt.Println()

	fmt.Println("Example 2: Get history")
	ExampleGetHistory()
	fmt.Println()

	fmt.Println("Example 3: Get most used commands")
	ExampleGetMostUsed()
	fmt.Println()

	fmt.Println("Example 4: Filter by success")
	ExampleFilterBySuccess()
	fmt.Println()

	fmt.Println("Example 5: Calculate statistics")
	ExampleCalculateStats()
	fmt.Println()

	fmt.Println("Example 6: Find slow commands")
	ExampleFindSlowCommands()
	fmt.Println()

	fmt.Println("Example 7: Group by day")
	ExampleGroupByDay()
	fmt.Println()

	fmt.Println("Example 8: Custom analysis")
	ExampleCustomAnalysis()
	fmt.Println()
}
