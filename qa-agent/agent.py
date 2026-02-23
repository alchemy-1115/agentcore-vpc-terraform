"""
シンプルなQ&AエージェントをStrands AgentとBedrock AgentCoreで構築

ローカルテスト: agentcore launch --local
本番デプロイ:   agentcore launch
呼び出し:       agentcore invoke '{"prompt": "AWSとは何ですか？"}'
"""

from strands import Agent
from strands.models import BedrockModel
from strands_tools import http_request
from bedrock_agentcore.runtime import BedrockAgentCoreApp

# ---- モデルの設定 ----
model = BedrockModel(
    model_id="jp.anthropic.claude-sonnet-4-5-20250929-v1:0",
    region_name="ap-northeast-1",
)

# ---- エージェントの作成 ----
agent = Agent(
    model=model,
    tools=[http_request],
    system_prompt=(
        "あなたは親切で知識豊富なAIアシスタントです。"
        "ユーザーからの質問に対して、正確でわかりやすい日本語で回答してください。"
        "わからないことは正直にわからないと答え、情報は最新のものを提供するよう努めてください。"
        "必要に応じてhttp_requestツールを使ってWeb上の最新情報を取得できます。"
    ),
)

# ---- AgentCore エントリポイント ----
app = BedrockAgentCoreApp()


@app.entrypoint
def invoke(payload, context):
    """AgentCoreから呼び出されるエントリポイント"""
    user_message = payload.get(
        "prompt", "こんにちは！何かお手伝いできることはありますか？"
    )
    result = agent(user_message)
    return {"result": result.message}


if __name__ == "__main__":
    app.run()
