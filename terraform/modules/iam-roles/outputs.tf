# =============================================================================
# Outputs
# =============================================================================

# Outputs - return maps keyed by the same names
output "roles" {
  description = "Map of IAM role details"
  value = {
    for key, role in aws_iam_role.main : key => {
      name                  = role.name
      arn                   = role.arn
      id                    = role.id
      unique_id             = role.unique_id
      description          = role.description
      path                 = role.path
      max_session_duration = role.max_session_duration
      assume_role_policy   = role.assume_role_policy
    }
  }
}

output "inline_policies" {
  description = "Map of inline policy details grouped by role"
  value = {
    for role_key, role_config in var.roles : role_key => {
      for policy_name, policy_config in role_config.inline_policies : policy_name => {
        name   = aws_iam_role_policy.main["${role_key}-${policy_name}"].name
        policy = aws_iam_role_policy.main["${role_key}-${policy_name}"].policy
      }
    }
  }
}

output "managed_policy_attachments" {
  description = "Map of managed policy attachments grouped by role"
  value = {
    for role_key, role_config in var.roles : role_key => {
      policy_arns = role_config.managed_policy_arns
    }
  }
}

# Convenience outputs for Terragrunt dependencies
output "role_arns" {
  description = "Map of role ARNs for easy reference"
  value = {
    for key, role in aws_iam_role.main : key => role.arn
  }
}

output "role_names" {
  description = "Map of role names for easy reference"
  value = {
    for key, role in aws_iam_role.main : key => role.name
  }
} 