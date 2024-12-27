package file

import (
	"os"
	"testing"

	"github.com/gr-oss-devops/github-repo-importer/pkg/github"
	"github.com/stretchr/testify/assert"
)

func TestWriteRepositoryToYAML(t *testing.T) {
	tests := []struct {
		name      string
		repo      *github.Repository
		wantError bool
		cleanup   bool
	}{
		{
			name: "valid repository",
			repo: &github.Repository{
				Name:          "test-repo",
				Owner:         "test-owner",
				Visibility:    "public",
				DefaultBranch: "main",
			},
			wantError: false,
			cleanup:   true,
		},
		{
			name:      "nil repository",
			repo:      nil,
			wantError: true,
			cleanup:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := WriteRepositoryToYAML(tt.repo)

			if tt.wantError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)

				// Verify file exists
				if tt.repo != nil {
					filename := tt.repo.Name + ".yaml"
					_, err := os.Stat(filename)
					assert.NoError(t, err)

					// Cleanup
					if tt.cleanup {
						os.Remove(filename)
					}
				}
			}
		})
	}
}

func TestImportFromFile(t *testing.T) {
	tests := []struct {
		name      string
		fileName  string
		wantError bool
		setup     func() error
		cleanup   func()
	}{
		{
			name:      "non-existent file",
			fileName:  "non-existent.yaml",
			wantError: true,
		},
		{
			name:      "valid file",
			fileName:  "test-repos.yaml",
			wantError: false,
			setup: func() error {
				// Create a temporary test file
				content := []byte("repos:\n  - owner/repo1\n  - owner/repo2")
				return os.WriteFile("test-repos.yaml", content, 0644)
			},
			cleanup: func() {
				os.Remove("test-repos.yaml")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			if tt.setup != nil {
				err := tt.setup()
				assert.NoError(t, err)
			}

			// Test
			err := ImportFromFile(tt.fileName)

			// Assert
			if tt.wantError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			// Cleanup
			if tt.cleanup != nil {
				tt.cleanup()
			}
		})
	}
}
