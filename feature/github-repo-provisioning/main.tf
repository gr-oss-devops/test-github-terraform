provider "github" {}

locals {
#  repo_configs = fileset(path.module, "repo_configs/*.{yml,yaml}")
  generated_repo_configs = fileset(path.module, "repo_configs/generated/*.{yml,yaml}")
  new_repo_configs = fileset(path.module, "repo_configs/new/*.{yml,yaml}")
}

data "local_file" "generated_repo_file" {
  for_each = toset(local.generated_repo_configs)
  filename = each.value
}

data "local_file" "new_repo_file" {
  for_each = toset(local.new_repo_configs)
  filename = each.value
}

locals {
  generated_repos = {
    for file_path, file_data in data.local_file.generated_repo_file :
    split(".", basename(file_path))[0] => yamldecode(file_data.content)
  }
  new_repos = {
    for file_path, file_data in data.local_file.new_repo_file :
    split(".", basename(file_path))[0] => yamldecode(file_data.content)
  }
  all_repos = merge(local.generated_repos, local.new_repos)
}

import {
  for_each = local.generated_repos
  to = module.repository[each.key].github_repository.repository
  id = each.key
}

module "repository" {
  source                  = "mineiros-io/repository/github"
  version                 = "~> 0.18.0"
  for_each                = local.all_repos

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Main resource configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  name                    = each.key
  allow_merge_commit      = try(each.value.allow_merge_commit,      true)
  allow_rebase_merge      = try(each.value.allow_rebase_merge,      false)
  allow_squash_merge      = try(each.value.allow_squash_merge,      false)
  allow_auto_merge        = try(each.value.allow_auto_merge,        false)
  description             = try(each.value.description,             "")
  delete_branch_on_merge  = try(each.value.delete_branch_on_merge,  true)
  homepage_url            = try(each.value.homepage_url,            "")
  visibility              = try(each.value.visibility,              "private")
  has_issues              = try(each.value.has_issues,              false)
  has_projects            = try(each.value.has_projects,            false)
  has_wiki                = try(each.value.has_wiki,                false)
  has_downloads           = try(each.value.has_downloads,           false)
  is_template             = try(each.value.is_template,             false)
  default_branch          = try(each.value.default_branch,          "")
  archived                = try(each.value.archived,                false)
  topics                  = try(each.value.topics,                  [])
  archive_on_destroy      = false
#  pages                   = try({
#                              branch = try(each.value.pages.branch, "gh-pages")
#                              path   = try(each.value.pages.path,   "/")
#                              cname  = try(each.value.pages.cname,  null)
#                            })

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Extended Resource Configuration
  # Repository Creation Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  auto_init           = try(each.value.auto_init,                           true)
  gitignore_template  = try(each.value.gitignore_template,                  "")
  license_template    = try(each.value.license_template,                    "")
#  template            = try({
#                          owner       = try(each.value.template.owner,      "")
#                          repository  = try(each.value.template.repository, "")
#                        })

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Teams Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  pull_teams              = try(each.value.pull_teams,      [])
  push_teams              = try(each.value.push_teams,      [])
  admin_teams             = try(each.value.admin_teams,     [])
  maintain_teams          = try(each.value.maintain_teams,  [])
  triage_teams            = try(each.value.triage_teams,    [])

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Collaborator Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  pull_collaborators      = try(each.value.pull_collaborators,      [])
  push_collaborators      = try(each.value.push_collaborators,      [])
  admin_collaborators     = try(each.value.admin_collaborators,     [])
  maintain_collaborators  = try(each.value.maintain_collaborators,  [])
  triage_collaborators    = try(each.value.triage_collaborators,    [])

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Branches Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Deploy Keys Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Branch Protections v3 Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  branch_protections_v3: (Optional list(branch_protection_v3)) Default is [].
#    branch: (Required string)
#    enforce_admins: (Optional bool) Default is false.
#    require_conversation_resolution: (Optional bool) Default is false.
#    require_signed_commits: (Optional bool) Default is false.
#    required_status_checks: (Optional object(required_status_checks)) Default is {}.
#      strict: (Optional bool) Default is false.
#      contexts: (Optional list(string)) Default is [].
#    required_pull_request_reviews: (Optional object(required_pull_request_reviews)) Default is {}.
#      dismiss_stale_reviews: (Optional bool) Default is true.
#      dismissal_users: (Optional list(string)) Default is [].
#      dismissal_teams: (Optional list(string)) Default is [].
#      require_code_owner_reviews: (Optional bool) Default is false.
#    restrictions: (Optional object(restrictions)) Default is {}.
#      users: (Optional list(string)) Default is [].
#      teams: (Optional list(string)) Default is [].
#      apps: (Optional list(string)) Default is [].

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Branch Protections v4 Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  branch_protections_v4 = try([
#    for branch_protection in try(each.value.branch_protections_v4, []) : {
#      pattern                         = branch_protection.pattern
#      allows_deletions                = try(branch_protection.allows_deletions, false)
#      allows_force_pushes             = try(branch_protection.allows_force_pushes, false)
#      blocks_creations                = try(branch_protection.blocks_creations, false)
#      enforce_admins                  = try(branch_protection.enforce_admins, true) TODO: not clear
#      push_restrictions               = try(branch_protection.push_restrictions, []) TODO: not clear
#      require_conversation_resolution = try(branch_protection.require_conversation_resolution, false)
#      require_signed_commits          = try(branch_protection.require_signed_commits, false)
#      required_linear_history         = try(branch_protection.required_linear_history, false)
#
#      required_pull_request_reviews = try({
#        dismiss_stale_reviews          = try(branch_protection.required_pull_request_reviews.dismiss_stale_reviews, true)
#        restrict_dismissals            = try(branch_protection.required_pull_request_reviews.restrict_dismissals, false) TODO: not clear
#        dismissal_restrictions         = try(branch_protection.required_pull_request_reviews.dismissal_restrictions, []) TODO: not clear
#        pull_request_bypassers         = try(branch_protection.required_pull_request_reviews.pull_request_bypassers, []) TODO: not clear
#        require_code_owner_reviews     = try(branch_protection.required_pull_request_reviews.require_code_owner_reviews, true)
#        required_approving_review_count = try(branch_protection.required_pull_request_reviews.required_approving_review_count, 0)
#      }, {})
#
#      required_status_checks = try({
#        strict   = try(branch_protection.required_status_checks.strict, false)
#        contexts = try(branch_protection.required_status_checks.contexts, [])
#      }, {})
#    }
#  ], [])

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Issue Labels Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  issue_labels_create = false

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Projects Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Webhooks Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Secrets Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Autolink References Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # App Installations
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#  app_installations = try(each.value.app_installations, [])
}

#resource "github_repository_ruleset" "ruleset" {
#  name        = try(var.ruleset_name, "Example Ruleset")
#  enforcement = try(var.enforcement, "active")
#  target      = try(var.target, "branch")
#  repository  = try(var.repository, "example-repo")
#
#  conditions {
#    ref_name {
#      include = try(var.ref_include, ["~DEFAULT_BRANCH", "releases/*"])
#      exclude = try(var.ref_exclude, ["releases/old/*"])
#    }
#  }
#
#  rules {
#    creation = try(var.rules_creation, true)
#    update   = try(var.rules_update, true)
#    deletion = try(var.rules_deletion, false)
#
#    required_linear_history = try(var.required_linear_history, true)
#    required_signatures    = try(var.required_signatures, true)
#    non_fast_forward      = try(var.non_fast_forward, true)
#
#    update_allows_fetch_and_merge = try(var.update_allows_fetch_and_merge, true)
#
#    branch_name_pattern {
#      name     = try(var.branch_pattern_name, "Branch naming convention")
#      operator = try(var.branch_pattern_operator, "regex")
#      pattern  = try(var.branch_pattern, "^(feature|bugfix|release)/")
#      negate   = try(var.branch_pattern_negate, false)
#    }
#
#    commit_author_email_pattern {
#      name     = try(var.author_email_name, "Require company email")
#      operator = try(var.author_email_operator, "ends_with")
#      pattern  = try(var.author_email_pattern, "@company.com")
#      negate   = try(var.author_email_negate, false)
#    }
#
#    commit_message_pattern {
#      name     = try(var.commit_msg_name, "Conventional commits")
#      operator = try(var.commit_msg_operator, "regex")
#      pattern  = try(var.commit_msg_pattern, "^(feat|fix|docs|style|refactor|test|chore):")
#      negate   = try(var.commit_msg_negate, false)
#    }
#
#    pull_request {
#      dismiss_stale_reviews_on_push     = try(var.dismiss_stale_reviews, true)
#      require_code_owner_review         = try(var.require_code_owner_review, true)
#      require_last_push_approval        = try(var.require_last_push_approval, true)
#      required_approving_review_count   = try(var.required_reviews, 2)
#      required_review_thread_resolution = try(var.required_thread_resolution, true)
#    }
#
#    required_status_checks {
#      strict_required_status_checks_policy = try(var.strict_status_checks, true)
#
#      required_check {
#        context       = try(var.status_check_context, "ci/test-suite")
#        integration_id = try(var.status_check_integration_id, 1234)
#      }
#    }
#
#    required_deployments {
#      required_deployment_environments = try(var.required_environments, ["staging", "production"])
#    }
#
#    required_code_scanning {
#      required_code_scanning_tool {
#        tool                    = try(var.code_scanning_tool, "codeql")
#        alerts_threshold        = try(var.alerts_threshold, "high_or_higher")
#        security_alerts_threshold = try(var.security_alerts_threshold, "high_or_higher")
#      }
#    }
#  }
#
#  bypass_actors {
#    actor_id    = try(var.bypass_actor_id, 5)
#    actor_type  = try(var.bypass_actor_type, "RepositoryRole")
#    bypass_mode = try(var.bypass_mode, "always")
#  }
#}