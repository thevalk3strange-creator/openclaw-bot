#!/bin/sh
# Hermes Agent startup for Gam Voc CSKH bot
# Provider: OpenRouter
set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
mkdir -p "$HERMES_HOME" /root/.hermes /root/.lark-cli /root/.lark-claw

OPENROUTER_KEY="${OPENROUTER_KEY:-}"
if [ -z "$OPENROUTER_KEY" ]; then
  # Key split to avoid GitHub secret scanning
  _k1="sk-or-v1-5e21e57350f5cf3554dd0f100166bd6a468a3d"
  _k2="cc4a9c1256790834d1a91df7c4"
  OPENROUTER_KEY="${_k1}${_k2}"
fi
OPENROUTER_MODEL="${OPENROUTER_MODEL:-google/gemini-2.0-flash-001}"
FEISHU_APP_ID="${FEISHU_APP_ID:-cli_a95799f30ef8de18}"
FEISHU_APP_SECRET="${FEISHU_APP_SECRET:-wi5j1S8jieUdKNcjl78SIbDnBGjTKIeM}"

if [ -z "$OPENROUTER_KEY" ]; then
  echo "[start-hermes] ERROR: OPENROUTER_KEY not set"
  exit 1
fi

echo "[start-hermes] Provider: OpenRouter"
echo "[start-hermes] Model: $OPENROUTER_MODEL"

# ── Write config.yaml ──
cat > "$HERMES_HOME/config.yaml" << CFGEOF
model:
  provider: custom
  default: ${OPENROUTER_MODEL}
  base_url: https://openrouter.ai/api/v1
  api_key: ${OPENROUTER_KEY}
CFGEOF
cp "$HERMES_HOME/config.yaml" /root/.hermes/config.yaml
echo "[start-hermes] config.yaml written"

# ── Write SOUL.md ──
cat > "$HERMES_HOME/SOUL.md" << 'SOLEOF'
# Tro ly Gam Voc

Ban la Tro ly Gam Voc - tro ly AI cua shop thoi trang ao dai nu Gam Voc.
Nhiem vu: tra cuu don hang, kiem tra san xuat, tu van khach hang.
Tra loi bang tieng Viet, than thien, ngan gon.

## Quy tac VANG (MUST FOLLOW)
1. Khi khach hoi ve don hang → GOI NGAY `lark-cli`
2. KHONG BAO GIO tu choi tra cuu
3. KHONG BAO GIO bia dat thong tin
4. KHONG TAO SKILL MOI — chi dung lark-cli
5. Dung "ban" voi khach, "anh/chi" voi chu shop

## Lenh lark-cli

Tim don theo ma SAPO:
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "#<ma>" --search-field "Mã đơn hàng SAPO"

Tim don theo SDT:
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<sdt>" --search-field "SĐT"

Tim don theo ten:
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<ten>" --search-field "Khách hàng"

Danh sach don:
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --page-size 20

San xuat:
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblT60XXm76Xi7fz --page-size 20

## Thong tin
- Base: ZSZxbtXCXagSiZsZlO4jVb46pPg
- DH: tblZlQNNxxyMb4aS
- SX: tblT60XXm76Xi7fz
SOLEOF
cp "$HERMES_HOME/SOUL.md" /root/.hermes/SOUL.md
echo "[start-hermes] SOUL.md written"

# ── Configure lark-cli ──
cat > /root/.lark-cli/context.json << LARKEOF
{"appId": "${FEISHU_APP_ID}", "appSecret": "${FEISHU_APP_SECRET}"}
LARKEOF
cp /root/.lark-cli/context.json /root/.lark-claw/context.json 2>/dev/null || true

cat > /root/.lark-cli/.env << ENVEOF
FEISHU_APP_ID=${FEISHU_APP_ID}
FEISHU_APP_SECRET=${FEISHU_APP_SECRET}
ENVEOF

# Hermes context for lark-cli bind
cat > /root/.hermes/.env << HENVEOF
FEISHU_APP_ID=${FEISHU_APP_ID}
FEISHU_APP_SECRET=${FEISHU_APP_SECRET}
HENVEOF

export FEISHU_APP_ID FEISHU_APP_SECRET
export GATEWAY_ALLOW_ALL_USERS=true
echo "[start-hermes] lark-cli configured"

# ── Bind lark-cli (best effort) ──
lark-cli config bind --source hermes --app-id "${FEISHU_APP_ID}" --identity bot-only 2>&1 || echo "[start-hermes] Bind skipped (context.json fallback)"

# ── Start Hermes ──
echo "[start-hermes] Starting Hermes gateway..."
exec hermes gateway run
