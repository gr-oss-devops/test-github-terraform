package github

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"strings"

	"github.com/google/go-github/v67/github"
	"golang.org/x/oauth2"
)

func getToken() (string, error) {
	cmd := exec.Command("gh", "auth", "token")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get token: %w", err)
	}
	token := strings.TrimSpace(string(output))
	if token == "" {
		return "", errors.New("retrieved token is empty")
	}
	return token, nil
}

func createGitHubClient() (*github.Client, error) {
	token, err := getToken()
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve token: %w", err)
	}

	ctx := context.Background()
	ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: token})
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)
	return client, nil
}

// ImportRepo fetches details of the given repository.
func ImportRepo(repoName string) (*Repository, error) {
	if !isValidRepoFormat(repoName) {
		return nil, errors.New("invalid repository format. Use owner/repo")
	}

	client, err := createGitHubClient()
	if err != nil {
		return nil, err
	}

	repoNameSplit := strings.Split(repoName, "/")
	repo, r, err := client.Repositories.Get(context.Background(), repoNameSplit[0], repoNameSplit[1])
	if err != nil {
		return nil, fmt.Errorf("failed to fetch repo: %w (API Response: %s)", err, r.Status)
	}

	categorizedCollaborators, err := CategorizeCollaborators(client, repoNameSplit[0], repoNameSplit[1])
	if err != nil {
		return nil, fmt.Errorf("failed to categorize collaborators: %w", err)
	}

	categorizedTeams, err := CategorizeTeams(client, repoNameSplit[0], repoNameSplit[1])
	if err != nil {
		return nil, fmt.Errorf("failed to categorize collaborators: %w", err)
	}

	pages, r, err := client.Repositories.GetPagesInfo(context.Background(), repoNameSplit[0], repoNameSplit[1])
	if 404 != r.StatusCode && err != nil {
		return nil, fmt.Errorf("failed to fetch repo: %w (API Response: %s)", err, r.Status)
	} else if 404 != r.StatusCode {
		fmt.Printf("No pages found for this repo: %s\n", repoName)
	}

	rulesets, r, err := client.Repositories.GetAllRulesets(context.Background(), repoNameSplit[0], repoNameSplit[1], false)
	if 404 != r.StatusCode && err != nil {
		return nil, fmt.Errorf("failed to fetch rulesets: %w", err)
	} else if 404 != r.StatusCode {
		fmt.Printf("No rulesets found for this repo: %s\n", repoName)
	}

	var collectedRulesets []github.Ruleset
	for _, ruleset := range rulesets {
		rulesetById, _, _ := client.Repositories.GetRuleset(context.Background(), repoNameSplit[0], repoNameSplit[1], ruleset.GetID(), false)
		jsonData, _ := json.Marshal(rulesetById)
		collectedRulesets = append(collectedRulesets, *rulesetById)
		fmt.Println(string(jsonData))
	}

	vulnerabilityAlertsEnabled, r, err := client.Repositories.GetVulnerabilityAlerts(context.Background(), repoNameSplit[0], repoNameSplit[1])
	if err != nil {
		return nil, fmt.Errorf("failed to fetch vulnerability alerts: %w", err)
	}

	return &Repository{
		Name:                       repo.GetName(),
		Owner:                      repo.GetOwner().GetLogin(),
		Description:                repo.Description,
		Visibility:                 resolveVisibility(repo.GetPrivate()),
		HomepageURL:                repo.Homepage,
		DefaultBranch:              repo.GetDefaultBranch(),
		HasIssues:                  repo.HasIssues,
		HasProjects:                repo.HasProjects,
		HasWiki:                    repo.HasWiki,
		HasDownloads:               repo.HasDownloads,
		AllowMergeCommit:           repo.AllowMergeCommit,
		AllowRebaseMerge:           repo.AllowRebaseMerge,
		AllowSquashMerge:           repo.AllowSquashMerge,
		AllowAutoMerge:             repo.AllowAutoMerge,
		DeleteBranchOnMerge:        repo.DeleteBranchOnMerge,
		IsTemplate:                 repo.IsTemplate,
		Archived:                   repo.Archived,
		Topics:                     repo.Topics,
		PullCollaborators:          categorizedCollaborators[PermissionPull],
		TriageCollaborators:        categorizedCollaborators[PermissionTriage],
		PushCollaborators:          categorizedCollaborators[PermissionPush],
		MaintainCollaborators:      categorizedCollaborators[PermissionMaintain],
		AdminCollaborators:         categorizedCollaborators[PermissionAdmin],
		PullTeams:                  categorizedTeams[PermissionPull],
		TriageTeams:                categorizedTeams[PermissionTriage],
		PushTeams:                  categorizedTeams[PermissionPush],
		MaintainTeams:              categorizedTeams[PermissionMaintain],
		AdminTeams:                 categorizedTeams[PermissionAdmin],
		LicenseTemplate:            repo.LicenseTemplate,
		GitignoreTemplate:          repo.GitignoreTemplate,
		Template:                   resolveRepositoryTemplate(repo),
		Pages:                      resolvePages(pages),
		Rulesets:                   resolveRulesets(collectedRulesets),
		VulnerabilityAlertsEnabled: &vulnerabilityAlertsEnabled,
	}, nil
}

func resolveRulesets(githubRulesets []github.Ruleset) []Ruleset {
	var rulesets []Ruleset

	for _, githubRuleset := range githubRulesets {
		rulesets = append(rulesets, Ruleset{
			ID:           githubRuleset.GetID(),
			Enforcement:  githubRuleset.Enforcement,
			Name:         githubRuleset.Name,
			Target:       githubRuleset.GetTarget(),
			Repository:   githubRuleset.Source,
			BypassActors: convertBypassActors(githubRuleset.BypassActors),
			Conditions:   convertConditions(githubRuleset.Conditions),
			Rules:        convertRules(githubRuleset.Rules),
		})
	}

	return rulesets
}

func convertRules(ghRules []*github.RepositoryRule) *Rule {
	if len(ghRules) == 0 {
		return nil
	}

	var rules = Rule{}
	for _, r := range ghRules {
		switch r.Type {
		case RuleTypeRequiredLinearHistory:
			trueVal := true
			rules.RequiredLinearHistory = &trueVal

		case RuleTypePullRequest:
			rules.PullRequest = convertPullRequestRule(r.Parameters)

		case RuleTypeRequiredStatusChecks:
			rules.RequiredStatusChecks = convertRequiredStatusChecks(r.Parameters)

		case RuleTypeDeletion:
			trueVal := true
			rules.Deletion = &trueVal

		case RuleTypeCreation:
			trueVal := true
			rules.Creation = &trueVal

		case RuleTypeNonFastForward:
			trueVal := true
			rules.NonFastForward = &trueVal

		case RuleRequiredSignatures:
			trueVal := true
			rules.RequiredSignatures = &trueVal

		case RuleUpdate:
			trueVal := true
			rules.Update = &trueVal

		case RuleRequiredDeployments:
			rules.RequiredDeployments = convertRequiredDeployments(r.Parameters)

		case RuleCommitMessagePattern:
			rules.CommitMessagePattern = convertPatternRule(r.Parameters)

		case RuleCommitAuthorEmailPattern:
			rules.CommitAuthorEmailPattern = convertPatternRule(r.Parameters)

		case RuleCommitterEmailPattern:
			rules.CommitterEmailPattern = convertPatternRule(r.Parameters)

		case RuleBranchNamePattern:
			rules.BranchNamePattern = convertPatternRule(r.Parameters)

		case RuleTagNamePattern:
			rules.TagNamePattern = convertPatternRule(r.Parameters)

		case RuleCodeScanning:
			rules.RequiredCodeScanning = convertRequiredCodeScanning(r.Parameters)

		default:
			// Handle unknown rule types
			fmt.Printf("Unknown rule type: %s\n", r.Type)
		}

	}
	return &rules
}

func convertPatternRule(pattern *json.RawMessage) *PatternRule {
	if pattern == nil {
		return nil
	}
	var rule PatternRule
	err := json.Unmarshal(*pattern, &rule)
	if err != nil {
		fmt.Printf("Failed to unmarshal pattern rule: %v\n", err)
	}
	return &rule
}

func convertPullRequestRule(pr *json.RawMessage) *PullRequestRule {
	if pr == nil {
		return nil
	}
	var rule PullRequestRule
	err := json.Unmarshal(*pr, &rule)
	if err != nil {
		fmt.Printf("Failed to unmarshal pull request rule: %v\n", err)
	}
	return &rule
}

func convertRequiredDeployments(rd *json.RawMessage) *RequiredDeployments {
	if rd == nil {
		return nil
	}
	var rule RequiredDeployments

	err := json.Unmarshal(*rd, &rule)
	if err != nil {
		fmt.Printf("Failed to unmarshal required deployments: %v\n", err)
	}
	return &rule
}

func convertRequiredStatusChecks(rsc *json.RawMessage) *RequiredStatusChecks {
	if rsc == nil {
		return nil
	}

	var rule RequiredStatusChecks

	err := json.Unmarshal(*rsc, &rule)
	if err != nil {
		fmt.Printf("Failed to unmarshal required status checks: %v\n", err)
	}
	return &rule
}

func convertRequiredCodeScanning(rcs *json.RawMessage) *RequiredCodeScanning {
	if rcs == nil {
		return nil
	}

	var rule RequiredCodeScanning

	err := json.Unmarshal(*rcs, &rule)
	if err != nil {
		fmt.Printf("Failed to unmarshal required code scanning: %v\n", err)
	}
	return &rule
}

func convertConditions(ghConditions *github.RulesetConditions) *Conditions {
	if ghConditions == nil || ghConditions.RefName == nil {
		return nil
	}

	return &Conditions{
		RefName: RefNameCondition{
			Exclude: ghConditions.RefName.Exclude,
			Include: ghConditions.RefName.Include,
		},
	}
}

func convertBypassActors(ghActors []*github.BypassActor) []BypassActor {
	//result := make([]BypassActor, len(ghActors))
	var result []BypassActor
	for _, actor := range ghActors {
		if actor.GetActorType() != "DeployKey" {
			result = append(result, BypassActor{
				ActorID:    int(actor.GetActorID()),
				ActorType:  actor.GetActorType(),
				BypassMode: actor.BypassMode,
			})
		}
	}
	return result
}

func resolvePages(pages *github.Pages) *Pages {
	if pages != nil {
		return &Pages{
			CNAME:  pages.CNAME,
			Branch: pages.GetSource().Branch,
			Path:   pages.GetSource().Path,
		}
	}
	return nil
}

func resolveRepositoryTemplate(githubRepository *github.Repository) *RepositoryTemplate {
	if githubRepository.GetTemplateRepository() != nil {
		return &RepositoryTemplate{
			Owner:      githubRepository.GetTemplateRepository().GetOwner().GetLogin(),
			Repository: githubRepository.GetTemplateRepository().GetName(),
		}
	}
	return nil
}

func resolveVisibility(private bool) string {
	if private {
		return VisibilityPrivate
	}
	return VisibilityPublic
}

func isValidRepoFormat(repoName string) bool {
	return strings.Count(repoName, "/") == 1
}

func CategorizeCollaborators(client *github.Client, owner, repo string) (map[string][]string, error) {
	pullCollaborators := []string{}
	triageCollaborators := []string{}
	pushCollaborators := []string{}
	maintainCollaborators := []string{}
	adminCollaborators := []string{}

	// List collaborators from the repository
	opts := &github.ListCollaboratorsOptions{
		ListOptions: github.ListOptions{PerPage: 100},
	}

	for {
		collaborators, resp, err := client.Repositories.ListCollaborators(context.Background(), owner, repo, opts)
		if 404 != resp.StatusCode && err != nil {
			return nil, fmt.Errorf("failed to fetch collaborators: %w", err)
		} else if 404 != resp.StatusCode {
			fmt.Printf("No collaborators found for this repo: %s\n", repo)
			return nil, nil
		}

		// Iterate over collaborators
		for _, collaborator := range collaborators {
			permissions := collaborator.GetPermissions()

			if permissions[PermissionPull] {
				pullCollaborators = append(pullCollaborators, collaborator.GetLogin())
			}
			if permissions[PermissionTriage] {
				triageCollaborators = append(triageCollaborators, collaborator.GetLogin())
			}
			if permissions[PermissionPush] {
				pushCollaborators = append(pushCollaborators, collaborator.GetLogin())
			}
			if permissions[PermissionMaintain] {
				maintainCollaborators = append(maintainCollaborators, collaborator.GetLogin())
			}
			if permissions[PermissionAdmin] {
				adminCollaborators = append(adminCollaborators, collaborator.GetLogin())
			}
		}

		// Break out of the loop if there are no more pages
		if resp.NextPage == 0 {
			break
		}

		// Set the next page
		opts.Page = resp.NextPage
	}

	// Return the categorized collaborators as a map
	return map[string][]string{
		PermissionPull:     pullCollaborators,
		PermissionTriage:   triageCollaborators,
		PermissionPush:     pushCollaborators,
		PermissionMaintain: maintainCollaborators,
		PermissionAdmin:    adminCollaborators,
	}, nil
}

func CategorizeTeams(client *github.Client, owner, repo string) (map[string][]int64, error) {
	pullTeams := []int64{}
	triageTeams := []int64{}
	pushTeams := []int64{}
	maintainTeams := []int64{}
	adminTeams := []int64{}

	opts := &github.ListOptions{PerPage: 100}

	for {
		teams, resp, err := client.Repositories.ListTeams(context.Background(), owner, repo, opts)
		if 404 != resp.StatusCode && err != nil {
			return nil, fmt.Errorf("failed to fetch teams: %w", err)
		} else if 404 != resp.StatusCode {
			fmt.Printf("No teams found for this repo: %s\n", repo)
			return nil, nil
		}

		// Iterate over collaborators
		for _, team := range teams {
			permissions := team.GetPermissions()

			if permissions[PermissionPull] {
				pullTeams = append(pullTeams, team.GetID())
			}
			if permissions[PermissionTriage] {
				triageTeams = append(triageTeams, team.GetID())
			}
			if permissions[PermissionPush] {
				pushTeams = append(pushTeams, team.GetID())
			}
			if permissions[PermissionMaintain] {
				maintainTeams = append(maintainTeams, team.GetID())
			}
			if permissions[PermissionAdmin] {
				adminTeams = append(adminTeams, team.GetID())
			}
		}

		// Break out of the loop if there are no more pages
		if resp.NextPage == 0 {
			break
		}

		// Set the next page
		opts.Page = resp.NextPage
	}

	// Return the categorized collaborators as a map
	return map[string][]int64{
		PermissionPull:     pullTeams,
		PermissionTriage:   triageTeams,
		PermissionPush:     pushTeams,
		PermissionMaintain: maintainTeams,
		PermissionAdmin:    adminTeams,
	}, nil
}
