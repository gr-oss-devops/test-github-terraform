package main

import (
	"fmt"
	"gopkg.in/yaml.v3"
	"log"
	"os"

	"github.com/gr-oss-devops/github-repo-importer/pkg/file"
	"github.com/gr-oss-devops/github-repo-importer/pkg/github"
	"github.com/spf13/cobra"
)

func main() {
	// Define variables for flags
	var importRepo string
	var extractRepo string
	var configFile string

	file.CreateDumpsDirectory()

	// Root command
	var rootCmd = &cobra.Command{
		Use:   "importer",
		Short: "A CLI tool to fetch GitHub repository details and branch protection rules",
		RunE: func(cmd *cobra.Command, args []string) error {
			// Handle flags separately to decouple the logic
			if importRepo != "" {
				fmt.Printf("Importing repository: %s\n", importRepo)
				file.CreateRepositoryDirectory(importRepo)
				if repo, err := github.ImportRepo(importRepo); err != nil {
					return fmt.Errorf("failed to import repo: %w", err)
				} else {
					HandleRepository(repo)
				}
			} else if extractRepo != "" {
				fmt.Printf("Extracting repository: %s\n", extractRepo)
				//if err := file.WriteRepoToYAML(extractRepo); err != nil {
				//	return fmt.Errorf("failed to extract repo: %w", err)
				//}
			} else if configFile != "" {
				fmt.Printf("Importing repositories from file: %s\n", configFile)
				if err := file.ImportFromFile(configFile); err != nil {
					return fmt.Errorf("failed to import repos from file: %w", err)
				}
			} else {
				return fmt.Errorf("you must provide one of --import, --extract, or --file flags")
			}
			return nil
		},
	}

	// Bind flags to local variables (not reused in logic)
	rootCmd.Flags().StringVar(&importRepo, "import", "", "The repository to import (e.g., owner/repo)")
	rootCmd.Flags().StringVar(&extractRepo, "extract", "", "The repository to extract to YAML (e.g., owner/repo)")
	rootCmd.Flags().StringVar(&configFile, "file", "", "A configuration file containing repositories")

	// Execute root command
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func HandleRepository(repository *github.Repository) {
	data, err := yaml.Marshal(repository)
	if err != nil {
		fmt.Printf("Failed to marshal repository to YAML: %w", err)
	}

	err = file.WriteRepositoryToYAML(data, repository.Name)
	if err != nil {
		log.Fatalf("Failed to write repository to YAML: %v", err)
	}
}
