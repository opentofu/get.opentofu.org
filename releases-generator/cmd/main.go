package main

import (
	"fmt"
	"log"
	"os"
	"path"

	releasesGenerator "github.com/opentofu/get.opentofu.org/releases-generator"
	"github.com/opentofu/get.opentofu.org/releases-generator/github"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Printf("Usage: %s target-dir/\n", os.Args[0])
		os.Exit(1)
	}

	targetDir := os.Args[1]

	if err := os.MkdirAll(targetDir, 0755); err != nil {
		log.Fatalf("Could not create target directory: %v", err)
	}

	gh, err := github.New(os.Getenv("GITHUB_TOKEN"))
	if err != nil {
		log.Fatal(err)
	}
	generator, err := releasesGenerator.New(gh)
	if err != nil {
		log.Fatal(err)
	}

	files, err := generator.Generate()
	if err != nil {
		log.Fatal(err)
	}

	for file, contents := range files {
		targetFile := path.Join(targetDir, file)
		fileDir := path.Dir(targetFile)
		if err := os.MkdirAll(fileDir, 0755); err != nil {
			log.Fatalf("Could not create directory for file %s: %v", targetFile, err)
		}
		if err := os.WriteFile(targetFile, contents, 0644); err != nil {
			log.Fatalf("Could not write file %s: %v", targetFile, err)
		}
	}
}
