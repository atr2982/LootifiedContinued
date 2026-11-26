#!/usr/bin/env node
// Build a local, packaged ForeverDB snapshot. The API key is read only from
// FOREVERDB_API_KEY and is never written to the repository or generated Lua.
const fs = require("fs");

const key = process.env.FOREVERDB_API_KEY;
const output = process.argv[2];
if (!key || !output) throw new Error("Usage: FOREVERDB_API_KEY=... node fetch_foreverdb.js OUTPUT_LUA");

const base = "https://foreverdb.net/api/v1/";
async function get(path) {
  for (let attempt = 0; attempt < 6; attempt++) {
    let res;
    try {
      res = await fetch(base + path, { headers: { "X-API-Key": key, Accept: "application/json" } });
    } catch (error) {
      if (attempt === 5) throw new Error(`${path}: network retries exhausted (${error.cause?.code || error.message})`);
      await new Promise(resolve => setTimeout(resolve, (attempt + 1) * 3000));
      continue;
    }
    if (res.ok) return res.json();
    if (res.status === 402) throw new Error(`${path}: HTTP 402 subscription_required (ForeverDB daily limit or subscription tier reached)`);
    if (res.status !== 429 && res.status < 500) throw new Error(`${path}: HTTP ${res.status}`);
    const retry = Number(res.headers.get("retry-after")) || (attempt + 1) * 5;
    await new Promise(resolve => setTimeout(resolve, Math.max(5000, retry * 1000)));
  }
  throw new Error(`${path}: retries exhausted`);
}

async function list(kind) {
  const first = await get(`${kind}?limit=100&offset=0`);
  const out = [...(first.data || [])];
  const total = Number(first.meta?.total || out.length);
  for (let offset = out.length; offset < total; offset += 100) {
    // Keep paginated snapshot requests below the account-wide 30 requests/minute limit.
    await new Promise(resolve => setTimeout(resolve, 2050));
    const page = await get(`${kind}?limit=100&offset=${offset}`);
    out.push(...(page.data || []));
    if (offset % 2500 === 0 || offset + 100 >= total) console.log(`${kind}: ${Math.min(out.length, total)}/${total}`);
  }
  return out;
}

function luaKey(k) { return /^\d+$/.test(String(k)) ? `[${k}]` : /^[A-Za-z_][A-Za-z0-9_]*$/.test(String(k)) ? String(k) : `[${JSON.stringify(String(k))}]`; }
function lua(v, depth = 0) {
  if (v == null) return "nil";
  if (typeof v === "string") return JSON.stringify(v);
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  const pad = " ".repeat(depth), child = " ".repeat(depth + 4);
  if (Array.isArray(v)) return v.length ? `{\n${v.map(x => child + lua(x, depth + 4)).join(",\n")}\n${pad}}` : "{}";
  return Object.keys(v).length ? `{\n${Object.entries(v).map(([k, x]) => child + luaKey(k) + " = " + lua(x, depth + 4)).join(",\n")}\n${pad}}` : "{}";
}

const CLASS_CATEGORIES = new Map([
  "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior",
].map(name => [name.toLowerCase(), name]));

function checkedDate() {
  const parts = Object.fromEntries(new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Chicago", year: "numeric", month: "2-digit", day: "2-digit",
  }).formatToParts(new Date()).map(part => [part.type, part.value]));
  return `${parts.year}-${parts.month}-${parts.day}`;
}

function questRow(q) {
  const row = { name: q.name, level: q.level, min: q.requiredLevel, side: q.side ? q.side.toUpperCase() : undefined, src: q.source };
  const category = typeof q.category === "string" ? q.category.trim() : "";
  const className = CLASS_CATEGORIES.get(category.toLowerCase());
  if (className) row.classes = [className];
  else if (category) row.zone = category;
  if (q.zone?.m) row.map = q.zone.m;
  if (q.starts?.name) row.startText = `${q.starts.name}${q.starts.location?.zone ? ", " + q.starts.location.zone : ""}`;
  if (q.ends?.name) row.finishText = `${q.ends.name}${q.ends.location?.zone ? ", " + q.ends.location.zone : ""}`;
  return row;
}

(async () => {
  const meta = await get("meta");
  const items = await list("items");
  const quests = await list("quests");
  const dungeons = await list("dungeons");
  const payload = { build: meta.data.build, attribution: meta.data.attribution, items: {}, quests: {}, dungeons: {} };
  for (const item of items) payload.items[item.id] = {
    name: item.name, quality: item.qualityId, level: item.itemLevel, min: item.requiredLevel,
    classId: item.classId, subclassId: item.subclassId, inventoryTypeId: item.inventoryTypeId,
    betaEvent: !!item.betaEvent, speculation: !!item.speculation,
  };
  for (const quest of quests) payload.quests[quest.id] = questRow(quest);
  for (const dungeon of dungeons) payload.dungeons[dungeon.id] = {
    name: dungeon.name, kind: dungeon.kind, players: dungeon.players, level: dungeon.level,
    range: dungeon.levelRange, status: dungeon.status, newInForever: !!dungeon.newInForever,
  };
  const merge = `
local _, LJ = ...
LJ.Data = LJ.Data or {}
LJ.Data.ForeverDB = ${lua(payload)}
LJ.DATA_BUILD = LJ.Data.ForeverDB.build
LJ.DATA_CHECKED = ${JSON.stringify(checkedDate())}
LJ.DATA_STATUS = "ForeverDB snapshot packaged; client collection remains authoritative for tooltip stats"
LJ.DATA_SOURCES = { "https://foreverdb.net" }
local D = LJ.Data.ForeverDB
for id, item in pairs(D.items) do
    local prior = LJ.Data.Items[id]
    if type(prior) == "string" then
        local _, tail = prior:match("^(.-)(|.*)$")
        LJ.Data.Items[id] = item.name .. (tail or "||")
    else
        LJ.Data.Items[id] = item.name .. "||"
    end
end
for id, fresh in pairs(D.quests) do
    local q = LJ.Data.Quests[id]
    if q then
        -- This catalog is sparse: nil means “not in this snapshot,” not “erase
        -- the reviewed Forever-specific value.”
        q.name = fresh.name or q.name
        q.level = fresh.level or q.level
        if fresh.min ~= nil then q.min = fresh.min end
        if fresh.side ~= nil then q.side = fresh.side end
        q.src = fresh.src or q.src
        q.startText = q.startText or fresh.startText
        q.finishText = q.finishText or fresh.finishText
        if fresh.classes then
            q.classes = fresh.classes
            if type(q.zone) == "string" and string.lower(q.zone) == string.lower(fresh.classes[1]) then q.zone = nil end
        elseif fresh.zone then
            q.zone = fresh.zone
        end
    else
        LJ.Data.Quests[id] = fresh
    end
end
`;
  fs.mkdirSync(require("path").dirname(output), { recursive: true });
  fs.writeFileSync(output, `-- Generated from ForeverDB.net build ${payload.build}.\n${merge}`, "utf8");
  console.log(JSON.stringify({ build: payload.build, items: items.length, quests: quests.length, dungeons: dungeons.length, output }));
})().catch(err => { console.error(err.message); process.exit(1); });
