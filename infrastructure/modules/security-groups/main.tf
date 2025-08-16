# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Security Groups
resource "aws_security_group" "main" {
  for_each = var.security_groups

  name        = "${var.name_prefix}-${each.key}-sg"
  description = each.value.description
  vpc_id      = each.value.vpc_id

  revoke_rules_on_delete = each.value.revoke_rules_on_delete

  tags = merge(local.common_tags, each.value.tags, {
    Name    = "${var.name_prefix}-${each.key}-sg"
    Purpose = "security-group-${each.key}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Ingress Rules
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for rule in local.ingress_rules_list : rule.unique_id => rule
  }

  type              = "ingress"
  security_group_id = aws_security_group.main[each.value.sg_key].id
  description       = each.value.description

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  ipv6_cidr_blocks         = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null
  prefix_list_ids          = length(each.value.prefix_list_ids) > 0 ? each.value.prefix_list_ids : null
  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
  self                     = each.value.self ? true : null
}

# Security Group Egress Rules
resource "aws_security_group_rule" "egress" {
  for_each = {
    for rule in local.egress_rules_list : rule.unique_id => rule
  }

  type              = "egress"
  security_group_id = aws_security_group.main[each.value.sg_key].id
  description       = each.value.description

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  ipv6_cidr_blocks         = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null
  prefix_list_ids          = length(each.value.prefix_list_ids) > 0 ? each.value.prefix_list_ids : null
  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
  self                     = each.value.self ? true : null
}

# Optional inter-group rule: allow HTTP from ALB SG to Nodes/Pods SG (for ALB IP target mode)
locals {
  create_alb_to_nodes_http = contains(keys(aws_security_group.main), "eks_nodes") && contains(keys(aws_security_group.main), "eks_alb")
}

resource "aws_security_group_rule" "alb_to_nodes_http" {
  count = local.create_alb_to_nodes_http ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.main["eks_nodes"].id
  description              = "HTTP from ALB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main["eks_alb"].id
}

# Optional inter-group rule: allow HTTPS from ALB SG to Nodes/Pods SG
resource "aws_security_group_rule" "alb_to_nodes_https" {
  count = local.create_alb_to_nodes_http ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.main["eks_nodes"].id
  description              = "HTTPS from ALB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main["eks_alb"].id
}
