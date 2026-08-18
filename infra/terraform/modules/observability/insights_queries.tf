############################################
# CloudWatch Logs Insights saved queries for VPC Flow Logs
#
# Honesty note: default VPC Flow Log records do NOT include a security-group
# ID field - AWS never exposes which SG (or NACL rule) caused a REJECT, only
# that the packet was rejected. These queries answer what flow logs *can*
# actually answer (top talkers by ENI, and where rejects are concentrated by
# destination port/source). Attributing a REJECT to a specific SG/NACL rule
# requires cross-referencing the ENI's attached SG/NACL (describe-network-
# interfaces / describe-security-groups / describe-network-acls) or running
# VPC Reachability Analyzer - see docs/runbooks/nacl-eni-troubleshooting.md.
############################################

resource "aws_cloudwatch_query_definition" "flow_logs_top_talkers" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name            = "${local.name_prefix}/vpc-flow-logs/top-talkers-by-eni"
  log_group_names = [aws_cloudwatch_log_group.vpc_flow_logs[0].name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | parse @message "* * * * * * * * * * * * * *" as version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, start, end, action, log_status
    | filter log_status = "OK"
    | stats sum(bytes) as totalBytes, sum(packets) as totalPackets by interface_id
    | sort totalBytes desc
    | limit 20
  QUERY
}

resource "aws_cloudwatch_query_definition" "flow_logs_rejects" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name            = "${local.name_prefix}/vpc-flow-logs/rejected-connections-by-dest-port"
  log_group_names = [aws_cloudwatch_log_group.vpc_flow_logs[0].name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | parse @message "* * * * * * * * * * * * * *" as version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, start, end, action, log_status
    | filter action = "REJECT"
    | stats count(*) as rejectedConnections by dstport, srcaddr, interface_id
    | sort rejectedConnections desc
    | limit 20
  QUERY
}
