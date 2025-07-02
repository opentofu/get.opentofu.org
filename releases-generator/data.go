package releases_generator

import (
	"cmp"
	"slices"
	"strings"
	"time"

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
		Versions: make([]Version, 0, len(response)),
	}
	for _, release := range response {
		if release.IsDraft {
			// We request the releases without an authenticated token so we
			// should not actually get any drafts, but we'll check anyway to
			// make sure this doesn't get broken under future maintenence.
			continue
		}
		result.Versions = append(result.Versions, Version{
			ID: strings.TrimLeft(release.TagName, "v"),
			Files: func() []string {
				files := make([]string, len(release.Assets))
				for i, asset := range release.Assets {
					files[i] = asset.Name
				}
				return files
			}(),
		})
	}
	return result
}

type SeriesIndex struct {
	Series []Series `json:"series"`
}

// Series describes a minor release series, such as "1.10", as an overview
// derived from the individual releases in that series.
type Series struct {
	// ID is a string representation of the whole-series version prefix, like "1.10".
	ID string `json:"id"`

	// LatestVersion is a string representation of the latest available version
	// in this series.
	//
	// For a series whose status is [StatusActive] this is guaranteed not to
	// be a prerelease, even if there is a prerelease of higher precedence
	// than the latest non-prerelease.
	LatestVersion VersionMeta `json:"latest"`

	// Status summarizes the current overall status of this series.
	//
	// [SeriesActive] represents a series that is still "supported" in the
	// sense of our release support policy.
	Status SeriesStatus `json:"status"`

	// ReleasedAt is the publication time of the first non-prerelease version in
	// the series, or the latest prerelease version if there are not yet any
	// non-prerelease versions.
	ReleasedAt time.Time `json:"released_at,omitempty"`
}

type VersionMeta struct {
	ID          string    `json:"id"`
	PublishedAt time.Time `json:"published_at"`
}

func githubResponseToSeriesSummary(response github.ReleasesResponse) *SeriesIndex {
	ret := &SeriesIndex{Series: nil}
	if len(response) == 0 {
		return ret
	}

	bySeries := make(map[string][]*github.Release)
	for i := range response {
		release := &response[i] // reference rather than copy
		if release.IsDraft {
			continue
		}
		seriesID := seriesIDForReleaseTagName(release.TagName)
		if seriesID == "" {
			// Tag does not match the shape we expect for a normal release,
			// so we'll ignore it for series-summarization purposes.
			continue
		}
		bySeries[seriesID] = append(bySeries[seriesID], release)
	}

	ret.Series = make([]Series, 0, len(bySeries))
	for seriesID, releases := range bySeries {
		ret.Series = append(ret.Series, Series{
			ID: seriesID,
		})
		series := &ret.Series[len(ret.Series)-1]

		// To make the rest of this a little easier we'll sort the releases
		// in each series so that the oldest appears first. As long as we
		// keep numbering our releases in a sensible way this should mean
		// that prereleases will appear before their respective release
		// and lower-numbered releases appear before higher-numbered ones.
		slices.SortFunc(releases, func(a, b *github.Release) int {
			return a.PublishedAt.Compare(b.PublishedAt)
		})

		for _, release := range releases {
			releaseStatus := seriesStatusForReleaseTagName(release.TagName)
			if releaseStatus == SeriesInvalid {
				continue
			}
			if series.Status == SeriesInvalid {
				// The first release we find in each series initializes
				// series object, so we can update it as needed on subsequent
				// iterations of this loop.
				series.Status = releaseStatus
				series.ReleasedAt = release.PublishedAt
				series.LatestVersion = VersionMeta{
					ID:          strings.TrimLeft(release.TagName, "v"),
					PublishedAt: release.PublishedAt,
				}
				continue
			}
			oldStatus := series.Status
			if series.Status < releaseStatus {
				series.Status = releaseStatus
			}
			switch series.Status {
			case SeriesActive:
				// For an active series, the earliest active release decides
				// the "released at" time.
				if oldStatus != SeriesActive || release.PublishedAt.Compare(series.ReleasedAt) < 0 {
					series.ReleasedAt = release.PublishedAt
				}
			default:
				// For non-active (i.e. prerelease) series, the most recent
				// prerelease decides the "released at" time. If we get here
				// with series.Status != SeriesActive then we definitely
				// haven't seen an active release yet.
				if release.PublishedAt.Compare(series.ReleasedAt) > 0 {
					series.ReleasedAt = release.PublishedAt
				}
			}
			if releaseStatus == series.Status && series.LatestVersion.PublishedAt.Compare(release.PublishedAt) < 0 {
				series.LatestVersion = VersionMeta{
					ID:          strings.TrimLeft(release.TagName, "v"),
					PublishedAt: release.PublishedAt,
				}
			}
		}
	}
	ret.Series = slices.DeleteFunc(ret.Series, func(s Series) bool {
		return s.Status == SeriesInvalid
	})
	slices.SortFunc(ret.Series, func(a, b Series) int {
		// On our first pass we order by release date, newest first, so that
		// we can easily find the most recent three releases below.
		if a.Status != b.Status {
			return cmp.Compare(b.Status, a.Status)
		}
		// Within each status, the newest "ReleasedAt" time appears first.
		return b.ReleasedAt.Compare(a.ReleasedAt)
	})
	// TODO: One day the list of series will become large and at that point
	// we might choose to limit the number of "eol"-status items we return,
	// but for now we'll just keep all of them.

	// Only the three most recent "active" releases are actually active, per
	// our release support policy. We'll mark all of the earlier ones as
	// being end-of-life.
	// We have considered guaranteeing a minimum amount of time for a release
	// to be supported despite the three-series limit and if we adopt that
	// in future we'll need to incorporate that into the following, but for
	// now we're assuming that we start new series infrequently enough that
	// a minimium time guarantee is not needed.
	foundActive := 0
	for i := range ret.Series {
		series := &ret.Series[i] // reference rather than copy
		if series.Status == SeriesActive {
			foundActive++
			if foundActive > 3 {
				series.Status = SeriesEndOfLife
			}
		}
	}
	// With the statuses now finalized, we'll group the releases by
	// status so that the active ones always appear first. This uses
	// a stable sort to preserve the publication date ordering we
	// applied above within each status group.
	slices.SortStableFunc(ret.Series, func(a, b Series) int {
		return cmp.Compare(b.Status, a.Status)
	})

	return ret
}

func seriesIDForReleaseTagName(tagName string) string {
	// We expect a tag name like "v1.10.0", possibly followed by a prerelease
	// suffix like "-beta1". Other forms produce unspecified results.
	v := strings.TrimLeft(tagName, "v")
	if len(v) == len(tagName) {
		// There was no "v" prefix, so invalid
		return ""
	}
	if strings.Count(v, ".") != 2 {
		// Wrong number of dots, so invalid.
		return ""
	}
	// Everything up to the last dot is the series identifier: "1.10.0-beta1"
	// belongs to "1.10".
	return v[:strings.LastIndexByte(v, '.')]
}

func seriesStatusForReleaseTagName(tagName string) SeriesStatus {
	_, pre, _ := strings.Cut(tagName, "-")
	if pre == "" {
		return SeriesActive
	}
	if strings.HasPrefix(pre, "rc") {
		return SeriesRC
	}
	if strings.HasPrefix(pre, "beta") {
		return SeriesBeta
	}
	// No other suffixes are recognized
	// Note that we intentionally disregard "alpha" because those happen via
	// a separate process before the release branch has been established:
	// a series that _only_ has alpha releases doesn't really exist yet.
	return SeriesInvalid
}

// SeriesStatus represents the overall status of a [Series], based on whether
// there are any
type SeriesStatus int

// The following constants are ordered so that we can take the highest value
// that applies across all individual releases in a series by numeric comparison.
const (
	SeriesInvalid SeriesStatus = iota
	SeriesEndOfLife
	SeriesBeta
	SeriesRC
	SeriesActive
)

func (s SeriesStatus) MarshalJSON() ([]byte, error) {
	switch s {
	case SeriesActive:
		return []byte(`"active"`), nil
	case SeriesBeta:
		return []byte(`"beta"`), nil
	case SeriesRC:
		return []byte(`"rc"`), nil
	case SeriesEndOfLife:
		return []byte(`"eol"`), nil
	case SeriesInvalid:
		// Should not actually try to return series with this status
		return []byte(`null`), nil
	default:
		// The cases above should be exhaustive for all [SeriesStatus] constants.
		panic("unsupported SeriesStatus value")
	}
}
