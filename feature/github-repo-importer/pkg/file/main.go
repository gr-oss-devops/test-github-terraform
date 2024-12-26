package file

import (
	"fmt"
	"github.com/gr-oss-devops/github-repo-importer/pkg/github"
	"gopkg.in/yaml.v3"
	"os"
)

// WriteRepositoryToYAML writes the Repository struct to a YAML file.
func WriteRepositoryToYAML(repo *github.Repository) error {
	if repo == nil {
		return fmt.Errorf("repository is nil")
	}

	// Use the repository name as the filename
	filename := fmt.Sprintf("%s.yaml", repo.Name)

	// Convert struct to YAML
	data, err := yaml.Marshal(repo)
	if err != nil {
		return fmt.Errorf("failed to marshal repository to YAML: %w", err)
	}

	// Write YAML to file
	err = os.WriteFile(filename, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write YAML to file: %w", err)
	}

	return nil
}

// ImportFromFile reads repository names from a file and processes them
func ImportFromFile(fileName string) error {
	if _, err := os.Stat(fileName); os.IsNotExist(err) {
		return fmt.Errorf("file %s does not exist", fileName)
	}

	// Simulate reading file and processing repos
	fmt.Printf("Simulating processing repositories from file: %s\n", fileName)
	return nil
}
