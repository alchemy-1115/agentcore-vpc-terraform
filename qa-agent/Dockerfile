# AgentCore Runtime は ARM64 アーキテクチャで動作する
# ローカルビルド時: docker buildx build --platform linux/arm64 -t qa-agent .
FROM python:3.12-slim

WORKDIR /app

# 依存ライブラリのインストール（キャッシュ活用のためrequirements.txtを先にコピー）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコードをコピー
COPY agent.py .

# AgentCore が使用するポート
EXPOSE 8080

# app.run() が Uvicorn サーバーを起動する
CMD ["python", "agent.py"]
