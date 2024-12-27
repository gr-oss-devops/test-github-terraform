provider "github" {}

locals {
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
  pages                   = try(contains(keys(each.value), "pages") && try(each.value.pages != null, false) ? {
                              branch = try(each.value.pages.branch, "gh-pages")
                              path   = try(each.value.pages.path,   "/")
                              cname  = try(each.value.pages.cname,  null)
                            } : null)

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Extended Resource Configuration
  # Repository Creation Configuration
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  auto_init           = try(each.value.auto_init,                           true)
  gitignore_template  = try(each.value.gitignore_template,                  "")
  license_template    = try(each.value.license_template,                    "")
  template            = try(contains(keys(each.value), "template") && try(each.value.template != null, false) ? {
                          owner       = try(each.value.template.owner,      "")
                          repository  = try(each.value.template.repository, "")
                        } : null)

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

locals {
  new_rulesets_flattened = flatten([
    for repo, config in local.new_repos : [
      for ruleset in try(config.rulesets, []) : {
        repository  = repo
        ruleset     = ruleset
      }
    ]
  ])

  new_rulesets_map = {
    for idx, item in local.new_rulesets_flattened :
    "${item.repository}-${item.ruleset.id}" => item
  }

  generated_rulesets_flattened = flatten([
    for repo, config in local.generated_repos : [
      for ruleset in try(config.rulesets, []) : {
        repository  = repo
        ruleset     = ruleset
      }
    ]
  ])

  generated_rulesets_map = {
    for idx, item in local.generated_rulesets_flattened :
    "${item.repository}-${item.ruleset.id}" => item
  }

  all_rulesets_map = merge(local.new_rulesets_map, local.generated_rulesets_map)
}

import {
  for_each = local.generated_rulesets_map
  to = github_repository_ruleset.ruleset[each.key]
  id = "${each.value.repository}:${each.value.ruleset.id}"
}

output "rulesets_map" {
  value = local.all_rulesets_map
}

resource "github_repository_ruleset" "ruleset" {
  for_each  = local.all_rulesets_map
  name      = each.value.ruleset.name
  enforcement = each.value.ruleset.enforcement
  target      = each.value.ruleset.target
  repository  = each.value.repository

  dynamic "conditions" {
    for_each = try(each.value.ruleset.conditions, null) != null ? [each.value.ruleset.conditions] : []

    content {
      ref_name {
        include = try(each.value.ruleset.conditions.ref_name.include, [])
        exclude = try(each.value.ruleset.conditions.ref_name.exclude, [])
      }
    }
  }

  rules {
    creation = try(each.value.ruleset.rules.creation, null)
    update   = try(each.value.ruleset.rules.update, null)
    deletion = try(each.value.ruleset.rules.deletion, null)
    required_linear_history = try(each.value.ruleset.rules.required_linear_history, null)
    required_signatures    = try(each.value.ruleset.rules.required_signatures, null)
    non_fast_forward      = try(each.value.ruleset.rules.non_fast_forward, null)

    dynamic "branch_name_pattern" {
      for_each = try(each.value.ruleset.rules.branch_name_pattern, null) != null ? [each.value.ruleset.rules.branch_name_pattern] : []

      content {
        name     = try(each.value.ruleset.rules.branch_name_pattern.name, null)
        operator = each.value.ruleset.rules.branch_name_pattern.operator
        pattern  = each.value.ruleset.rules.branch_name_pattern.pattern
        negate   = try(each.value.ruleset.rules.branch_name_pattern.negate, null)
      }
    }

    dynamic "commit_author_email_pattern" {
      for_each = try(each.value.ruleset.rules.commit_author_email_pattern, null) != null ? [each.value.ruleset.rules.commit_author_email_pattern] : []

      content {
        name     = try(each.value.ruleset.rules.commit_author_email_pattern.name, null)
        operator = each.value.ruleset.rules.commit_author_email_pattern.operator
        pattern  = each.value.ruleset.rules.commit_author_email_pattern.pattern
        negate   = try(each.value.ruleset.rules.commit_author_email_pattern.negate, null)
      }
    }

    dynamic "commit_message_pattern" {
      for_each = try(each.value.ruleset.rules.committer_email_pattern, null) != null ? [each.value.ruleset.rules.committer_email_pattern] : []

      content {
        name     = try(each.value.ruleset.rules.committer_email_pattern.name, null)
        operator = each.value.ruleset.rules.committer_email_pattern.operator
        pattern  = each.value.ruleset.rules.committer_email_pattern.pattern
        negate   = try(each.value.ruleset.rules.committer_email_pattern.negate, null)
      }
    }

    dynamic "pull_request" {
      for_each = try(each.value.ruleset.rules.pull_request, null) != null ? [each.value.ruleset.rules.pull_request] : []

      content {
        dismiss_stale_reviews_on_push     = try(each.value.ruleset.rules.pull_request.dismiss_stale_reviews_on_push, null)
        require_code_owner_review         = try(each.value.ruleset.rules.pull_request.require_code_owner_review, null)
        require_last_push_approval        = try(each.value.ruleset.rules.pull_request.require_last_push_approval, null)
        required_approving_review_count   = try(each.value.ruleset.rules.pull_request.required_approving_review_count, null)
        required_review_thread_resolution = try(each.value.ruleset.rules.pull_request.required_review_thread_resolution, null)
      }
    }

    dynamic "required_status_checks" {
      for_each = (
      contains(keys(each.value.ruleset.rules), "required_status_checks") &&
      try(each.value.ruleset.rules.required_status_checks != null, false) &&
      length(try(each.value.ruleset.rules.required_status_checks.required_check, [])) > 0
      ) ? [each.value.ruleset.rules.required_status_checks] : []

      content {
        strict_required_status_checks_policy = try(required_status_checks.value.strict_required_status_checks_policy, null)

        dynamic "required_check" {
          for_each = try(required_status_checks.value.required_check, [])
          content {
            context       = required_check.value.context
            integration_id = required_check.value.integration_id
          }
        }
      }
    }

    dynamic "required_deployments" {
      for_each = try(
        contains(keys(each.value.ruleset.rules), "required_deployments") &&
        try(each.value.ruleset.rules.required_deployments != null, false) &&
        try(length(keys(each.value.ruleset.rules.required_deployments)) > 0, false)
        ? [each.value.ruleset.rules.required_deployments]
        : []
      )

      content {
        required_deployment_environments = try(required_deployments.value.required_deployment_environments, ["staging", "production"])
      }
    }

    dynamic "required_code_scanning" {
      for_each = try(
        contains(keys(each.value.ruleset.rules), "required_code_scanning") &&
        try(each.value.ruleset.rules.required_code_scanning != null, false) &&
        length(try(each.value.ruleset.rules.required_code_scanning.required_code_scanning_tool, [])) > 0
        ? [each.value.ruleset.rules.required_code_scanning]  # Only one block for `required_code_scanning`
        : []
      )

      content {
        dynamic "required_code_scanning_tool" {
          for_each = try(each.value.ruleset.rules.required_code_scanning.required_code_scanning_tool, [])

          content {
            tool                    = required_code_scanning_tool.value.tool
            alerts_threshold        = required_code_scanning_tool.value.alerts_threshold
            security_alerts_threshold = required_code_scanning_tool.value.security_alerts_threshold
          }
        }
      }
    }

  }

  dynamic "bypass_actors" {
    for_each = try(each.value.ruleset.bypass_actors, [])

    content {
      actor_id    = try(bypass_actors.value.actor_id, null)
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }
}