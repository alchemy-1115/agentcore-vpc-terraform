# =============================================================================
# データソース
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 既存のECRリポジトリを参照（agentcore-vpc-agentにある既存イメージを使用）
data "aws_ecr_repository" "agent" {
  name = var.ecr_repository_name
}

# =============================================================================
# セキュリティグループ（AgentCore Runtime用）
# =============================================================================

resource "aws_security_group" "agentcore" {
  name        = "${var.project_name}-${var.environment}-agentcore-sg"
  description = "Security group for AgentCore Runtime outbound traffic"
  vpc_id      = aws_vpc.main.id

  # AgentCore はアウトバウンドのみ（インバウンドは不要）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic (for Bedrock / ECR / CloudWatch access)"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-agentcore-sg"
    Environment = var.environment
  }
}

# =============================================================================
# IAMロール（AgentCore Runtime 実行用）
# =============================================================================

resource "aws_iam_role" "agentcore_execution" {
  name = "${var.project_name}-${var.environment}-agentcore-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AgentCoreAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "bedrock-agentcore.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        # このアカウントのAgentCoreリソースからのみ AssumeRole を許可（最小権限の原則）
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.id}:*"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-agentcore-execution-role"
    Environment = var.environment
  }
}

# AWS管理ポリシー（BedrockAgentCore全般アクセス）をアタッチ
resource "aws_iam_role_policy_attachment" "agentcore_managed" {
  role       = aws_iam_role.agentcore_execution.name
  policy_arn = "arn:aws:iam::aws:policy/BedrockAgentCoreFullAccess"
}

# カスタムインラインポリシー（ECR・CloudWatch・Bedrock等の最小権限）
resource "aws_iam_role_policy" "agentcore_execution" {
  name = "AgentCoreExecutionPolicy"
  role = aws_iam_role.agentcore_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECRからコンテナイメージを取得する権限
      {
        Sid    = "ECRImageAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = data.aws_ecr_repository.agent.arn
      },
      {
        Sid      = "ECRAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      # CloudWatch Logsへのログ書き込み権限
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.id}:log-group:/aws/bedrock-agentcore/runtimes/*"
      },
      # Bedrock モデル呼び出し権限（エージェントがLLMを使うため）
      {
        Sid    = "BedrockModelInvocation"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
      # X-Ray トレーシング（オプション：デバッグ用途）
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# AgentCore Runtime（VPCモード）
# =============================================================================

resource "aws_bedrockagentcore_agent_runtime" "main" {
  agent_runtime_name = var.agent_runtime_name
  description        = "${var.project_name} Q&Aエージェント（VPC接続モード）"
  role_arn           = aws_iam_role.agentcore_execution.arn

  # コンテナイメージの指定（ECRリポジトリ: agentcore-vpc-agent）
  agent_runtime_artifact {
    container_configuration {
      container_uri = "${data.aws_ecr_repository.agent.repository_url}:${var.container_image_tag}"
    }
  }

  # VPCモードの設定
  # AgentCoreがプライベートサブネット内にENI（ネットワークインターフェース）を作成し
  # NAT Gatewayを経由してBedrockエンドポイント等に接続する
  network_configuration {
    network_mode = "VPC"
    network_mode_config {
      subnets         = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
      security_groups = [aws_security_group.agentcore.id]
    }
  }

  # エージェントコンテナに渡す環境変数
  environment_variables = {
    AWS_REGION         = var.aws_region
    AWS_DEFAULT_REGION = var.aws_region
  }

  depends_on = [
    aws_iam_role_policy.agentcore_execution,
    aws_iam_role_policy_attachment.agentcore_managed,
    aws_nat_gateway.regional,
    aws_route_table_association.private_1a,
    aws_route_table_association.private_1c,
  ]
}
