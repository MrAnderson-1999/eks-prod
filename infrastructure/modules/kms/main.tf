# Provider versions are managed centrally by Terragrunt root configuration
# No local provider version constraints to avoid conflicts

# Input - exactly one plural map(object) variable per resource family
variable "kms_keys" {
  description = "Map of KMS key configurations"
  type = map(object({
    description                  = string
    deletion_window_in_days      = optional(number, 7)
    enable_key_rotation          = optional(bool, true)
    key_usage                    = optional(string, "ENCRYPT_DECRYPT")
    customer_master_key_spec     = optional(string, "SYMMETRIC_DEFAULT")
    multi_region                 = optional(bool, false)
    aliases                      = optional(list(string), [])
    key_policy                   = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.kms_keys : v.key_policy == null ? true : can(jsondecode(v.key_policy))
    ])
    error_message = "If provided, the key_policy must be a valid JSON string."
  }
}

variable "additional_policy_statements" {
  description = "A map of additional policy statements to add to each key, keyed by the key name."
  type        = map(list(any))
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# Data sources inside module
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Logic - for_each over every map
locals {
  common_tags = merge(
    {
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # Flatten aliases for each key
  aliases_list = flatten([
    for key, config in var.kms_keys : [
      for alias in config.aliases : {
        key        = key
        alias_name = alias
        unique_id  = "${key}-${alias}"
      }
    ]
  ])
}

# Default KMS key policy template - for final application
data "aws_iam_policy_document" "full_policy" {
  for_each = var.kms_keys

  # 1. Enable IAM User Permissions (always first)
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # 2. Additional policy statements (e.g., CloudFront)
  dynamic "statement" {
    for_each = lookup(var.additional_policy_statements, each.key, [])

    content {
      sid     = lookup(statement.value, "sid", null)
      effect  = lookup(statement.value, "effect", "Allow")
      actions = lookup(statement.value, "actions", [])
      
      dynamic "principals" {
        for_each = try(statement.value.principals, null) != null ? [statement.value.principals] : []
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
      
      resources = lookup(statement.value, "resources", [])
      
      dynamic "condition" {
        for_each = lookup(statement.value, "condition", [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }

  # 3. Allow CloudWatch Logs
  statement {
    sid    = "Allow CloudWatch Logs"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*", 
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    
    resources = ["*"]
  }

  # 4. Allow S3 Service (always last)
  statement {
    sid    = "Allow S3 Service"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt", 
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    
    resources = ["*"]
  }
}

# Minimal KMS key policy for initial creation to break dependency cycles
data "aws_iam_policy_document" "creation_policy" {
  for_each = var.kms_keys

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

# KMS Keys - using creation policy first to avoid dependency cycles
resource "aws_kms_key" "main" {
  for_each = var.kms_keys

  description              = each.value.description
  deletion_window_in_days  = each.value.deletion_window_in_days
  enable_key_rotation      = each.value.enable_key_rotation
  key_usage               = each.value.key_usage
  customer_master_key_spec = each.value.customer_master_key_spec
  multi_region            = each.value.multi_region
  policy                  = coalesce(each.value.key_policy, data.aws_iam_policy_document.creation_policy[each.key].json)

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })

  lifecycle {
    ignore_changes = [policy]
  }
}

# KMS Key Policy - applies the full policy after dependencies are resolved
resource "aws_kms_key_policy" "main" {
  for_each = {
    for key, config in var.kms_keys : key => config
    if config.key_policy == null # Only manage policy if not overridden
  }

  key_id = aws_kms_key.main[each.key].id
  policy = data.aws_iam_policy_document.full_policy[each.key].json

  depends_on = [aws_kms_key.main]
}

# KMS Aliases
resource "aws_kms_alias" "main" {
  for_each = {
    for alias in local.aliases_list : alias.unique_id => alias
  }

  name          = "alias/${each.value.alias_name}"
  target_key_id = aws_kms_key.main[each.value.key].key_id
}

# Default aliases for keys without explicit aliases
resource "aws_kms_alias" "default" {
  for_each = {
    for key, config in var.kms_keys : key => config
    if length(config.aliases) == 0
  }

  name          = "alias/${var.name_prefix}-${each.key}-key"
  target_key_id = aws_kms_key.main[each.key].key_id
}

# =============================================================================
# Outputs
# =============================================================================

# Outputs - return maps keyed by the same names
output "kms_keys" {
  description = "Map of KMS key details"
  value = {
    for key, kms_key in aws_kms_key.main : key => {
      id          = kms_key.key_id
      arn         = kms_key.arn
      description = kms_key.description
      usage       = kms_key.key_usage
      rotation    = kms_key.enable_key_rotation
    }
  }
}

output "kms_aliases" {
  description = "Map of KMS key aliases"
  value = {
    for key, config in var.kms_keys : key => {
      names = length(config.aliases) > 0 ? [for alias in config.aliases : "alias/${alias}"] : [aws_kms_alias.default[key].name]
      arns = length(config.aliases) > 0 ? [for alias_key in keys(aws_kms_alias.main) : aws_kms_alias.main[alias_key].arn if startswith(alias_key, "${key}-")] : [aws_kms_alias.default[key].arn]
    }
  }
}
