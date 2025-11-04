package history

const (
	Usage = "jf history [command options]"
)

func GetDescription() string {
	return "View and manage command execution history"
}

func GetArguments() string {
	return `  --limit     [Default: 50]
		Maximum number of history entries to display

  --failed
		Show only failed commands

  --success
		Show only successful commands

  --stats
		Show statistics about most used commands

  --clear
		Clear all command history`
}

var EnvVar []string
