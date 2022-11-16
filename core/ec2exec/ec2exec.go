package ec2exec

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
)

// UNUSED allows unused variables to be included in Go programs
func UNUSED(x ...interface{}) {}

func EC2EXEC() {
	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.3.4")),
	}

	execPath, err := installer.Install(context.Background())
	if err != nil {
		log.Fatalf("error installing Terraform: %s", err)
	}

	workingDir, pathErr := filepath.Abs("")
	UNUSED(pathErr)

	tf, err := tfexec.NewTerraform(workingDir, execPath)
	if err != nil {
		log.Fatalf("error running NewTerraform: %s", err)
	}

	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("error running Init: %s", err)
	}

	state, err := tf.Show(context.Background())
	if err != nil {
		log.Fatalf("error running Show: %s", err)
	}

	//tf.Show(context.Background(), tfexec.State(state))

	otherstate, err := tf.ShowStateFile(context.Background(), "terraform.tfstate")
	UNUSED(otherstate, err)

	bs, _ := json.MarshalIndent(state.Values.Outputs, "", "  ")

	fmt.Println(string(bs))

	os.Exit(1)
	// fmt.Println(state.TerraformVersion)
	// fmt.Println(state.FormatVersion)
	// fmt.Println(state.Values)
	// fmt.Println(state.Values.Outputs)
	// fmt.Println(state.Values.RootModule)

}
