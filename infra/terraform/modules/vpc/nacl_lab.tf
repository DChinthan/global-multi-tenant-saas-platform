############################################
# Troubleshooting lab: deliberately-misconfigured NACL
#
# See docs/runbooks/nacl-eni-troubleshooting.md for the full walkthrough.
#
# Toggle enable_troubleshooting_lab = true (dev only, never stage/prod) to
# attach a custom NACL to ONE AZ's private-app subnet that blocks inbound
# TCP on the app's container port. Everything else about that subnet's
# reachability looks fine - security groups are untouched - which is the
# point: it reproduces the classic "SG rules are correct, but targets in one
# AZ are still unhealthy" incident, where the real root cause lives one
# layer down at the NACL/ENI level instead.
#
# Attaching ANY custom NACL to a subnet replaces AWS's default "allow all"
# main-VPC NACL for that subnet, and custom NACLs deny-by-default unless a
# rule explicitly allows the traffic. So beyond the one explicit DENY rule
# below, everything else on this subnet is implicitly blocked too until you
# add matching ALLOW rules (or disable the lab).
############################################

resource "aws_network_acl" "lab_broken" {
  count = var.enable_troubleshooting_lab ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = [local.private_app_subnet_ids_sorted[0]]

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-nacl-LAB-BROKEN"
    Purpose = "deliberately-misconfigured-for-runbook-practice"
  })
}

# The actual break: deny inbound TCP on the app's container port from
# anywhere. In a real incident this is the rule an engineer has to find -
# it's easy to miss because the ECS service security group (modules/compute/
# network.tf) already correctly allows this same port from the ALB/NLB SGs.
resource "aws_network_acl_rule" "lab_deny_app_port_inbound" {
  count = var.enable_troubleshooting_lab ? 1 : 0

  network_acl_id = aws_network_acl.lab_broken[0].id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.app_container_port
  to_port        = var.app_container_port
}

# Allow everything else inbound so the ONLY symptom is the app port -
# otherwise the lab would also silently break ephemeral-port return traffic,
# health checks on other ports, etc., muddying the troubleshooting exercise.
resource "aws_network_acl_rule" "lab_allow_other_inbound" {
  count = var.enable_troubleshooting_lab ? 1 : 0

  network_acl_id = aws_network_acl.lab_broken[0].id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "lab_allow_all_outbound" {
  count = var.enable_troubleshooting_lab ? 1 : 0

  network_acl_id = aws_network_acl.lab_broken[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
