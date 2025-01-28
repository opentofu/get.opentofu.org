package releases_generator

import (
	"strings"

	"github.com/opentofu/get.opentofu.org/releases-generator/github"
)

// Index holds all data for all versions.
type Index struct {
	Versions       []Version          `json:"versions"`
	LatestVersions map[string]Version `json:"latest_versions"`
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
		Versions:       make([]Version, len(response)),
		LatestVersions: make(map[string]Version),
	}
	for i, release := range response {
		ver := strings.TrimLeft(release.TagName, "v")
		verStruct := Version{
			ID: ver,
			Files: func() []string {
				files := make([]string, len(release.Assets))
				for i, asset := range release.Assets {
					files[i] = asset.Name
				}
				return files
			}(),
		}
		result.Versions[i] = verStruct
		parts := strings.Split(ver, "-")
		if len(parts) != 1 {
			// Don't generate the latest entry for pre-release versions
			continue
		}
		parts = strings.Split(ver, ".")
		if len(parts) != 3 {
			// This is a weird version, ignore it.
			continue
		}
		for _, latest := range []string{
			"latest",
			parts[0],
			parts[0] + "." + parts[1],
		} {
			if _, ok := result.LatestVersions[latest]; !ok {
				result.LatestVersions[latest] = verStruct
			}
		}
	}
	return result
}
