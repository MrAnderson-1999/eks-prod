# Logic - for_each over every map
locals {


  # Flatten inline policies for each role
  inline_policies_list = flatten([
    for role_key, role_config in var.roles : [
      for policy_name, policy_config in role_config.inline_policies : {
        role_key     = role_key
        policy_name  = policy_name
        policy       = policy_config.policy
        unique_id    = "${role_key}-${policy_name}"
      }
    ]
  ])

  # Flatten managed policy attachments for each role
  managed_policy_attachments = flatten([
    for role_key, role_config in var.roles : [
      for policy_arn in role_config.managed_policy_arns : {
        role_key    = role_key
        policy_arn  = policy_arn
        unique_id   = "${role_key}-${replace(policy_arn, "/[^a-zA-Z0-9]/", "-")}"
      }
    ]
  ])
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Roles
resource "aws_iam_role" "main" {
  for_each = var.roles

  name                  = "${var.name_prefix}-${each.key}-role"
  description          = each.value.description
  assume_role_policy   = each.value.assume_role_policy
  max_session_duration = each.value.max_session_duration
  path                 = each.value.path
  permissions_boundary = each.value.permissions_boundary
  force_detach_policies = each.value.force_detach_policies

  tags = merge(each.value.tags, {
    Name    = "${var.name_prefix}-${each.key}-role"
    Purpose = "iam-role-${each.key}"
  })
}

# Inline IAM Policies
resource "aws_iam_role_policy" "main" {
  for_each = {
    for policy in local.inline_policies_list : policy.unique_id => policy
  }

  name   = "${var.name_prefix}-${each.value.role_key}-${each.value.policy_name}-policy"
  role   = aws_iam_role.main[each.value.role_key].id
  policy = each.value.policy
}

# Managed Policy Attachments
resource "aws_iam_role_policy_attachment" "main" {
  for_each = {
    for attachment in local.managed_policy_attachments : attachment.unique_id => attachment
  }

  role       = aws_iam_role.main[each.value.role_key].name
  policy_arn = each.value.policy_arn
}