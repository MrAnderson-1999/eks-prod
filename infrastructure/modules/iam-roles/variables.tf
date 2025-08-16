
# Input - exactly one plural map(object) variable per resource family
variable "roles" {
  description = "Map of IAM role configurations"
  type = map(object({
    description                = string
    assume_role_policy        = string
    max_session_duration      = optional(number, 3600)
    path                      = optional(string, "/")
    permissions_boundary      = optional(string)
    force_detach_policies     = optional(bool, false)
    inline_policies = optional(map(object({
      policy = string
    })), {})
    managed_policy_arns = optional(list(string), [])
    tags               = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.roles : can(jsondecode(v.assume_role_policy))
    ])
    error_message = "The assume_role_policy must be a valid JSON string."
  }

  validation {
    condition = alltrue([
      for k, v in var.roles : alltrue([
        for policy_name, policy_config in v.inline_policies : can(jsondecode(policy_config.policy))
      ])
    ])
    error_message = "All inline policies must be valid JSON strings."
  }

  validation {
    condition = alltrue([
      for k, v in var.roles : v.max_session_duration >= 3600 && v.max_session_duration <= 43200
    ])
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}