# Security Groups Module

This module creates AWS Security Groups with configurable ingress and egress rules following the established module design pattern.

## Features

- **Flexible Rule Management**: Support for multiple ingress and egress rules per security group
- **Multiple Source Types**: CIDR blocks, IPv6 CIDR blocks, prefix lists, other security groups, and self-referencing
- **Comprehensive Validation**: Built-in validation for protocols, ports, and rule sources
- **Default Egress**: Includes sensible default egress rule (allow all outbound)
- **Consistent Naming**: Follows the project naming conventions with prefix and purpose tags
- **Lifecycle Management**: Includes `create_before_destroy` for safe updates

## Usage

### Basic Example

```hcl
module "security_groups" {
  source = "../../modules/security"

  security_groups = local.security_groups
  name_prefix     = local.name_prefix
  tags           = local.common_tags
}
```

### Configuration Example

```hcl
# config.security.tf
locals {
  security_groups = {
    web = {
      description = "Security group for web servers"
      vpc_id      = module.vpc.vpc_id
      ingress_rules = [
        {
          description = "HTTP from anywhere"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          description = "HTTPS from anywhere"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    
    database = {
      description = "Security group for database servers"
      vpc_id      = module.vpc.vpc_id
      ingress_rules = [
        {
          description     = "MySQL/Aurora from web servers"
          from_port       = 3306
          to_port         = 3306
          protocol        = "tcp"
          security_groups = [module.security_groups.security_groups["web"].id]
        }
      ]
      egress_rules = [
        {
          description = "HTTPS outbound for updates"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    
    internal = {
      description = "Internal communication security group"
      vpc_id      = module.vpc.vpc_id
      ingress_rules = [
        {
          description = "All internal traffic"
          from_port   = 0
          to_port     = 65535
          protocol    = "tcp"
          self        = true
        }
      ]
    }
  }
}
```

## Input Variables

### security_groups

Map of security group configurations with the following structure:

- **description** (string, required): Description of the security group
- **vpc_id** (string, required): VPC ID where the security group will be created
- **ingress_rules** (list, optional): List of ingress rule objects
- **egress_rules** (list, optional): List of egress rule objects (defaults to allow all outbound)
- **revoke_rules_on_delete** (bool, optional): Whether to revoke rules on delete (default: false)
- **tags** (map, optional): Additional tags for the security group

### Rule Object Structure

Each rule in `ingress_rules` and `egress_rules` supports:

- **description** (string, optional): Description of the rule
- **from_port** (number, required): Start port (0-65535)
- **to_port** (number, required): End port (0-65535)
- **protocol** (string, required): Protocol (tcp, udp, icmp, icmpv6, all, or -1)
- **cidr_blocks** (list, optional): IPv4 CIDR blocks
- **ipv6_cidr_blocks** (list, optional): IPv6 CIDR blocks
- **prefix_list_ids** (list, optional): Prefix list IDs
- **security_groups** (list, optional): Source/destination security group IDs
- **self** (bool, optional): Allow traffic from/to the same security group

### Common Variables

- **name_prefix** (string, required): Prefix for naming resources
- **tags** (map, optional): Additional tags for all resources

## Outputs

### security_groups

Map of security group details:
- **id**: Security group ID
- **arn**: Security group ARN
- **name**: Security group name
- **description**: Security group description
- **vpc_id**: VPC ID
- **owner_id**: AWS account ID

### ingress_rules / egress_rules

Maps of rule details grouped by security group for reference and debugging.

## Validation Rules

The module includes comprehensive validation:

1. **Protocol validation**: Must be tcp, udp, icmp, icmpv6, all, or -1
2. **Port validation**: Ports must be 0-65535 and from_port ≤ to_port
3. **Source validation**: Each rule must specify at least one source (CIDR, security group, etc.)

## Best Practices

1. **Least Privilege**: Only open necessary ports and sources
2. **Descriptive Names**: Use clear, descriptive names for security groups and rules
3. **Rule Organization**: Group related rules logically
4. **Reference Security Groups**: Use security group references instead of IP ranges when possible
5. **Regular Review**: Regularly review and audit security group rules

## Common Protocols and Ports

| Service | Protocol | Port | Description |
|---------|----------|------|-------------|
| HTTP | tcp | 80 | Web traffic |
| HTTPS | tcp | 443 | Secure web traffic |
| SSH | tcp | 22 | Secure shell |
| RDP | tcp | 3389 | Remote desktop |
| MySQL/Aurora | tcp | 3306 | Database |
| PostgreSQL | tcp | 5432 | Database |
| Redis | tcp | 6379 | Cache |
| SMTP | tcp | 25 | Email |

## Dependencies

- AWS Provider >= 5.0
- VPC must exist before creating security groups
- Referenced security groups must exist when using cross-references
