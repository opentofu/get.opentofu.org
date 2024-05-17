package releases_generator_test

import (
	"encoding/json"
	"strings"
	"testing"

	releases_generator "github.com/opentofu/get.opentofu.org/releases-generator"
	"github.com/opentofu/get.opentofu.org/releases-generator/github"
)

func TestGenerator_Generate(t *testing.T) {
	releases := github.ReleasesResponse{
		{
			TagName: "v1.0.0",
			Assets: []github.Asset{
				{
					Name: "tofu_v1.0.0.tar.gz",
				},
			},
		},
	}

	gh, err := github.NewFake(releases)
	if err != nil {
		t.Fatal(err)
	}

	generator, err := releases_generator.New(gh)
	if err != nil {
		t.Fatal(err)
	}

	result, err := generator.Generate()
	if err != nil {
		t.Fatal(err)
	}

	t.Run("api", func(t *testing.T) {
		api, ok := result["api.json"]
		if !ok {
			t.Fatal("api.json not found.")
		}
		var apiData map[string]interface{}
		if err := json.Unmarshal(api, &apiData); err != nil {
			t.Fatal(err)
		}

		versions, ok := apiData["versions"]
		if !ok {
			t.Fatal("Versions key not found.")
		}

		if l := len(versions.([]interface{})); l != 1 {
			t.Fatalf("Incorrect number of versions found: %d", l)
		}
		version := versions.([]interface{})[0].(map[string]interface{})
		if version["id"] != "1.0.0" {
			t.Fatalf("Incorrect version id: %s", version["id"])
		}
		if l := len(version["files"].([]interface{})); l != 1 {
			t.Fatalf("Incorrect number of files: %d", l)
		}
		if fn := version["files"].([]interface{})[0]; fn != "tofu_v1.0.0.tar.gz" {
			t.Fatalf("Incorrect file name: %s", fn)
		}
	})

	t.Run("index", func(t *testing.T) {
		index, ok := result["index.html"]
		if !ok {
			t.Fatal("index.html not found")
		}

		if !strings.Contains(string(index), `<a href="/tofu/1.0.0/">tofu_1.0.0</a>`) {
			t.Fatal("Expected version link not found.")
		}
	})

	t.Run("version", func(t *testing.T) {
		version, ok := result["1.0.0/index.html"]
		if !ok {
			t.Fatal("1.0.0/index.html not found")
		}

		if !strings.Contains(
			string(version),
			`<a href="https://github.com/opentofu/opentofu/releases/download/v1.0.0/tofu_v1.0.0.tar.gz">tofu_v1.0.0.tar.gz</a>`,
		) {
			t.Fatal("Expected file link not found.")
		}
	})
}
