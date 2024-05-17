package github

import (
	"fmt"
)

func NewFake(releases ReleasesResponse) (Client, error) {
	return &fakeGitHub{
		releases,
	}, nil
}

type fakeGitHub struct {
	releases ReleasesResponse
}

func (f fakeGitHub) GetReleases() (ReleasesResponse, error) {
	if f.releases == nil {
		return nil, fmt.Errorf("no releases provided, returning error for simulation")
	}
	return f.releases, nil
}
