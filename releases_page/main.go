package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"net/http"
	"os"
)

// Templates for main page and release page
const (
	mainPageTemplate = `<ul>
	<li>
		<a href="../">../</a>
	</li>
	{{ range . }}
	<li>{{ $releaseName := .name | trimV }}
		<a href="./{{ $releaseName }}/">{{ printf "tofu_%s" $releaseName }}</a>
	</li>
	{{ end }}
	</ul>`
	releasePageTemplate = `<ul>
	<li>
		<a href="../">../</a>
	</li>
	{{ range . }}
	<li>
		<a href="{{ .browser_download_url }}">{{ .name }}</a>
	</li>
	{{end}}
	</ul>`
)

func main() {
	const (
		githubAPIEndpoint = "https://api.github.com/repos/opentofu/opentofu/releases"
		htmlFileName      = "index.html"
	)

	// Create client with custom user-agent
	client := &http.Client{}
	req, err := http.NewRequest("GET", githubAPIEndpoint, nil)
	if err != nil {
		fmt.Println("Error creating request: ", err)
		return
	}
	req.Header.Set("User-Agent", "opentofu releases page")

	// Fetch releases from GitHub API
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error fetching releases: ", err)
		return
	}
	defer response.Body.Close()

	body, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading response body: ", err)
		return
	}

	// Unmarshal JSON response
	releases := []map[string]interface{}{}
	if err := json.Unmarshal(body, &releases); err != nil {
		fmt.Println("Error unmarshalling JSON: ", err)
		return
	}

	// Create main index.html file
	htmlFile, err := os.Create(htmlFileName)
	if err != nil {
		fmt.Println("Error creating HTML file: ", err)
		return
	}
	defer htmlFile.Close()

	// Function to remove the first character of a string
	funcMap := template.FuncMap{
		"trimV": func(s string) string {
			if len(s) <= 1 {
				return ""
			}
			return s[1:]
		},
	}

	// Parse mainPage template
	mainPageTmpl, err := template.New("mainPageTemplate").Funcs(funcMap).Parse(mainPageTemplate)
	if err != nil {
		fmt.Println("Error parsing mainPage template: ", err)
		return
	}

	// Execute the mainPage template and write to the main index.html
	if err := mainPageTmpl.Execute(htmlFile, releases); err != nil {
		fmt.Println("Error executing mainPage template: ", err)
		return
	}

	// Parse releasePage template
	releasePageTmpl, err := template.New("releasePageTemplate").Parse(releasePageTemplate)
	if err != nil {
		fmt.Println("Error parsing releasePage template: ", err)
		return
	}

	// Iterate over releases to create release pages
	for _, release := range releases {
		// Extract version from release name
		version := release["name"].(string)[1:]
		path := version + "/"

		// Create directory for each release
		if err := os.Mkdir(path, 0755); err != nil && !os.IsExist(err) {
			fmt.Println(fmt.Sprintf("Error creating %s directory: ",version), err)
			return
		}

		// Create index.html file for release page
		htmlFile, err := os.Create(path + htmlFileName)
		if err != nil {
			fmt.Println(fmt.Sprintf("Error creating HTML file, %s%s: ", path, htmlFileName), err)
			return
		}
		defer htmlFile.Close()

		// Execute releasePage template and write to releases' index.html
		if assets, ok := release["assets"].([]interface{}); ok {
			if err := releasePageTmpl.Execute(htmlFile, assets); err != nil {
				fmt.Println(fmt.Sprintf("Error executing releasePage template for %s%s: ", path, htmlFileName), err)
				return
			}
		}
	}
}