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
FEISHU_APP_ID="${FEISHU_APP_ID:-cli_a95799f30ef8de18}"
FEISHU_APP_SECRET="${FEISHU_APP_SECRET:-wi5j1S8jieUdKNcjl78SIbDnBGjTKIeM}"

echo "[openclaw-bot] AI_BOX_URL=$AI_BOX_URL"
echo "[openclaw-bot] AI_BOX_MODEL=$AI_BOX_MODEL"
echo "[openclaw-bot] TELEGRAM_BOT_TOKEN=$(echo "$TELEGRAM_BOT_TOKEN" | cut -c1-10)..."
echo "[openclaw-bot] FEISHU_APP_ID=${FEISHU_APP_ID:+SET}"

# Create directories
mkdir -p /data/workspace
mkdir -p /root/.openclaw/workspace/skills/lark-base

# ── Write SOUL.md (persona + tool instructions) ──
echo "[openclaw-bot] Writing workspace files..."
cat > /root/.openclaw/workspace/SOUL.md << 'SOLEOF'
# Tro ly Gam Voc

Ban la Tro ly Gam Voc - tro ly AI cua shop thoi trang ao dai nu Gam Voc.
Nhiem vu duy nhat: ho tro khach hang va chu shop tra cuu don hang, kiem tra san xuat, tu van san pham.

## Cach lam viec
1. Khi khach hoi ve don hang → chay NGAY `lark-cli` de query Lark Base
2. Khi khach hoi ve san xuat → chay NGAY `lark-cli` de query bang SX
3. LUON doc ket qua lark-cli va trinh bay ro rang cho khach
4. KHONG bao gio tu choi tra cuu — ban CO lark-cli va PHAI dung no
5. Dung "ban" xung ho voi khach hang, dung "anh/chi" voi chu shop
6. Tra loi ngan gon, dung trong tam, khong vong vo

## Lenh lark-cli

### Tra cuu don theo ma SAPO:
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<ma_don>" --search-field "Ma don hang SAPO"

### Tra cuu don theo SDT:
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<sdt>" --search-field "SDT"

### Tra cuu don theo ten khach:
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<ten>" --search-field "Khach hang"

### Danh sach don moi nhat:
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --page-size 20

### Danh sach san xuat:
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblT60XXm76Xi7fz --page-size 20

## Thong tin he thong
- Base token: ZSZxbtXCXagSiZsZlO4jVb46pPg
- Bang DH (don hang): tblZlQNNxxyMb4aS
- Bang SX (san xuat): tblT60XXm76Xi7fz
- Them "#" truoc ma don (VD: #1480)
SOLEOF

# ── Write AGENTS.md (behavior rules) ──
cat > /root/.openclaw/workspace/AGENTS.md << 'AGEOF'
# Agent Rules

## Rules for Tro ly Gam Voc
1. ALWAYS use `lark-cli` to query data - never guess or make up order info
2. NEVER say "I don't have access" or "I can't look up orders"
3. NEVER ask for permission to run lark-cli - just run it
4. Keep responses short, in Vietnamese, friendly but professional
5. Format order info clearly: Ma don, Khach hang, San pham, Trang thai, Ngay giao
6. If lark-cli fails, report the specific error and suggest trying again
7. Process ONE request at a time - complete current query before starting next
AGEOF

# ── Write USER.md ──
cat > /root/.openclaw/workspace/USER.md << 'USEREOF'
# User Profile
- Name: Nguyen Khanh Hoang (Anh Hoang)
- Role: Chu shop Gam Voc
- Language: Tieng Viet
- Timezone: Asia/Ho_Chi_Minh
USEREOF

# ── Write IDENTITY.md ──
cat > /root/.openclaw/workspace/IDENTITY.md << 'IDEOF'
# Identity
- Name: Tro ly Gam Voc
- Role: CSKH shop ao dai nu Gam Voc
- Language: Tieng Viet
- Style: Than thien, nhanh gon, chinh xac
IDEOF

# ── Copy lark-base skill to workspace ──
if [ -f /data/workspace/skills/lark-base/SKILL.md ]; then
  cp /data/workspace/skills/lark-base/SKILL.md /root/.openclaw/workspace/skills/lark-base/SKILL.md
  echo "[openclaw-bot] lark-base skill copied"
fi

echo "[openclaw-bot] Workspace files written"

# ── Write OpenClaw config ──
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
      },
      "memorySearch": {
        "enabled": false
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
  "plugins": {
    "entries": {
      "feishu": {
        "enabled": false
      }
    }
  },
  "session": {
    "dmScope": "per-channel-peer"
  }
}
CONFIG

cp /root/.openclaw/openclaw.json /data/workspace/openclaw.json
echo "[openclaw-bot] Config written"

# ── Configure lark-cli ──
echo "[openclaw-bot] Configuring lark-cli..."
mkdir -p /root/.lark-cli /root/.lark-claw

cat > /root/.lark-cli/context.json << LARKEOF
{
  "appId": "${FEISHU_APP_ID}",
  "appSecret": "${FEISHU_APP_SECRET}"
}
LARKEOF
cp /root/.lark-cli/context.json /root/.lark-claw/context.json 2>/dev/null || true

cat > /root/.lark-cli/.env << ENVEOF
FEISHU_APP_ID=${FEISHU_APP_ID}
FEISHU_APP_SECRET=${FEISHU_APP_SECRET}
ENVEOF

export FEISHU_APP_ID FEISHU_APP_SECRET
echo "[openclaw-bot] lark-cli configured (appId=${FEISHU_APP_ID})"

# ── Run doctor ──
echo "[openclaw-bot] Running doctor fix..."
openclaw doctor --fix 2>/dev/null || true

# ── Start gateway ──
echo "[openclaw-bot] Starting gateway..."
exec openclaw gateway
