package verifyprice

import (
	"bufio"
	"bytes"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"unicode"
)

// UNUSED allows unused variables to be included in Go programs
func UNUSED(x ...interface{}) {}

func exec_script(bin string, script string) string {
	// Execute the bash script
	cmd, err := exec.Command(bin, script).Output()
	if err != nil {
		fmt.Printf("error %s", err)
	}

	output := string(cmd)
	return output
}

// Chain together all the steps needed to verify the price of spot instances
func CHAINVERIFYPRICE() ([][]string, []string) {
	var getspotprice, g_err = filepath.Abs("core/verifyprice/getspotprice.sh")
	var json2csv, j_err = filepath.Abs("core/verifyprice/json2csv.py")

	// TODO
	UNUSED(g_err, j_err)

	// Download the spot price data using current filters
	var download_json = exec_script("bash", getspotprice)

	// Convert and sort the downloaded JSON data into a CSV file
	var convert_json = exec_script("python3", json2csv)

	// TODO
	UNUSED(download_json, convert_json)

	// Remove redundant "SpotPriceHistory." from each header and newlines
	var csvdata, c_err = filepath.Abs("core/verifyprice/data/spot-price-history.csv")

	// TODO
	UNUSED(c_err)

	to_remove := "SpotPriceHistory."
	infile := csvdata

	// Generate the final table output
	return FMTDATA(infile, to_remove)

}

// Read in a sample CSV file and return a slice of rows and the first row.
func readSample(rs io.ReadSeeker) ([][]string, []byte, error) {
	// Skip first row (line)
	row1, err := bufio.NewReader(rs).ReadSlice('\n')
	if err != nil {
		return nil, nil, err
	}

	_, err = rs.Seek(int64(len(row1)), io.SeekStart)
	if err != nil {
		return nil, nil, err
	}

	// Read remaining rows
	r := csv.NewReader(rs)
	rows, err := r.ReadAll()
	if err != nil {
		return nil, nil, err
	}
	return rows, row1, nil
}

// Adds spaces between capital letters in one word strings
func addSpace(s string) string {
	buf := &bytes.Buffer{}
	for i, rune := range s {
		if unicode.IsUpper(rune) && i > 0 {
			buf.WriteRune(' ')
		}
		buf.WriteRune(rune)
	}
	return buf.String()
}

func FMTDATA(infile string, to_remove string) ([][]string, []string) {
	// Read in CSV file into headers and rows so that it can be used to create a table
	f, err := os.Open(infile)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	rows, row1, err := readSample(f)
	if err != nil {
		panic(err)
	}

	// Remove unwanted characters from the headers
	str_row1 := string(row1)
	fmt_row1 := strings.Replace(str_row1, to_remove, "", -1)
	clr_row1 := strings.Replace(fmt_row1, "\n", "", -1)

	// Split the string into an array of strings delimited by ","
	headers := strings.Split(clr_row1, ",")
	for x, header := range headers {
		headers[x] = addSpace(header)
	}

	// // Create a table with the headers and rows
	// t := ftable.NewWriter()

	// t.SetOutputMirror(os.Stdout)

	// // Set the headers
	// t.AppendHeader(ftable.Row{addSpace(headers[0]), addSpace(headers[1]), addSpace(headers[3]), headers[4]})

	// // Set the rows
	// for _, element := range rows {
	// 	// Cut out unneccessary information from timestamp
	// 	timestamp := element[4][5 : len(element[4])-15]
	// 	t.AppendRow([]interface{}{element[0], element[1], element[3], timestamp})
	// }

	// // Render the table
	// t.SetStyle(ftable.StyleRounded)

	return rows, headers
}
