package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

func main() {
	const githubApiEndpoint = "https://api.github.com/repos/opentofu/opentofu/releases"
	const userAgent = "opentofu releases page"

	mainPageContent := "<ul>\n<li>\n<a href=\"../\">../</a></li>\n"

	// Create a new HTTP request with the desired User-Agent header
	req, err := http.NewRequest("GET", githubApiEndpoint, nil)
	if err != nil {
		fmt.Println("Error creating HTTP request: ", err)
		return
	}
	req.Header.Set("User-Agent", userAgent)

	// Perform the HTTP request
	response, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error fetching releases: ", err)
		return
	}
	defer response.Body.Close()

	// Read the response body
	body, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading response body: ", err)
		return
	}

	// Parse the JSON response
	releases := []map[string]interface{}{}
	if err := json.Unmarshal(body, &releases); err != nil {
		fmt.Println("Error unmarshalling JSON: ", err)
		return
	}

	// Iterate over the releases
	for _, release := range releases {
		versionTrimmed := release["name"].(string)[1:]
		version := release["name"].(string)

		// Create child page directory
		path := versionTrimmed + "/"
		if err := os.Mkdir(path, 0755); err != nil && !os.IsExist(err) {
			fmt.Println("Error creating directory: ", err)
			return
		}

		// Generate child page content
		childPageContent := "<ul>\n<li>\n<a href=\"../\">../</a></li>\n"
		if assets, ok := release["assets"].([]interface{}); ok {
			for _, asset := range assets {
				if assetMap, ok := asset.(map[string]interface{}); ok {
					fileName := assetMap["name"].(string)
					childPageContent += "<li>\n"
					childPageContent += fmt.Sprintf("<a href=\"https://github.com/opentofu/opentofu/releases/download/%s/%s\">%s</a>\n", version, fileName, fileName)
					childPageContent += "</li>\n"
				}
			}
		}
		childPageContent += "</ul>\n"

		// Write child page content to file
		if err := os.WriteFile(path+"/index.html", []byte(childPageContent), 0644); err != nil {
			fmt.Println("Error writing child page: ", err)
			return
		}

		// Update main page content
		mainPageContent += "<li>\n"
		mainPageContent += fmt.Sprintf("<a href=\"./%s\">tofu_%s</a>\n", path, versionTrimmed)
		mainPageContent += "</li>\n"
	}
	mainPageContent += "</ul>\n"

	// Write main page content to file
	if err := os.WriteFile("index.html", []byte(mainPageContent), 0644); err != nil {
		fmt.Println("Error writing main page: ", err)
		return
	}
}
