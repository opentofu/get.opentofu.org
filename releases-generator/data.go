package releases_generator

import (
	"strings"

	"github.com/opentofu/get.opentofu.org/releases-generator/github"
)

// Index holds all data for all versions.
type Index struct {
	Versions []Version `json:"versions"`
}

// Version holds the file list for a single version.
type Version struct {
	ID    string   `json:"id"`
	Files []string `json:"files"`
}

func githubResponseToIndex(response github.ReleasesResponse) *Index {
	if response == nil {
		return &Index{Versions: nil}
	}
	result := &Index{
		Versions: make([]Version, len(response)),
	}
	for i, release := range response {
		result.Versions[i] = Version{
			ID: strings.TrimLeft(release.TagName, "v"),
			Files: func() []string {
				files := make([]string, len(release.Assets))
				for i, asset := range release.Assets {
					files[i] = asset.Name
				}
				return files
			}(),
		}
	}
	return result
}
