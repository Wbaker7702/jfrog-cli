package history

import (
	"fmt"
	corecommon "github.com/jfrog/jfrog-cli-core/v2/docs/common"
	"github.com/jfrog/jfrog-cli/docs/common"
	historyDocs "github.com/jfrog/jfrog-cli/docs/general/history"
	"github.com/jfrog/jfrog-cli/utils/cliutils"
	"github.com/jfrog/jfrog-client-go/utils/log"
	"github.com/urfave/cli"
	"strings"
	"time"
)

func HistoryCmd(c *cli.Context) error {
	if show, err := cliutils.ShowCmdHelpIfNeeded(c, c.Args()); show || err != nil {
		return err
	}

	// Handle clear command
	if c.Bool("clear") {
		return clearHistory()
	}

	// Handle stats command
	if c.Bool("stats") {
		return showStats(c.Int("limit"))
	}

	// Default: show history
	return showHistory(c.Int("limit"), c.Bool("failed"), c.Bool("success"))
}

func showHistory(limit int, failedOnly, successOnly bool) error {
	var filterSuccess *bool
	if failedOnly {
		f := false
		filterSuccess = &f
	} else if successOnly {
		f := true
		filterSuccess = &f
	}

	if limit <= 0 {
		limit = 50 // Default limit
	}

	entries, err := cliutils.GetCommandHistory(limit, filterSuccess)
	if err != nil {
		return err
	}

	if len(entries) == 0 {
		log.Output("No command history found.")
		return nil
	}

	log.Output(fmt.Sprintf("Command History (showing %d of %d entries):\n", len(entries), len(entries)))
	log.Output(strings.Repeat("=", 80))

	for i, entry := range entries {
		status := "✓"
		if !entry.Success {
			status = "✗"
		}

		timestamp := entry.Timestamp.Format("2006-01-02 15:04:05")
		duration := ""
		if entry.ExecutionTime > 0 {
			duration = fmt.Sprintf(" (%v)", entry.ExecutionTime.Round(time.Millisecond))
		}

		log.Output(fmt.Sprintf("%3d. [%s] %s %s%s", i+1, timestamp, status, entry.Command, duration))
	}

	return nil
}

func showStats(limit int) error {
	if limit <= 0 {
		limit = 10
	}

	mostUsed, err := cliutils.GetMostUsedCommands(limit)
	if err != nil {
		return err
	}

	if len(mostUsed) == 0 {
		log.Output("No command statistics available.")
		return nil
	}

	log.Output("Most Used Commands:\n")
	log.Output(strings.Repeat("=", 80))

	count := 1
	for cmd, freq := range mostUsed {
		log.Output(fmt.Sprintf("%2d. %-50s %d times", count, cmd, freq))
		count++
	}

	return nil
}

func clearHistory() error {
	err := cliutils.ClearHistory()
	if err != nil {
		return err
	}
	log.Output("Command history cleared.")
	return nil
}
