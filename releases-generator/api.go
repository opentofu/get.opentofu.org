package releases_generator

import (
	_ "embed"
	"encoding/json"
	"fmt"

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

	for _, version := range index.Versions {
		result[version.ID+"/index.html"], err = renderTemplate(releaseTemplate, version)
		if err != nil {
			return nil, fmt.Errorf("failed to render release template for version %s: %w", version.ID, err)
		}
	}
	return result, nil
}
