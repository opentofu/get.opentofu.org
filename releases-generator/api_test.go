package releases_generator_test

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/google/go-cmp/cmp"

	releases_generator "github.com/opentofu/get.opentofu.org/releases-generator"
	"github.com/opentofu/get.opentofu.org/releases-generator/github"
)

func TestGenerator_Generate(t *testing.T) {
	releases := github.ReleasesResponse{
		{
			TagName: "v1.0.0",
			Assets: []github.Asset{
				{
					Name: "tofu_v1.0.0.tar.gz",
				},
			},
		},
	}

	gh, err := github.NewFake(releases)
	if err != nil {
		t.Fatal(err)
	}

	generator, err := releases_generator.New(gh)
	if err != nil {
		t.Fatal(err)
	}

	result, err := generator.Generate()
	if err != nil {
		t.Fatal(err)
	}

	t.Run("api", func(t *testing.T) {
		api, ok := result["api.json"]
		if !ok {
			t.Fatal("api.json not found.")
		}
		var apiData map[string]interface{}
		if err := json.Unmarshal(api, &apiData); err != nil {
			t.Fatal(err)
		}

		versions, ok := apiData["versions"]
		if !ok {
			t.Fatal("Versions key not found.")
		}

		if l := len(versions.([]interface{})); l != 1 {
			t.Fatalf("Incorrect number of versions found: %d", l)
		}
		version := versions.([]interface{})[0].(map[string]interface{})
		if version["id"] != "1.0.0" {
			t.Fatalf("Incorrect version id: %s", version["id"])
		}
		if l := len(version["files"].([]interface{})); l != 1 {
			t.Fatalf("Incorrect number of files: %d", l)
		}
		if fn := version["files"].([]interface{})[0]; fn != "tofu_v1.0.0.tar.gz" {
			t.Fatalf("Incorrect file name: %s", fn)
		}
	})

	t.Run("index", func(t *testing.T) {
		index, ok := result["index.html"]
		if !ok {
			t.Fatal("index.html not found")
		}

		if !strings.Contains(string(index), `<a href="/tofu/1.0.0/">tofu_1.0.0</a>`) {
			t.Fatal("Expected version link not found.")
		}
	})

	t.Run("version", func(t *testing.T) {
		version, ok := result["1.0.0/index.html"]
		if !ok {
			t.Fatal("1.0.0/index.html not found")
		}

		if !strings.Contains(
			string(version),
			`<a href="https://github.com/opentofu/opentofu/releases/download/v1.0.0/tofu_v1.0.0.tar.gz">tofu_v1.0.0.tar.gz</a>`,
		) {
			t.Fatal("Expected file link not found.")
		}
	})
}

func TestGenerator_Generate_seriesJSON(t *testing.T) {
	releases := github.ReleasesResponse{
		{
			TagName:     "v1.13.0-alpha1", // ignored because we don't consider alpha-only series as really existing yet
			PublishedAt: mustParseRFC3339("2099-03-01T00:00:00Z"),
		},
		{
			TagName:     "v1.12.0-beta1",
			PublishedAt: mustParseRFC3339("2099-02-01T00:00:00Z"),
		},
		{
			TagName:     "v1.12.0-beta2",
			PublishedAt: mustParseRFC3339("2099-02-02T00:00:00Z"),
		},
		{
			TagName:     "v1.11.0-rc1",
			PublishedAt: mustParseRFC3339("2099-01-01T00:00:00Z"),
		},
		{
			// This is intentionally out of order to make sure our
			// implementation is not depending on the order returned by GitHub,
			// so we are resilient to oddities that might be caused by
			// republishing.
			TagName:     "v1.10.0-rc1",
			PublishedAt: mustParseRFC3339("2025-06-04T13:21:40Z"),
		},
		{
			TagName:     "v1.10.3",
			PublishedAt: mustParseRFC3339("2025-07-05T17:44:31Z"),
			IsDraft:     true, // should be completely ignored
		},
		{
			TagName:     "v1.10.2",
			PublishedAt: mustParseRFC3339("2025-07-01T17:44:31Z"),
		},
		{
			TagName:     "v1.10.1",
			PublishedAt: mustParseRFC3339("2025-06-25T15:48:03Z"),
		},
		{
			TagName:     "v1.10.0",
			PublishedAt: mustParseRFC3339("2025-06-24T13:58:50Z"),
		},
		{
			TagName:     "v1.10.0-beta1",
			PublishedAt: mustParseRFC3339("2025-05-19T15:57:41Z"),
		},
		{
			TagName:     "v1.10.0-alpha1",
			PublishedAt: mustParseRFC3339("2025-03-28T13:42:48Z"),
		},
		{
			// We don't currently have any process that causes prereleases
			// of patch releases but this is here just to make sure this
			// program handles that in a reasonable way: it should essentially
			// ignore this and continue treating v1.9.1 as an active series.
			TagName:     "v1.9.2-beta1",
			PublishedAt: mustParseRFC3339("2025-04-25T00:00:00Z"),
		},
		{
			TagName:     "v1.9.1",
			PublishedAt: mustParseRFC3339("2025-04-24T20:54:41Z"),
		},
		{
			TagName:     "v1.8.9",
			PublishedAt: mustParseRFC3339("2025-04-24T20:53:48Z"),
		},
		{
			TagName:     "v1.7.8",
			PublishedAt: mustParseRFC3339("2025-04-24T20:53:05Z"),
		},
		{
			TagName:     "v1.6.0",
			PublishedAt: mustParseRFC3339("2024-08-07T13:53:04Z"),
		},
		{
			// We should be resilient against release names that don't follow
			// our typical naming scheme. We have no plans to do this
			// intentionally, but we want to keep working if we do it
			// accidentally. This should be completely ignored.
			TagName:     "garbage",
			PublishedAt: mustParseRFC3339("2029-01-01T00:00:00Z"),
		},
	}

	gh, err := github.NewFake(releases)
	if err != nil {
		t.Fatal(err)
	}

	generator, err := releases_generator.New(gh)
	if err != nil {
		t.Fatal(err)
	}

	result, err := generator.Generate()
	if err != nil {
		t.Fatal(err)
	}

	raw, ok := result["series.json"]
	if !ok {
		t.Fatal("series.json not found")
	}
	var got map[string]any
	if err := json.Unmarshal(raw, &got); err != nil {
		t.Fatal(err)
	}

	want := map[string]any{
		"series": []any{
			map[string]any{
				"id":          "1.10",
				"latest":      map[string]any{"id": "1.10.2", "published_at": "2025-07-01T17:44:31Z"},
				"released_at": "2025-06-24T13:58:50Z", // the time of the earliest non-prerelease, 1.10.0
				"status":      "active",
			},
			map[string]any{
				"id":          "1.9",
				"latest":      map[string]any{"id": "1.9.1", "published_at": "2025-04-24T20:54:41Z"},
				"released_at": "2025-04-24T20:54:41Z",
				"status":      "active",
			},
			map[string]any{
				"id":          "1.8",
				"latest":      map[string]any{"id": "1.8.9", "published_at": "2025-04-24T20:53:48Z"},
				"released_at": "2025-04-24T20:53:48Z",
				"status":      "active",
			},
			// Prerelease-only series always appear after active series even
			// though they have higher numbers and may have newer release dates.
			map[string]any{
				"id":          "1.11",
				"latest":      map[string]any{"id": "1.11.0-rc1", "published_at": "2099-01-01T00:00:00Z"},
				"released_at": "2099-01-01T00:00:00Z",
				"status":      "rc",
			},
			map[string]any{
				// (Having both an rc and beta series at the same time would be
				// weird but we support it anyway just in case.)
				"id":          "1.12",
				"latest":      map[string]any{"id": "1.12.0-beta2", "published_at": "2099-02-02T00:00:00Z"},
				"released_at": "2099-02-02T00:00:00Z", // for prerelease series this always matches the latest prerelease time
				"status":      "beta",
			},
			// End-of-life series always appear at the very end.
			map[string]any{
				"id":          "1.7",
				"latest":      map[string]any{"id": "1.7.8", "published_at": "2025-04-24T20:53:05Z"},
				"released_at": "2025-04-24T20:53:05Z",
				"status":      "eol",
			},
			map[string]any{
				"id":          "1.6",
				"latest":      map[string]any{"id": "1.6.0", "published_at": "2024-08-07T13:53:04Z"},
				"released_at": "2024-08-07T13:53:04Z",
				"status":      "eol",
			},
		},
	}

	if diff := cmp.Diff(want, got); diff != "" {
		t.Error("wrong result\n" + diff)
	}
}

func mustParseRFC3339(s string) time.Time {
	ret, err := time.Parse(time.RFC3339, s)
	if err != nil {
		panic(err)
	}
	return ret
}
