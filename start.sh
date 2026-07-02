#!/bin/sh
# OpenClaw startup script for Gấm Vóc CSKH bot

echo "[openclaw-bot] Starting OpenClaw for Gấm Vóc..."

# Set environment variables
export TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-8673157236:AAEYeFjsglFvGQLyk6Ybs1lm9yQSNjkV1KQ}"
export AI_BOX_KEY="${AI_BOX_KEY:-sk-V34DDrtMOcHX8ZiRuhS2Hq8BmgWzKVZp4VtwlWCHJC4caJPS}"

# Create workspace directory
mkdir -p /data/workspace

# Write OpenClaw config with AI Box as custom provider
echo "[openclaw-bot] Writing config..."
cat > /data/workspace/openclaw.json << 'CONFIG'
{
  "models": {
    "providers": {
      "ai-box": {
        "baseUrl": "https://api.ai-box.vn/v1",
        "apiKey": "sk-V34DDrtMOcHX8ZiRuhS2Hq8BmgWzKVZp4VtwlWCHJC4caJPS",
        "api": "openai-completions",
        "models": [
          {
            "id": "deepseek-v4-flash",
            "name": "DeepSeek V4 Flash",
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
        "primary": "ai-box/deepseek-v4-flash"
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "8673157236:AAEYeFjsglFvGQLyk6Ybs1lm9yQSNjkV1KQ",
      "dmPolicy": "open",
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    }
  },
  "agent": {
    "name": "Trợ lý Gấm Vóc",
    "persona": "Bạn là trợ lý AI của Gấm Vóc — shop thời trang áo dài nữ. Bạn giúp khách hàng tra cứu đơn hàng, trạng thái giao hàng, và tư vấn sản phẩm. Trả lời bằng tiếng Việt, thân thiện, chuyên nghiệp. Luôn dùng lark-cli để tra cứu dữ liệu từ Lark Base."
  }
}
CONFIG

# Run OpenClaw doctor to fix configuration
echo "[openclaw-bot] Running doctor fix..."
openclaw doctor --fix 2>/dev/null || true

# Start gateway in foreground (Railway will manage the process)
echo "[openclaw-bot] Starting gateway..."
exec openclaw gateway
