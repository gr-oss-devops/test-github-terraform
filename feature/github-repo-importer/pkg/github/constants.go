package github

const (
	// Rule types
	RuleTypeRequiredLinearHistory = "required_linear_history"
	RuleTypePullRequest           = "pull_request"
	RuleTypeRequiredStatusChecks  = "required_status_checks"
	RuleTypeDeletion              = "deletion"
	RuleTypeCreation              = "creation"
	RuleTypeNonFastForward        = "non_fast_forward"
	RuleRequiredSignatures        = "required_signatures"
	RuleUpdate                    = "update"
	RuleRequiredDeployments       = "required_deployments"
	RuleCommitMessagePattern      = "commit_message_pattern"
	RuleCommitAuthorEmailPattern  = "commit_author_email_pattern"
	RuleCommitterEmailPattern     = "committer_email_pattern"
	RuleBranchNamePattern         = "branch_name_pattern"
	RuleTagNamePattern            = "tag_name_pattern"
	RuleCodeScanning              = "code_scanning"

	// Visibility
	VisibilityPrivate = "private"
	VisibilityPublic  = "public"

	// Permission levels
	PermissionPull     = "pull"
	PermissionPush     = "push"
	PermissionTriage   = "triage"
	PermissionMaintain = "maintain"
	PermissionAdmin    = "admin"
)
