#!/usr/bin/env node
// Gam Voc CSKH Bot - Hybrid: Pattern matching + AI Box LLM for natural language
const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '8673157236:AAEYeFjsglFvGQLyk6Ybs1lm9yQSNjkV1KQ';
const FEISHU_APP_ID = process.env.FEISHU_APP_ID || 'cli_a95799f30ef8de18';
const FEISHU_APP_SECRET = process.env.FEISHU_APP_SECRET || 'wi5j1S8jieUdKNcjl78SIbDnBGjTKIeM';
const AI_BOX_KEY = process.env.AI_BOX_KEY || 'sk-V34DDrtMOcHX8ZiRuhS2Hq8BmgWzKVZp4VtwlWCHJC4caJPS';
const AI_BOX_URL = process.env.AI_BOX_URL || 'https://api.ai-box.vn/v1';
const BASE_TOKEN = 'ZSZxbtXCXagSiZsZlO4jVb46pPg';
const TABLE_DH = 'tblZlQNNxxyMb4aS';
const TELEGRAM_API = `https://api.telegram.org/bot${TELEGRAM_TOKEN}`;

let larkToken = null, larkTokenExpiry = 0, lastUpdateId = 0;

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
    { method: 'POST', headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ filter: { conjunction: 'and', conditions: [{ field_name: field, operator: 'is', value: [keyword] }] }, page_size: 10 }) }
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

function getText(v) { return Array.isArray(v) ? v.map(x => typeof x === 'object' ? x.text : x).join(', ') : (v || ''); }

function formatOrder(r) {
  const f = r.fields;
  return [`📦 Mã: ${getText(f['Mã đơn hàng SAPO'])}`, `👤 Khách: ${getText(f['Khách hàng'])}`, `📞 SĐT: ${getText(f['SĐT'])}`, `📝 Ghi chú: ${getText(f['Ghi chú'])}`, f['Hẹn giao'] ? `📅 Hẹn giao: ${new Date(f['Hẹn giao']).toLocaleDateString('vi-VN')}` : '', f['Ngày tạo (Date Created)'] ? `📅 Ngày tạo: ${new Date(f['Ngày tạo (Date Created)']).toLocaleDateString('vi-VN')}` : ''].filter(Boolean).join('\n');
}

async function sendMessage(chatId, text) {
  // Split long messages
  const MAX = 4000;
  if (text.length <= MAX) {
    await fetch(`${TELEGRAM_API}/sendMessage`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ chat_id: chatId, text }) });
    return;
  }
  const parts = text.match(new RegExp(`[\\s\\S]{1,${MAX}}`, 'g')) || [text];
  for (const p of parts) {
    await fetch(`${TELEGRAM_API}/sendMessage`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ chat_id: chatId, text: p }) });
  }
}

// ── AI Box LLM for natural language understanding ──
async function askLLM(userMessage) {
  const systemPrompt = `Ban la tro ly CSKH cua shop ao dai Gam Voc. Nguoi dung nhap: "${userMessage}".
Hay xac dinh y dinh va tra ve JSON (CHI JSON, khong text khac):
- Tim don theo ma: {"action":"search","field":"Mã đơn hàng SAPO","keyword":"#XXX"}
- Tim don theo SDT: {"action":"search","field":"SĐT","keyword":"XXX"}
- Tim don theo ten: {"action":"search","field":"Khách hàng","keyword":"XXX"}
- Xem danh sach don: {"action":"list"}
- Xem san xuat: {"action":"list_sx"}
- Chào hỏi/không rõ: {"action":"chat","reply":"cau tra loi ngan gon bang tieng Viet"}`;

  const resp = await fetch(`${AI_BOX_URL}/v1/chat/completions`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${AI_BOX_KEY}` },
    body: JSON.stringify({ model: 'deepseek-v4-flash', messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userMessage }], max_tokens: 300, temperature: 0 }),
  });
  const data = await resp.json();
  return (data.choices?.[0]?.message?.content || '').trim();
}

async function handleLLMResponse(chatId, llmOutput, originalText) {
  try {
    // Extract JSON from LLM output (may have markdown wrappers)
    const jsonMatch = llmOutput.match(/\{[\s\S]*\}/);
    if (!jsonMatch) { await sendMessage(chatId, 'Mình là Trợ lý Gấm Vóc. Bạn cần tra cứu đơn hàng, SĐT, hay xem danh sách?'); return; }

    const cmd = JSON.parse(jsonMatch[0]);

    if (cmd.action === 'search') {
      const result = await searchOrders(cmd.field, cmd.keyword);
      if (result.data?.items?.length > 0) {
        const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
        await sendMessage(chatId, `✅ Tìm thấy ${result.data.items.length} kết quả:\n\n${items}`);
      } else {
        await sendMessage(chatId, `❌ Không tìm thấy kết quả cho "${cmd.keyword}"`);
      }
    } else if (cmd.action === 'list' || cmd.action === 'list_sx') {
      const table = cmd.action === 'list_sx' ? 'tblT60XXm76Xi7fz' : TABLE_DH;
      const result = await listOrders(table);
      if (result.data?.items?.length > 0) {
        const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
        await sendMessage(chatId, `${cmd.action === 'list_sx' ? '🏭 Sản xuất' : '📋 Đơn hàng'} gần đây:\n\n${items}`);
      } else {
        await sendMessage(chatId, 'Chưa có dữ liệu.');
      }
    } else if (cmd.action === 'chat') {
      await sendMessage(chatId, cmd.reply || 'Mình là Trợ lý Gấm Vóc. Bạn cần tra cứu gì ạ?');
    } else {
      await sendMessage(chatId, 'Mình là Trợ lý Gấm Vóc. Bạn cần tra cứu đơn hàng, SĐT, hay xem danh sách?');
    }
  } catch (e) {
    await sendMessage(chatId, 'Mình là Trợ lý Gấm Vóc. Bạn cần tra cứu gì ạ?\n• tìm đơn #1480\n• tìm SĐT 0918400072\n• danh sách đơn\n• sản xuất');
  }
}

// ── Pattern matching for fast common queries ──
function matchPattern(text) {
  const lower = text.toLowerCase().trim();

  // Order number
  const maDon = text.match(/#?(\d{3,6})/);
  if (maDon && lower.match(/t[iì]m|tra|đơn|don|hàng|hang|ki[eể]m|tim|kiem|kiếm/)) {
    return { matched: true, action: 'search', field: 'Mã đơn hàng SAPO', keyword: `#${maDon[1]}` };
  }

  // Phone number
  const sdt = text.match(/(\d{9,11})/);
  if (sdt && !maDon) {
    return { matched: true, action: 'search', field: 'SĐT', keyword: sdt[1] };
  }

  // List orders
  if (lower.match(/danh\s*s[aá]ch|đơn\s*hàng|đơn\s*mới|list|ds\s*đơn|gần\s*đây|tu[aà]n\s*này/)) {
    return { matched: true, action: 'list' };
  }

  // Production
  if (lower.match(/sản\s*xuất|sx\b|production|đang\s*làm|đang\s*may/)) {
    return { matched: true, action: 'list_sx' };
  }

  // Greeting
  if (lower.match(/^(hi|hello|chào|xin chào|alo|bạn\s*là\s*ai|hey)$/) || lower.length < 5) {
    return { matched: true, action: 'chat', reply: 'Chào bạn! 👋 Mình là Trợ lý Gấm Vóc - CSKH shop áo dài nữ Gấm Vóc.\n\nMình có thể:\n• Tra cứu đơn hàng (gửi mã đơn)\n• Tìm đơn theo SĐT\n• Xem danh sách đơn mới\n• Kiểm tra sản xuất\n\nBạn cần gì ạ?' };
  }

  return { matched: false };
}

async function processMessage(msg) {
  const chatId = msg.chat.id;
  const text = (msg.text || '').trim();
  if (!text) return;

  console.log(`[gamvoc-bot] ${msg.from?.first_name}: ${text}`);

  try {
    // 1. Try fast pattern matching
    const pattern = matchPattern(text);
    if (pattern.matched) {
      if (pattern.action === 'search') {
        const result = await searchOrders(pattern.field, pattern.keyword);
        if (result.data?.items?.length > 0) {
          const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
          await sendMessage(chatId, `✅ Tìm thấy ${result.data.items.length} kết quả:\n\n${items}`);
        } else {
          await sendMessage(chatId, `❌ Không tìm thấy "${pattern.keyword}"`);
        }
      } else if (pattern.action === 'list' || pattern.action === 'list_sx') {
        const table = pattern.action === 'list_sx' ? 'tblT60XXm76Xi7fz' : TABLE_DH;
        const result = await listOrders(table);
        if (result.data?.items?.length > 0) {
          const items = result.data.items.map(formatOrder).join('\n\n───\n\n');
          await sendMessage(chatId, `${pattern.action === 'list_sx' ? '🏭 Sản xuất' : '📋 Đơn hàng'} gần đây:\n\n${items}`);
        } else {
          await sendMessage(chatId, 'Chưa có dữ liệu.');
        }
      } else if (pattern.action === 'chat') {
        await sendMessage(chatId, pattern.reply);
      }
      return;
    }

    // 2. No pattern match — use LLM for understanding
    await sendMessage(chatId, '🔍 Đang xử lý yêu cầu của bạn...');
    const llmOutput = await askLLM(text);
    console.log(`[gamvoc-bot] LLM: ${llmOutput}`);
    await handleLLMResponse(chatId, llmOutput, text);

  } catch (e) {
    console.error('[gamvoc-bot] Error:', e.message);
    await sendMessage(chatId, `❌ Lỗi: ${e.message}. Vui lòng thử lại.`);
  }
}

async function main() {
  console.log('[gamvoc-bot] Starting Gam Voc CSKH bot (hybrid mode)...');
  while (true) {
    try {
      const resp = await fetch(`${TELEGRAM_API}/getUpdates?offset=${lastUpdateId + 1}&timeout=30`);
      const data = await resp.json();
      if (!data.ok) { await new Promise(r => setTimeout(r, 2000)); continue; }
      for (const update of data.result) {
        lastUpdateId = update.update_id;
        if (update.message?.text) await processMessage(update.message);
      }
    } catch (e) {
      console.error('[gamvoc-bot] Poll error:', e.message);
      await new Promise(r => setTimeout(r, 5000));
    }
  }
}

main();
