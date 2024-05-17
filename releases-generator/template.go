package releases_generator

import (
	"bytes"
	"fmt"
	"html/template"
)

func renderTemplate(templateData []byte, data any) ([]byte, error) {
	tpl := template.New("")
	tpl, err := tpl.Parse(string(templateData))
	if err != nil {
		return nil, fmt.Errorf("failed to parse template: %w", err)
	}
	var result bytes.Buffer
	if err := tpl.Execute(&result, data); err != nil {
		return nil, fmt.Errorf("failed to execute template: %w", err)
	}
	return result.Bytes(), nil
}
