# =============================================================================
# Outputs
# =============================================================================

# Outputs - return maps keyed by the same names
output "security_groups" {
  description = "Map of security group details"
  value = {
    for key, sg in aws_security_group.main : key => {
      id          = sg.id
      arn         = sg.arn
      name        = sg.name
      description = sg.description
      vpc_id      = sg.vpc_id
      owner_id    = sg.owner_id
    }
  }
}

output "ingress_rules" {
  description = "Map of ingress rule details grouped by security group"
  value = {
    for sg_key, sg_config in var.security_groups : sg_key => [
      for rule_index, rule in sg_config.ingress_rules : {
        rule_index       = rule_index
        description      = rule.description
        from_port        = rule.from_port
        to_port          = rule.to_port
        protocol         = rule.protocol
        cidr_blocks      = rule.cidr_blocks
        ipv6_cidr_blocks = rule.ipv6_cidr_blocks
        prefix_list_ids  = rule.prefix_list_ids
        security_groups  = rule.security_groups
        self             = rule.self
      }
    ]
  }
}

output "egress_rules" {
  description = "Map of egress rule details grouped by security group"
  value = {
    for sg_key, sg_config in var.security_groups : sg_key => [
      for rule_index, rule in sg_config.egress_rules : {
        rule_index       = rule_index
        description      = rule.description
        from_port        = rule.from_port
        to_port          = rule.to_port
        protocol         = rule.protocol
        cidr_blocks      = rule.cidr_blocks
        ipv6_cidr_blocks = rule.ipv6_cidr_blocks
        prefix_list_ids  = rule.prefix_list_ids
        security_groups  = rule.security_groups
        self             = rule.self
      }
    ]
  }
}

# Convenience outputs for Terragrunt dependencies
output "security_group_ids" {
  description = "Map of security group IDs for easy reference"
  value = {
    for key, sg in aws_security_group.main : key => sg.id
  }
}

output "security_group_arns" {
  description = "Map of security group ARNs for easy reference"
  value = {
    for key, sg in aws_security_group.main : key => sg.arn
  }
}
