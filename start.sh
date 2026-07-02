#!/bin/sh
# OpenClaw startup script for Gam Voc CSKH bot
# ALL secrets come from Railway environment variables

set -e

echo "[openclaw-bot] Starting OpenClaw for Gam Voc..."

# Validate required env vars
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "[openclaw-bot] ERROR: TELEGRAM_BOT_TOKEN not set"
  exit 1
fi
if [ -z "$AI_BOX_KEY" ]; then
  echo "[openclaw-bot] ERROR: AI_BOX_KEY not set"
  exit 1
fi

# Defaults for optional vars
AI_BOX_URL="${AI_BOX_URL:-https://api.ai-box.vn/v1}"
AI_BOX_MODEL="${AI_BOX_MODEL:-deepseek-v4-flash}"
FEISHU_APP_ID="${FEISHU_APP_ID:-}"
FEISHU_APP_SECRET="${FEISHU_APP_SECRET:-}"

echo "[openclaw-bot] AI_BOX_URL=$AI_BOX_URL"
echo "[openclaw-bot] AI_BOX_MODEL=$AI_BOX_MODEL"
echo "[openclaw-bot] TELEGRAM_BOT_TOKEN=$(echo "$TELEGRAM_BOT_TOKEN" | cut -c1-10)..."
echo "[openclaw-bot] FEISHU_APP_ID=${FEISHU_APP_ID:+SET}"

# Create workspace directory
mkdir -p /data/workspace

# Write OpenClaw config with AI Box as custom provider
echo "[openclaw-bot] Writing config..."
cat > /data/workspace/openclaw.json << CONFIG
{
  "models": {
    "providers": {
      "ai-box": {
        "baseUrl": "${AI_BOX_URL}",
        "apiKey": "${AI_BOX_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${AI_BOX_MODEL}",
            "name": "AI Box",
            "context": 128000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ai-box/${AI_BOX_MODEL}"
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "open",
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    }
  },
  "agent": {
    "name": "Tro ly Gam Voc",
    "persona": "Ban la tro ly AI cua Gam Voc — shop thoi trang ao dai nu. Ban giup khach hang tra cuu don hang, trang thai giao hang, va tu van san pham. Tra loi bang tieng Viet, than thien, chuyen nghiep. Luon dung lark-cli de tra cuu du lieu tu Lark Base."
  }
}
CONFIG

echo "[openclaw-bot] Config written"

# Run OpenClaw doctor to fix configuration
echo "[openclaw-bot] Running doctor fix..."
openclaw doctor --fix 2>/dev/null || true

# -- Write .env for lark-cli --
if [ -n "$FEISHU_APP_ID" ] && [ -n "$FEISHU_APP_SECRET" ]; then
  mkdir -p /root/.lark-cli
  cat > /root/.lark-cli/.env << ENVEOF
FEISHU_APP_ID=${FEISHU_APP_ID}
FEISHU_APP_SECRET=${FEISHU_APP_SECRET}
ENVEOF
  echo "[openclaw-bot] lark-cli .env written"
else
  echo "[openclaw-bot] WARNING: FEISHU_APP_ID/FEISHU_APP_SECRET not set - lark-cli will not work"
fi

# Start gateway in foreground
echo "[openclaw-bot] Starting gateway..."
exec openclaw gateway
