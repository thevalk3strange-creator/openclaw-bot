# OpenClaw CSKH Bot - Gấm Vóc

Bot CSKH cho shop thời trang áo dài nữ Gấm Vóc, sử dụng OpenClaw với Telegram.

## Tính năng

- Tra cứu đơn hàng từ Lark Base
- Tư vấn sản phẩm
- Theo dõi trạng thái giao hàng
- Phản hồi nhanh chóng trên Telegram

## Cài đặt

### Yêu cầu
- Railway account
- GitHub account
- Telegram Bot Token (từ @BotFather)
- AI API Key (Anthropic hoặc OpenAI)

### Deploy lên Railway

1. Clone repo này
2. Push lên GitHub
3. Deploy trên Railway từ GitHub repo
4. Set environment variables:
   - `TELEGRAM_BOT_TOKEN`: Token của bot Telegram
   - `ANTHROPIC_API_KEY`: API key cho AI model

### Local development

```bash
# Install dependencies
npm install -g openclaw
npm install -g @larksuite/cli

# Run locally
./start.sh
```

## Cấu trúc

```
openclaw-bot/
├── Dockerfile          # Docker image cho Railway
├── start.sh           # Script khởi động OpenClaw
├── railway.json       # Cấu hình Railway
└── README.md          # Tài liệu
```

## Environment Variables

| Variable | Mô tả | Mặc định |
|----------|--------|----------|
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | - |
| `ANTHROPIC_API_KEY` | Anthropic API key | - |

## Liên hệ

- Bot Telegram: @trolygamvocbot
- Shop: Gấm Vóc - Thời trang áo dài nữ
