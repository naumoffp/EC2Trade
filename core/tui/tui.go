package tui

import (
	"fmt"

	"github.com/gdamore/tcell/v2"
	"github.com/naumoffp/EC2Trade/core/verifyprice"
	"github.com/rivo/tview"
)

// UNUSED allows unused variables to be included in Go programs
func UNUSED(x ...interface{}) {}

type exitCode int

const (
	exitOK     exitCode = 0
	exitError  exitCode = 1
	exitCancel exitCode = 2
)

var app = tview.NewApplication()

var output_window = tview.NewTextView().
	SetDynamicColors(true).
	SetRegions(true).
	SetWordWrap(true).
	SetTextColor(tcell.ColorDarkGrey).
	SetTextAlign(tview.AlignCenter).
	SetChangedFunc(func() {
		app.Draw()
	})

func grab_prices() *tview.Table {
	table := tview.NewTable().
		SetBorders(true)

	rows, cols := verifyprice.CHAINVERIFYPRICE()

	// Set the headers
	for c := 0; c < len(cols); c++ {
		color := tcell.ColorGreen

		table.SetCell(0, c,
			tview.NewTableCell(cols[c]).
				SetTextColor(color).
				SetAlign(tview.AlignCenter))
	}

	// Set the rows
	for x := 0; x < len(rows); x++ {
		for r := 0; r < len(rows); r++ {
			for c := 0; c < len(rows[x]); c++ {
				color := tcell.ColorWhite

				table.SetCell(r+1, c,
					tview.NewTableCell(rows[r][c]).
						SetTextColor(color).
						SetAlign(tview.AlignCenter))
			}
		}
	}

	return table
}

func main_menu() *tview.Form {
	form := tview.NewForm().
		AddDropDown("Instance Type", []string{"T.2 Micro", "T3.Micro", "Quantum Computer"}, 0, nil).
		AddDropDown("vCPU Count", []string{"8", "16", "32", "64"}, 0, nil).
		AddDropDown("Memory GiB", []string{"16", "32", "64", "128"}, 0, nil).
		AddCheckbox("Persistent Storage?", true, nil).
		AddCheckbox("Save Profile?", false, nil).
		AddButton("Save", func() {
			fmt.Fprintf(output_window, "%s ", "Other subroutine")
		}).
		AddButton("Quit", func() {
			app.Stop()
		})
	form.SetBorder(true).SetTitle("Main Menu").SetTitleAlign(tview.AlignCenter).SetBorderAttributes(tcell.AttrDim)
	return form

}

func MAIN_WINDOW() exitCode {
	newText := func(text string) tview.Primitive {
		return tview.NewTextView().
			SetTextAlign(tview.AlignCenter).
			SetText(text)
	}

	graph_window := grab_prices()
	main := main_menu()

	helpBar := tview.NewTextView().
		SetDynamicColors(true).
		SetRegions(true).
		SetWordWrap(true).
		SetTextColor(tcell.ColorDarkGrey).
		SetTextAlign(tview.AlignCenter).
		SetChangedFunc(func() {
			app.Draw()
		})

	fmt.Fprintf(helpBar, "%s ", "Tab Navigate Forward · Shift-Tab Navigate Back · Ctrl+C To Exit")

	grid := tview.NewGrid().
		SetRows(3, 0, 1).
		SetColumns(48, 0, 40).
		SetBorders(true).
		AddItem(newText("Welcome To EC2 Trade"), 0, 0, 1, 3, 0, 0, false)

	// Layout for screens narrower than 100 cells (menu and side bar are hidden).
	grid.AddItem(graph_window, 0, 0, 0, 0, 0, 0, false).
		AddItem(helpBar, 0, 0, 0, 0, 0, 0, false).
		AddItem(main, 1, 0, 2, 1, 0, 0, true).
		AddItem(output_window, 1, 1, 2, 2, 0, 0, false)

	// Layout for screens wider than 100 cells.
	grid.AddItem(graph_window, 0, 0, 0, 0, 0, 100, false).
		AddItem(helpBar, 2, 0, 1, 3, 0, 100, false).
		AddItem(main, 1, 0, 1, 2, 0, 100, true).
		AddItem(output_window, 1, 2, 1, 1, 0, 100, false)

	// Layout for screens wider than 130 cells.
	grid.AddItem(graph_window, 1, 0, 1, 1, 0, 130, false).
		AddItem(helpBar, 2, 0, 1, 3, 0, 130, false).
		AddItem(main, 1, 1, 1, 1, 0, 130, true).
		AddItem(output_window, 1, 2, 1, 1, 0, 130, false)

	if err := app.SetRoot(grid, true).EnableMouse(true).Run(); err != nil {
		panic(err)
	}

	return exitOK
}
