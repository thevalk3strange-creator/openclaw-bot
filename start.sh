#!/bin/sh
# OpenClaw startup script for Gấm Vóc CSKH bot

echo "[openclaw-bot] Starting OpenClaw for Gấm Vóc..."

# Set environment variables
export TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-8673157236:AAEYeFjsglFvGQLyk6Ybs1lm9yQSNjkV1KQ}"
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-sk-V34DDrtMOcHX8ZiRuhS2Hq8BmgWzKVZp4VtwlWCHJC4caJPS}"

# Run OpenClaw onboarding (non-interactive)
echo "[openclaw-bot] Running onboarding..."
openclaw onboard --non-interactive \
  --accept-risk \
  --mode local \
  --auth-choice apiKey \
  --anthropic-api-key "$ANTHROPIC_API_KEY" \
  --gateway-port 18789 \
  --workspace /data/workspace

# Configure Telegram channel
echo "[openclaw-bot] Configuring Telegram..."
cat > /data/workspace/openclaw.json << 'CONFIG'
{
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
    "persona": "Bạn là trợ lý AI của Gấm Vóc — shop thời trang áo dài nữ. Bạn giúp khách hàng tra cứu đơn hàng, trạng thái giao hàng, và tư vấn sản phẩm. Trả lời bằng tiếng Việt, thân thiện, chuyên nghiệp."
  }
}
CONFIG

# Fix configuration
echo "[openclaw-bot] Running doctor fix..."
openclaw doctor --fix

# Start gateway in background
echo "[openclaw-bot] Starting gateway..."
openclaw gateway &

# Wait for gateway to start
sleep 5

# Start API server
echo "[openclaw-bot] Starting API server on port 8081..."
openclaw api --port 8081
