package github

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net/http"
)

// ReleasesResponse contains all releases fetched from GitHub.
type ReleasesResponse []Release

// Release describes a single release on GitHub.
type Release struct {
	TagName string  `json:"tag_name"`
	Assets  []Asset `json:"assets"`
}

// Asset describes a single asset.
type Asset struct {
	Name string `json:"name"`
}

// Client describes the functions needed for this tool to work.
type Client interface {
	// GetReleases fetches all releases from GitHub.
	GetReleases() (ReleasesResponse, error)
}

// New creates a new Client with the specified token. If no token is specified, the client will attempt to proceed
// without one.
func New(token string) (Client, error) {
	transport := http.DefaultTransport.(*http.Transport)
	// Based on the Mozilla "modern" compatibility, see
	// https://wiki.mozilla.org/Security/Server_Side_TLS
	transport.TLSClientConfig = &tls.Config{
		CipherSuites: []uint16{
			tls.TLS_AES_128_GCM_SHA256,
			tls.TLS_AES_256_GCM_SHA384,
			tls.TLS_CHACHA20_POLY1305_SHA256,
		},
		MinVersion: tls.VersionTLS13,
		CurvePreferences: []tls.CurveID{
			tls.X25519, tls.CurveP256, tls.CurveP384,
		},
	}

	return &client{
		token: token,
		client: &http.Client{
			Transport: http.DefaultTransport,
		},
	}, nil
}

type client struct {
	token  string
	client *http.Client
}

func (c client) GetReleases() (ReleasesResponse, error) {
	req, err := http.NewRequest(
		"GET",
		"https://api.github.com/repos/opentofu/opentofu/releases",
		nil,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}
	if c.token != "" {
		req.Header.Set("Authorization", "token "+c.token)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to query the GitHub API: %w", err)
	}
	defer resp.Body.Close()

	var responseData ReleasesResponse

	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		return nil, fmt.Errorf("failed to decode GitHub releases response: %w", err)
	}

	return responseData, nil
}
