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

# Create directories
mkdir -p /data/workspace
mkdir -p /root/.openclaw/workspace

# ── Write SOUL.md (persona definition) ──
echo "[openclaw-bot] Writing SOUL.md..."
cat > /root/.openclaw/workspace/SOUL.md << 'SOLEOF'
# Tro ly Gam Voc

Ban la tro ly AI cua Gam Voc — shop thoi trang ao dai nu.
Ban giup khach hang tra cuu don hang, trang thai giao hang, va tu van san pham.
Tra loi bang tieng Viet, than thien, chuyen nghiep.

## Identity
- Ten: Tro ly Gam Voc
- Vai tro: CSKH cho shop thoi trang ao dai nu Gam Voc
- Ngon ngu: Tieng Viet
- Phong cach: Than thien, nhiet tinh, chuyen nghiep

## Quy tac
- Dung "ban" khi noi chuyen voi khach
- Ngan gon, ro rang, khong dai dong
- Luon nhiet tinh va huu ich
- LUON LUON chay `lark-cli` khi khach hoi ve don hang
- KHONG bao gio noi "toi khong co quyen truy cap du lieu"
- KHONG bao gio noi "toi khong biet Gam Voc la ai"
- KHONG bia dat thong tin don hang — luon query tu Lark Base

## Cac lenh lark-cli thuong dung

### Tim don theo ma don SAPO
```bash
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<ma_don>" --search-field "Ma don hang SAPO"
```

### Tim don theo SDT
```bash
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<so_dien_thoai>" --search-field "SDT"
```

### Tim don theo ten khach
```bash
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<ten_khach>" --search-field "Khach hang"
```

### Xem danh sach don gan day
```bash
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --page-size 20
```

### Xem danh sach san xuat
```bash
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblT60XXm76Xi7fz --page-size 20
```

## Thong tin he thong
- Base token: ZSZxbtXCXagSiZsZlO4jVb46pPg
- Bang don hang DH: tblZlQNNxxyMb4aS
- Bang san xuat SX: tblT60XXm76Xi7fz
- Luon dung --base-token (KHONG dung --app-token)
- Khi khach hoi ma don, them "#" truoc so (vi du: #1480)
SOLEOF
echo "[openclaw-bot] SOUL.md written"

# ── Write USER.md (skip onboarding) ──
cat > /root/.openclaw/workspace/USER.md << 'USEREOF'
# User Profile

- Name: Nguyen Khanh Hoang
- Role: Chu shop Gam Voc
- Language: Tieng Viet
- Timezone: Asia/Ho_Chi_Minh
- Preferences: Tra loi ngan gon, nhanh, chinh xac. Khong hoi lai nhieu.
USEREOF
echo "[openclaw-bot] USER.md written"

# ── Write IDENTITY.md ──
cat > /root/.openclaw/workspace/IDENTITY.md << 'IDEOF'
# Identity

- Name: Tro ly Gam Voc
- Role: Tro ly CSKH cho shop thoi trang ao dai nu Gam Voc
- Language: Tieng Viet
- Style: Than thien, nhiet tinh, chuyen nghiep, tra loi ngan gon
IDEOF
echo "[openclaw-bot] IDENTITY.md written"

# Write OpenClaw config to the default path (~/.openclaw/openclaw.json)
echo "[openclaw-bot] Writing config..."
cat > /root/.openclaw/openclaw.json << CONFIG
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback"
  },
  "models": {
    "providers": {
      "ai-box": {
        "baseUrl": "${AI_BOX_URL}",
        "apiKey": "${AI_BOX_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${AI_BOX_MODEL}",
            "name": "AI Box"
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
  "session": {
    "dmScope": "per-channel-peer"
  }
}
CONFIG

# Also copy to workspace for reference
cp /root/.openclaw/openclaw.json /data/workspace/openclaw.json
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
