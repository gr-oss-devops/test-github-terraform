package github

type BranchProtectionV4 struct {
	Pattern                       string                      `yaml:"pattern"`
	AllowsDeletions               *bool                       `yaml:"allows_deletions,omitempty"`
	AllowsForcePushes             *bool                       `yaml:"allows_force_pushes,omitempty"`
	AllowsCreations               *bool                       `yaml:"allows_creations,omitempty"`
	BlocksCreations               *bool                       `yaml:"blocks_creations,omitempty"`
	EnforceAdmins                 *bool                       `yaml:"enforce_admins,omitempty"`
	PushRestrictions              []*int64                    `yaml:"push_restrictions,omitempty"`
	RequireConversationResolution *bool                       `yaml:"require_conversation_resolution,omitempty"`
	RequireSignedCommits          *bool                       `yaml:"require_signed_commits,omitempty"`
	RequiredLinearHistory         *bool                       `yaml:"required_linear_history,omitempty"`
	RequiredPullRequestReviews    *RequiredPullRequestReviews `yaml:"required_pull_request_reviews,omitempty"`
	RequiredStatusChecks          *RequiredStatusChecksV4     `yaml:"required_status_checks,omitempty"`
}

type RequiredPullRequestReviews struct {
	RequiredApprovingReviewCount *int     `yaml:"required_approving_review_count,omitempty"`
	DismissStaleReviews          *bool    `yaml:"dismiss_stale_reviews,omitempty"`
	RequireCodeOwnerReviews      *bool    `yaml:"require_code_owner_reviews,omitempty"`
	DismissalRestrictions        []*int64 `yaml:"dismissal_restrictions,omitempty"`
	RestrictDismissals           *bool    `yaml:"restrict_dismissals,omitempty"`
	PullRequestBypassers         []*int64 `yaml:"pull_request_bypassers,omitempty"`
}

type RequiredStatusChecksV4 struct {
	Strict   *bool     `yaml:"strict,omitempty"`
	Contexts []*string `yaml:"contexts,omitempty"`
}
