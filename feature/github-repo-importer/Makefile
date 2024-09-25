# Makefile for Terraform to YAML conversion using yq

# Default target
.PHONY: all
all: extract

# Extract Terraform state to YAML
.PHONY: extract
extract:
	@echo "Extracting Terraform state to YAML..."
	@terraform show -json | \
	jq -c '.values.root_module.child_modules[].resources[] | select(.type == "github_repository")' | \
	while read -r resource; do \
		name=$$(echo $$resource | jq -r '.values.name'); \
		echo $$resource | \
		jq '{description: .values.description, visibility: .values.visibility, topics: .values.topics, has_issues: .values.has_issues, has_projects: .values.has_projects, has_wiki: .values.has_wiki, has_downloads: .values.has_downloads}' | \
		yq eval -P > "$$name.yaml"; \
		echo "Created $$name.yaml"; \
	done

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  extract  - Extract Terraform state to YAML files"
	@echo "  help     - Show this help message"