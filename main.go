package main

import (
	"os"

	"github.com/naumoffp/EC2Trade/core/tui"
)

var (
	version   string
	buildDate string
)

func main() {
	// TODO: Implement semver
	tui.UNUSED(version, buildDate)

	code := tui.MAIN_WINDOW()
	os.Exit(int(code))
}
