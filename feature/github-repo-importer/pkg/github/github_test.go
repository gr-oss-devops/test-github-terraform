package github

import (
	"os/exec"
	"testing"

	"github.com/google/go-github/v67/github"

	"github.com/stretchr/testify/assert"
)

// Mock execCommand
var execCommand = exec.Command

func TestIsValidRepoFormat(t *testing.T) {
	tests := []struct {
		name     string
		repoName string
		want     bool
	}{
		{
			name:     "valid repository format",
			repoName: "owner/repo",
			want:     true,
		},
		{
			name:     "invalid format - no slash",
			repoName: "ownerrepo",
			want:     false,
		},
		{
			name:     "invalid format - multiple slashes",
			repoName: "owner/repo/extra",
			want:     false,
		},
		{
			name:     "invalid format - empty string",
			repoName: "",
			want:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := isValidRepoFormat(tt.repoName)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestResolveVisibility(t *testing.T) {
	tests := []struct {
		name    string
		private bool
		want    string
	}{
		{
			name:    "private repository",
			private: true,
			want:    VisibilityPrivate,
		},
		{
			name:    "public repository",
			private: false,
			want:    VisibilityPublic,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolveVisibility(tt.private)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestConvertBypassActors(t *testing.T) {
	tests := []struct {
		name      string
		input     []*github.BypassActor
		expected  []BypassActor
		shouldLen int
	}{
		{
			name: "converts multiple actors",
			input: []*github.BypassActor{
				{
					ActorID:    github.Int64(1),
					ActorType:  github.String("User"),
					BypassMode: github.String("always"),
				},
				{
					ActorID:    github.Int64(2),
					ActorType:  github.String("Team"),
					BypassMode: github.String("pull_request"),
				},
			},
			shouldLen: 2,
		},
		{
			name: "skips DeployKey actors",
			input: []*github.BypassActor{
				{
					ActorID:    github.Int64(1),
					ActorType:  github.String("DeployKey"),
					BypassMode: github.String("always"),
				},
				{
					ActorID:    github.Int64(2),
					ActorType:  github.String("User"),
					BypassMode: github.String("pull_request"),
				},
			},
			shouldLen: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := convertBypassActors(tt.input)
			assert.Len(t, result, tt.shouldLen)

			for i, actor := range result {
				assert.NotEqual(t, "DeployKey", actor.ActorType)
				if tt.input[i].GetActorType() != "DeployKey" {
					assert.Equal(t, int(tt.input[i].GetActorID()), actor.ActorID)
					assert.Equal(t, tt.input[i].GetActorType(), actor.ActorType)
					assert.Equal(t, tt.input[i].BypassMode, actor.BypassMode)
				}
			}
		})
	}
}

func TestImportRepo(t *testing.T) {
	tests := []struct {
		name      string
		repoName  string
		wantError bool
		errorMsg  string
	}{
		{
			name:      "invalid repo format",
			repoName:  "invalid-format",
			wantError: true,
			errorMsg:  "invalid repository format. Use owner/repo",
		},
		{
			name:      "empty repo name",
			repoName:  "",
			wantError: true,
			errorMsg:  "invalid repository format. Use owner/repo",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			repo, err := ImportRepo(tt.repoName)

			if tt.wantError {
				assert.Error(t, err)
				assert.Nil(t, repo)
				assert.Equal(t, tt.errorMsg, err.Error())
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, repo)
			}
		})
	}
}

func TestResolvePages(t *testing.T) {
	tests := []struct {
		name     string
		input    *github.Pages
		expected *Pages
	}{
		{
			name: "valid pages configuration",
			input: &github.Pages{
				CNAME: github.String("example.com"),
				Source: &github.PagesSource{
					Branch: github.String("gh-pages"),
					Path:   github.String("/docs"),
				},
			},
			expected: &Pages{
				CNAME:  github.String("example.com"),
				Branch: github.String("gh-pages"),
				Path:   github.String("/docs"),
			},
		},
		{
			name:     "nil input",
			input:    nil,
			expected: nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := resolvePages(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

// MockClient implements necessary interfaces for testing
type MockClient struct {
	// Add fields to store expected results
	repositories  map[string]*github.Repository
	collaborators map[string][]*github.User
	teams         map[string][]*github.Team
}

func NewMockClient() *MockClient {
	return &MockClient{
		repositories:  make(map[string]*github.Repository),
		collaborators: make(map[string][]*github.User),
		teams:         make(map[string][]*github.Team),
	}
}

func TestCategorizeCollaborators(t *testing.T) {
	client := github.NewClient(nil)
	tests := []struct {
		name       string
		owner      string
		repo       string
		wantError  bool
		wantResult map[string][]string
	}{
		{
			name:  "valid repository",
			owner: "test-owner",
			repo:  "test-repo",
			wantResult: map[string][]string{
				PermissionAdmin:    {"admin-user"},
				PermissionPush:     {"push-user"},
				PermissionPull:     {"pull-user"},
				PermissionTriage:   {"triage-user"},
				PermissionMaintain: {"maintain-user"},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := CategorizeCollaborators(client, tt.owner, tt.repo)

			if tt.wantError {
				assert.Error(t, err)
				assert.Nil(t, result)
			} else {
				assert.NoError(t, err)
				// Add more specific assertions based on expected results
			}
		})
	}
}
