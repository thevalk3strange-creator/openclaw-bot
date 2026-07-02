#!/usr/bin/env node
// Lark Base lookup for Gam Voc — direct API, no bind needed
const FEISHU_APP_ID = process.env.FEISHU_APP_ID || 'cli_a95799f30ef8de18';
const FEISHU_APP_SECRET = process.env.FEISHU_APP_SECRET || 'wi5j1S8jieUdKNcjl78SIbDnBGjTKIeM';
const BASE_TOKEN = 'ZSZxbtXCXagSiZsZlO4jVb46pPg';
const TABLE_DH = 'tblZlQNNxxyMb4aS';
const TABLE_SX = 'tblT60XXm76Xi7fz';

function log(msg) { if (process.env.LARK_DEBUG) process.stderr.write(`[lark-lookup] ${msg}\n`); }

const args = process.argv.slice(2);
const getArg = (name) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : null; };

const command = args[0];
const searchField = getArg('--field');
const keyword = getArg('--keyword');
const table = getArg('--table') === 'sx' ? TABLE_SX : TABLE_DH;
const pageSize = parseInt(getArg('--page-size') || '10');

log(`command=${command} field=${searchField} keyword=${keyword} table=${table}`);

async function getToken() {
  log('Getting tenant_access_token...');
  const resp = await fetch('https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ app_id: FEISHU_APP_ID, app_secret: FEISHU_APP_SECRET }),
  });
  if (!resp.ok) throw new Error(`Auth HTTP ${resp.status}`);
  const data = await resp.json();
  if (data.code !== 0) throw new Error(`Auth failed: ${data.msg} (code ${data.code})`);
  log('Token obtained');
  return data.tenant_access_token;
}

async function searchRecords(token, field, kw) {
  log(`Searching records: field="${field}" keyword="${kw}"`);
  const resp = await fetch(
    `https://open.feishu.cn/open-apis/bitable/v1/apps/${BASE_TOKEN}/tables/${table}/records/search`,
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        filter: { conjunction: 'and', conditions: [{ field_name: field, operator: 'is', value: [kw] }] },
        page_size: pageSize,
      }),
    }
  );
  if (!resp.ok) throw new Error(`Search HTTP ${resp.status}`);
  return resp.json();
}

async function listRecords(token) {
  log(`Listing records from table=${table} page_size=${pageSize}`);
  const resp = await fetch(
    `https://open.feishu.cn/open-apis/bitable/v1/apps/${BASE_TOKEN}/tables/${table}/records?page_size=${pageSize}`,
    { headers: { 'Authorization': `Bearer ${token}` } }
  );
  if (!resp.ok) throw new Error(`List HTTP ${resp.status}`);
  return resp.json();
}

(async () => {
  try {
    const token = await getToken();
    let result;
    if (command === 'search' && searchField && keyword) {
      result = await searchRecords(token, searchField, keyword);
    } else if (command === 'list') {
      result = await listRecords(token);
    } else {
      console.log(JSON.stringify({ error: 'Usage: lark-lookup search --field <f> --keyword <kw> [--table sx] OR lark-lookup list [--table sx] [--page-size 20]' }));
      process.exit(1);
    }

    if (result.code !== 0) {
      console.log(JSON.stringify({ error: `Lark API error: ${result.msg} (code ${result.code})` }));
      process.exit(1);
    }

    const items = result.data?.items || [];
    if (items.length === 0) {
      console.log(JSON.stringify({ message: 'Không tìm thấy kết quả', total: 0 }));
      process.exit(0);
    }

    const fields = items.map(r => r.fields);
    console.log(JSON.stringify({ total: result.data?.total || items.length, records: fields }));
  } catch (e) {
    console.log(JSON.stringify({ error: e.message }));
    process.exit(1);
  }
})();
