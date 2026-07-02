#!/usr/bin/env node
// Gam Voc CSKH Bot - standalone Telegram bot with direct Lark API
// No LLM dependency, no tool calling needed. Just works.
const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '8673157236:AAEYeFjsglFvGQLyk6Ybs1lm9yQSNjkV1KQ';
const FEISHU_APP_ID = process.env.FEISHU_APP_ID || 'cli_a95799f30ef8de18';
const FEISHU_APP_SECRET = process.env.FEISHU_APP_SECRET || 'wi5j1S8jieUdKNcjl78SIbDnBGjTKIeM';
const BASE_TOKEN = 'ZSZxbtXCXagSiZsZlO4jVb46pPg';
const TABLE_DH = 'tblZlQNNxxyMb4aS';
const TELEGRAM_API = `https://api.telegram.org/bot${TELEGRAM_TOKEN}`;

let larkToken = null, larkTokenExpiry = 0;
let lastUpdateId = 0;

async function getLarkToken() {
  if (larkToken && Date.now() < larkTokenExpiry) return larkToken;
  const resp = await fetch('https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ app_id: FEISHU_APP_ID, app_secret: FEISHU_APP_SECRET }),
  });
  const data = await resp.json();
  if (data.code !== 0) throw new Error(`Lark auth: ${data.msg}`);
  larkToken = data.tenant_access_token;
  larkTokenExpiry = Date.now() + (data.expire - 300) * 1000;
  return larkToken;
}

async function searchOrders(field, keyword, table = TABLE_DH) {
  const token = await getLarkToken();
  const resp = await fetch(
    `https://open.feishu.cn/open-apis/bitable/v1/apps/${BASE_TOKEN}/tables/${table}/records/search`,
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        filter: { conjunction: 'and', conditions: [{ field_name: field, operator: 'is', value: [keyword] }] },
        page_size: 5,
      }),
    }
  );
  return resp.json();
}

async function listOrders(table = TABLE_DH) {
  const token = await getLarkToken();
  const resp = await fetch(
    `https://open.feishu.cn/open-apis/bitable/v1/apps/${BASE_TOKEN}/tables/${table}/records?page_size=10`,
    { headers: { 'Authorization': `Bearer ${token}` } }
  );
  return resp.json();
}

function formatOrder(r) {
  const f = r.fields;
  const getText = (v) => Array.isArray(v) ? v.map(x => typeof x === 'object' ? x.text : x).join(', ') : (v || '');
  return [
    `📦 Mã đơn: ${getText(f['Mã đơn hàng SAPO'])}`,
    `👤 Khách: ${getText(f['Khách hàng'])}`,
    `📞 SĐT: ${getText(f['SĐT'])}`,
    `📝 Ghi chú: ${getText(f['Ghi chú'])}`,
    f['Hẹn giao'] ? `📅 Hẹn giao: ${new Date(f['Hẹn giao']).toLocaleDateString('vi-VN')}` : '',
  ].filter(Boolean).join('\n');
}

async function handleOrderLookup(chatId, query) {
  // Try order number
  const maDon = query.match(/#?(\d{3,6})/);
  if (maDon) {
    const kw = `#${maDon[1]}`;
    const result = await searchOrders('Mã đơn hàng SAPO', kw);
    if (result.data?.items?.length > 0) {
      const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
      await sendMessage(chatId, `✅ Tìm thấy ${result.data.items.length} đơn:\n\n${items}`);
      return;
    }
    await sendMessage(chatId, `❌ Không tìm thấy đơn ${kw}`);
    return;
  }

  // Try phone number
  const sdt = query.match(/(\d{9,11})/);
  if (sdt) {
    const result = await searchOrders('SĐT', sdt[1]);
    if (result.data?.items?.length > 0) {
      const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
      await sendMessage(chatId, `✅ Tìm thấy ${result.data.items.length} đơn cho SĐT ${sdt[1]}:\n\n${items}`);
      return;
    }
    await sendMessage(chatId, `❌ Không tìm thấy đơn với SĐT ${sdt[1]}`);
    return;
  }

  await sendMessage(chatId, `🤔 Gấm Vóc chưa hiểu yêu cầu. Bạn thử:\n- tìm đơn #1480\n- tìm SĐT 0918400072\n- danh sách đơn\n- sản xuất`);
}

async function sendMessage(chatId, text) {
  await fetch(`${TELEGRAM_API}/sendMessage`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text, parse_mode: 'HTML' }),
  });
}

async function processMessage(msg) {
  const chatId = msg.chat.id;
  const text = (msg.text || '').toLowerCase().trim();
  if (!text) return;

  try {
    if (text.match(/t[iì]m\s*(đơn|don|hàng|hang).*#?\d{3,6}/) || text.match(/tra\s*cứu.*#?\d{3,6}/)) {
      await handleOrderLookup(chatId, msg.text);
    } else if (text.match(/t[iì]m\s*(sđt|sdt|số\s*điện\s*thoại)/) || text.match(/\d{9,11}/)) {
      await handleOrderLookup(chatId, msg.text);
    } else if (text.match(/danh\s*s[aá]ch\s*đơn|đơn\s*hàng\s*gần|đơn\s*mới|list|ds\s*đơn/)) {
      const result = await listOrders();
      if (result.data?.items?.length > 0) {
        const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
        await sendMessage(chatId, `📋 Đơn hàng gần đây:\n\n${items}`);
      } else {
        await sendMessage(chatId, '📋 Chưa có đơn hàng nào.');
      }
    } else if (text.match(/sản\s*xuất|sx|production/)) {
      const result = await listOrders('tblT60XXm76Xi7fz');
      if (result.data?.items?.length > 0) {
        const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
        await sendMessage(chatId, `🏭 Sản xuất gần đây:\n\n${items}`);
      } else {
        await sendMessage(chatId, '🏭 Chưa có đơn sản xuất nào.');
      }
    } else if (text.match(/hi|hello|chào|xin chào|alo|bạn\s*là\s*ai/)) {
      await sendMessage(chatId, 'Chào bạn! 👋\n\nMình là Trợ lý Gấm Vóc - trợ lý CSKH của shop áo dài nữ Gấm Vóc.\n\nMình có thể giúp bạn:\n• Tra cứu đơn hàng (#mã đơn)\n• Tìm đơn theo SĐT\n• Xem danh sách đơn mới\n• Kiểm tra sản xuất\n\nBạn cần gì ạ?');
    } else {
      await sendMessage(chatId, 'Mình là Trợ lý Gấm Vóc. Bạn có thể:\n• tìm đơn #1480\n• tìm SĐT 0918400072\n• danh sách đơn\n• sản xuất');
    }
  } catch (e) {
    await sendMessage(chatId, `❌ Lỗi: ${e.message}. Vui lòng thử lại.`);
  }
}

async function main() {
  console.log('[gamvoc-bot] Starting Gam Voc CSKH bot...');
  console.log('[gamvoc-bot] Bot: @trolygamvocbot');

  while (true) {
    try {
      const resp = await fetch(`${TELEGRAM_API}/getUpdates?offset=${lastUpdateId + 1}&timeout=30`);
      const data = await resp.json();
      if (!data.ok) { await new Promise(r => setTimeout(r, 2000)); continue; }

      for (const update of data.result) {
        lastUpdateId = update.update_id;
        if (update.message?.text) {
          console.log(`[gamvoc-bot] ${update.message.from?.first_name}: ${update.message.text}`);
          await processMessage(update.message);
        }
      }
    } catch (e) {
      console.error('[gamvoc-bot] Error:', e.message);
      await new Promise(r => setTimeout(r, 5000));
    }
  }
}

main();
