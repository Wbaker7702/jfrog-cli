package cliutils

import (
	"encoding/json"
	"github.com/jfrog/jfrog-cli-core/v2/utils/coreutils"
	"github.com/jfrog/jfrog-client-go/utils/errorutils"
	"github.com/jfrog/jfrog-client-go/utils/io/fileutils"
	"os"
	"path/filepath"
	"sort"
	gosync "sync"
	"time"
)

const historyFileName = "command-history.json"
const maxHistoryEntries = 1000

// CommandHistoryEntry represents a single command execution
type CommandHistoryEntry struct {
	Command     string    `json:"command"`
	Timestamp   time.Time `json:"timestamp"`
	Success     bool      `json:"success"`
	ExecutionTime time.Duration `json:"execution_time_ms,omitempty"`
}

// CommandHistory stores all command history entries
type CommandHistory struct {
	Entries []CommandHistoryEntry `json:"entries"`
}

var (
	historyFilePath string
	historyLock     gosync.Mutex
)

// getHistoryFilePath returns the path to the history file
func getHistoryFilePath() (string, error) {
	if historyFilePath == "" {
		homeDir, err := coreutils.GetJfrogHomeDir()
		if err != nil {
			return "", errorutils.CheckErrorf("failed to get JFrog home directory: " + err.Error())
		}
		historyFilePath = filepath.Join(homeDir, historyFileName)
	}
	return historyFilePath, nil
}

// loadHistory loads the command history from disk
func loadHistory() (*CommandHistory, error) {
	historyPath, err := getHistoryFilePath()
	if err != nil {
		return nil, err
	}

	history := &CommandHistory{Entries: []CommandHistoryEntry{}}

	if !fileutils.IsPathExists(historyPath, false) {
		return history, nil
	}

	content, err := fileutils.ReadFile(historyPath)
	if err != nil {
		return nil, errorutils.CheckErrorf("failed to read history file: " + err.Error())
	}

	if len(content) == 0 {
		return history, nil
	}

	err = json.Unmarshal(content, history)
	if err != nil {
		return nil, errorutils.CheckErrorf("failed to parse history file: " + err.Error())
	}

	return history, nil
}

// saveHistory saves the command history to disk
func saveHistory(history *CommandHistory) error {
	historyPath, err := getHistoryFilePath()
	if err != nil {
		return err
	}

	// Keep only the most recent entries
	if len(history.Entries) > maxHistoryEntries {
		sort.Slice(history.Entries, func(i, j int) bool {
			return history.Entries[i].Timestamp.After(history.Entries[j].Timestamp)
		})
		history.Entries = history.Entries[:maxHistoryEntries]
	}

	content, err := json.MarshalIndent(history, "", "  ")
	if err != nil {
		return errorutils.CheckErrorf("failed to marshal history: " + err.Error())
	}

	// Ensure directory exists
	dir := filepath.Dir(historyPath)
	if err = os.MkdirAll(dir, 0755); err != nil {
		return errorutils.CheckErrorf("failed to create history directory: " + err.Error())
	}

	err = os.WriteFile(historyPath, content, 0644)
	if err != nil {
		return errorutils.CheckErrorf("failed to write history file: " + err.Error())
	}

	return nil
}

// AddCommandToHistory adds a command execution to the history
func AddCommandToHistory(command string, success bool, executionTime time.Duration) error {
	historyLock.Lock()
	defer historyLock.Unlock()

	history, err := loadHistory()
	if err != nil {
		return err
	}

	entry := CommandHistoryEntry{
		Command:       command,
		Timestamp:     time.Now(),
		Success:       success,
		ExecutionTime: executionTime,
	}

	history.Entries = append(history.Entries, entry)
	return saveHistory(history)
}

// GetCommandHistory retrieves the command history, optionally filtered
func GetCommandHistory(limit int, filterSuccess *bool) ([]CommandHistoryEntry, error) {
	historyLock.Lock()
	defer historyLock.Unlock()

	history, err := loadHistory()
	if err != nil {
		return nil, err
	}

	entries := history.Entries

	// Filter by success status if specified
	if filterSuccess != nil {
		filtered := []CommandHistoryEntry{}
		for _, entry := range entries {
			if entry.Success == *filterSuccess {
				filtered = append(filtered, entry)
			}
		}
		entries = filtered
	}

	// Sort by timestamp (most recent first)
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Timestamp.After(entries[j].Timestamp)
	})

	// Apply limit
	if limit > 0 && limit < len(entries) {
		entries = entries[:limit]
	}

	return entries, nil
}

// GetMostUsedCommands returns the most frequently used commands
func GetMostUsedCommands(limit int) (map[string]int, error) {
	historyLock.Lock()
	defer historyLock.Unlock()

	history, err := loadHistory()
	if err != nil {
		return nil, err
	}

	commandCount := make(map[string]int)
	for _, entry := range history.Entries {
		commandCount[entry.Command]++
	}

	// Sort by frequency
	type cmdFreq struct {
		command string
		count   int
	}
	freqList := []cmdFreq{}
	for cmd, count := range commandCount {
		freqList = append(freqList, cmdFreq{command: cmd, count: count})
	}
	sort.Slice(freqList, func(i, j int) bool {
		return freqList[i].count > freqList[j].count
	})

	result := make(map[string]int)
	count := 0
	for _, item := range freqList {
		if limit > 0 && count >= limit {
			break
		}
		result[item.command] = item.count
		count++
	}

	return result, nil
}

// ClearHistory removes all history entries
func ClearHistory() error {
	historyLock.Lock()
	defer historyLock.Unlock()

	historyPath, err := getHistoryFilePath()
	if err != nil {
		return err
	}

	if fileutils.IsPathExists(historyPath, false) {
		err = os.Remove(historyPath)
		if err != nil {
			return errorutils.CheckErrorf("failed to remove history file: " + err.Error())
		}
	}

	return nil
}
