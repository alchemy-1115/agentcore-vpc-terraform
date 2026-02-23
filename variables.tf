variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "agentcore-vpc"
}

variable "environment" {
  description = "環境名（dev, staging, prod等）"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ecr_repository_name" {
  description = "AgentCoreが使用するECRリポジトリ名"
  type        = string
  default     = "agentcore-vpc-agent"
}

variable "agent_runtime_name" {
  description = "AgentCore Runtimeの名前"
  type        = string
  default     = "agentcore_vpc_agent"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,47}$", var.agent_runtime_name))
    error_message = "Runtime名は英字始まり、英数字とアンダースコアのみ、最大48文字"
  }
}

variable "container_image_tag" {
  description = "ECRイメージのタグ"
  type        = string
  default     = "latest"
}
