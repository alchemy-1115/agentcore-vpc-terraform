output "vpc_id" {
  description = "VPCのID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPCのCIDRブロック"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "プライベートサブネットのIDリスト"
  value       = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
}

output "private_subnet_1a_id" {
  description = "プライベートサブネット（1a）のID"
  value       = aws_subnet.private_1a.id
}

output "private_subnet_1c_id" {
  description = "プライベートサブネット（1c）のID"
  value       = aws_subnet.private_1c.id
}

output "internet_gateway_id" {
  description = "インターネットゲートウェイのID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "Regional NAT GatewayのID"
  value       = aws_nat_gateway.regional.id
}

output "nat_gateway_route_table_id" {
  description = "Regional NAT Gatewayが自動作成するルートテーブルのID"
  value       = aws_nat_gateway.regional.route_table_id
}

output "agentcore_runtime_id" {
  description = "AgentCore RuntimeのID"
  value       = aws_bedrockagentcore_agent_runtime.main.agent_runtime_id
}

output "agentcore_runtime_arn" {
  description = "AgentCore RuntimeのARN"
  value       = aws_bedrockagentcore_agent_runtime.main.agent_runtime_arn
}

output "agentcore_security_group_id" {
  description = "AgentCore Runtime用セキュリティグループのID"
  value       = aws_security_group.agentcore.id
}

output "agentcore_execution_role_arn" {
  description = "AgentCore Runtime実行ロールのARN"
  value       = aws_iam_role.agentcore_execution.arn
}
