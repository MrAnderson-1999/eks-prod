
# Input - exactly one plural map(object) variable per resource family
variable "security_groups" {
  description = "Map of security group configurations"
  type = map(object({
    description = string
    vpc_id      = string
    ingress_rules = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      prefix_list_ids  = optional(list(string), [])
      security_groups  = optional(list(string), [])
      self             = optional(bool, false)
    })), [])
    egress_rules = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      prefix_list_ids  = optional(list(string), [])
      security_groups  = optional(list(string), [])
      self             = optional(bool, false)
    })), [
      # Default egress rule - allow all outbound traffic
      {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ])
    revoke_rules_on_delete = optional(bool, false)
    tags                   = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.security_groups : alltrue([
        for rule in concat(v.ingress_rules, v.egress_rules) : 
        contains(["tcp", "udp", "icmp", "icmpv6", "all", "-1"], rule.protocol)
      ])
    ])
    error_message = "Protocol must be one of: tcp, udp, icmp, icmpv6, all, or -1."
  }

  validation {
    condition = alltrue([
      for k, v in var.security_groups : alltrue([
        for rule in concat(v.ingress_rules, v.egress_rules) : 
        rule.from_port >= 0 && rule.from_port <= 65535 && 
        rule.to_port >= 0 && rule.to_port <= 65535 &&
        rule.from_port <= rule.to_port
      ])
    ])
    error_message = "Port numbers must be between 0-65535 and from_port must be <= to_port."
  }

  validation {
    condition = alltrue([
      for k, v in var.security_groups : alltrue([
        for rule in concat(v.ingress_rules, v.egress_rules) : 
        length(rule.cidr_blocks) > 0 || 
        length(rule.ipv6_cidr_blocks) > 0 || 
        length(rule.prefix_list_ids) > 0 || 
        length(rule.security_groups) > 0 || 
        rule.self == true
      ])
    ])
    error_message = "Each rule must specify at least one source: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, security_groups, or self."
  }
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

# Logic - for_each over every map
locals {
  common_tags = merge(
    {
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # Flatten ingress rules for each security group
  ingress_rules_list = flatten([
    for sg_key, sg_config in var.security_groups : [
      for rule_index, rule in sg_config.ingress_rules : {
        sg_key       = sg_key
        rule_index   = rule_index
        unique_id    = "${sg_key}-ingress-${rule_index}"
        description  = rule.description
        from_port    = rule.from_port
        to_port      = rule.to_port
        protocol     = rule.protocol
        cidr_blocks      = rule.cidr_blocks
        ipv6_cidr_blocks = rule.ipv6_cidr_blocks
        prefix_list_ids  = rule.prefix_list_ids
        security_groups  = rule.security_groups
        self             = rule.self
      }
    ]
  ])

  # Flatten egress rules for each security group
  egress_rules_list = flatten([
    for sg_key, sg_config in var.security_groups : [
      for rule_index, rule in sg_config.egress_rules : {
        sg_key       = sg_key
        rule_index   = rule_index
        unique_id    = "${sg_key}-egress-${rule_index}"
        description  = rule.description
        from_port    = rule.from_port
        to_port      = rule.to_port
        protocol     = rule.protocol
        cidr_blocks      = rule.cidr_blocks
        ipv6_cidr_blocks = rule.ipv6_cidr_blocks
        prefix_list_ids  = rule.prefix_list_ids
        security_groups  = rule.security_groups
        self             = rule.self
      }
    ]
  ])
}
