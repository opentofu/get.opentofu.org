package releases_generator

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/opentofu/get.opentofu.org/releases-generator/github"
)

//go:embed index.gohtml
var indexTemplate []byte

//go:embed release.gohtml
var releaseTemplate []byte

// New creates a new Generator using a provider GitHub client.
func New(
	githubClient github.Client,
) (Generator, error) {
	return &generator{
		githubClient,
	}, nil
}

// Generator provides a method to generate all files for the releases page.
type Generator interface {
	Generate() (map[string][]byte, error)
}

type generator struct {
	github github.Client
}

func (g *generator) Generate() (map[string][]byte, error) {
	result := make(map[string][]byte)
	releases, err := g.github.GetReleases()
	if err != nil {
		return nil, fmt.Errorf("failed to fetch GitHub releases: %w", err)
	}
	index := githubResponseToIndex(releases)

	result["api.json"], err = json.Marshal(index)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal releases API file: %w", err)
	}

	result["index.html"], err = renderTemplate(indexTemplate, index)
	if err != nil {
		return nil, fmt.Errorf("failed to render the index.html file: %w", err)
	}

	versionIDList := make([]string, len(index.Versions))
	for i, version := range index.Versions {
		// Shell script friendly output:
		versionIDList[i] = version.ID
		versionFiles := []string{
			version.ID,
		}
		if len(strings.Split(version.ID, "-")) == 1 {
			// Only do this for non-prereleases
			parts := strings.Split(version.ID, ".")
			versionFiles = append(
				versionFiles,
				"latest",
				parts[0],
				parts[0]+"."+parts[1],
			)
		}
		for _, ver := range versionFiles {
			if _, ok := result["api/"+ver+".version.txt"]; ok {
				continue
			}
			versionIDJSON, err := json.Marshal(version.ID)
			if err != nil {
				return nil, fmt.Errorf("failed to marshal version ID API file for %s: %w", version.ID, err)
			}
			versionFilesJSON, err := json.Marshal(version.Files)
			if err != nil {
				return nil, fmt.Errorf("failed to marshal version files API file for %s: %w", version.ID, err)
			}

			result["api/"+ver+".version.txt"] = []byte(version.ID)
			result["api/"+ver+".version.json"] = versionIDJSON
			result["api/"+ver+".files.txt"] = []byte(strings.Join(version.Files, "\n"))
			result["api/"+ver+".files.json"] = versionFilesJSON
		}

		result[version.ID+"/index.html"], err = renderTemplate(releaseTemplate, version)
		if err != nil {
			return nil, fmt.Errorf("failed to render release template for version %s: %w", version.ID, err)
		}
	}
	result["api.txt"] = []byte(strings.Join(versionIDList, "\n"))
	return result, nil
}
