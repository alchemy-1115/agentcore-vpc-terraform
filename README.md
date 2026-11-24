# AgentCore VPC Terraform

このプロジェクトは、Amazon Bedrock AgentCore Runtime用のVPCをTerraformで構築するためのコードです。

## 参考ドキュメント

- [Amazon Bedrock AgentCore - VPC Configuration](https://aws.github.io/bedrock-agentcore-starter-toolkit/user-guide/security/agentcore-vpc.md)
- [AWS Regional NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateways-regional.html)
- [AWS Regional NAT Gateway発表](https://aws.amazon.com/about-aws/whats-new/2025/11/aws-nat-gateway-regional-availability/)

## 前提条件

- Terraform 1.0以上
- AWS CLI設定済み（`aws configure sso --profile default` で default プロファイルに IAM Identity Center を設定し、`aws sso login` で認証）
- 適切なIAM権限

## アーキテクチャ

### ネットワーク構成

- **VPC**: 10.0.0.0/16
- **プライベートサブネット**:
  - 10.0.1.0/24 (ap-northeast-1a)
  - 10.0.2.0/24 (ap-northeast-1c)
- **Regional NAT Gateway**: VPCレベルで動作し、全AZに自動拡張

### 設計のポイント

1. **Regional NAT Gateway（2025年11月の新機能）**:
   - パブリックサブネット不要
   - 単一のNAT Gateway IDで全AZをカバー
   - ワークロードに応じて自動的にAZ間で拡張・縮小
   - Automaticモードで自動管理

2. **マルチAZ構成**: 高可用性のため、2つのAvailability Zoneにプライベートサブネットを配置

3. **シンプルな構成**: 従来のZonal NAT Gatewayと比べて、パブリックサブネットやAZごとのNAT Gatewayが不要

## Regional NAT Gatewayのメリット

- **簡素化**: 全AZで単一のNAT IDを使用
- **セキュリティ強化**: パブリックサブネット不要
- **自動高可用性**: ワークロードに応じて自動拡張・縮小
- **高いリミット**: AZあたり最大32個のIPアドレス（従来の4倍）

## ファイル構成

- `provider.tf` - AWSプロバイダーの設定（AWS Provider v6.32.0）
- `variables.tf` - 変数定義
- `main.tf` - VPC、サブネット、Regional NAT Gateway、ルーティングの定義
- `outputs.tf` - 出力値の定義
- `terraform.tfvars.example` - 変数の設定例

## 使い方

### 1. 初期化

```bash
terraform init
```

### 2. 変数ファイルの作成（オプション）

デフォルト値で問題なければスキップ可能です。

```bash
cp terraform.tfvars.example terraform.tfvars
# 必要に応じて terraform.tfvars を編集
```

### 3. プランの確認

```bash
terraform plan
```

### 4. リソースの作成

```bash
terraform apply
```

### 5. 出力値の確認

```bash
terraform output
```

### 6. リソースの削除

```bash
terraform destroy
```

## 作成されるリソース

- VPC
- インターネットゲートウェイ
- プライベートサブネット × 2（ap-northeast-1a、1c）
- Regional NAT Gateway × 1（全AZに自動拡張）
- ルートテーブル × 1（プライベート用）

## コストについて

Regional NAT Gatewayは、ワークロードが存在するAZごとに課金されます。Automaticモードでは、AWSが自動的にIPアドレスを管理するため、実際のワークロードに応じた最適なコスト効率を実現します。

詳細は[NAT Gateway料金ページ](https://aws.amazon.com/vpc/pricing/)を参照してください。

## AgentCore Runtimeのデプロイ

このVPCを使用してAgentCore Runtimeをデプロイする際は、以下を指定してください:

- **サブネット**: `private_subnet_1a_id`と`private_subnet_1c_id`（両方）
- **セキュリティグループ**: 必要に応じて別途作成してください

例:
```bash
aws bedrock-agentcore create-runtime \
  --runtime-name "MyAgentRuntime" \
  --network-configuration '{
    "networkMode": "VPC",
    "networkModeConfig": {
      "subnets": ["<private_subnet_1a_id>", "<private_subnet_1c_id>"],
      "securityGroups": ["<security_group_id>"]
    }
  }'
```

## 注意事項

- Regional NAT Gatewayが新しいAZに拡張するには、最大60分かかる場合があります
- その間、トラフィックは既存のAZのNAT Gatewayを経由します（クロスAZ通信）
- Regional NAT Gatewayはpublic connectivityのみをサポート（private connectivityには非対応）

## サポートされているAvailability Zone

東京リージョン（ap-northeast-1）でAgentCore Runtimeがサポートしているのは以下のAZです:

- apne1-az1 (ap-northeast-1a)
- apne1-az2 (ap-northeast-1c)
- apne1-az4 (ap-northeast-1d)

このコードでは1aと1cを使用しています。
