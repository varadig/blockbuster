// A levels/*.tmx pont-objektumainak (Player, Enemy, Pickup, Shroom, Meteor, Meteorfall, Boss, End) cseréje csempe-objektumokra (levels/objects.tsj),
// hogy a Tiled-ben a játék sprite-jai látszódjanak. Idempotens: a már csempe-objektumokat nem bántja. A hely a sprite horgonyán marad (TiledSprites.anchor).
// Használat: node scripts/tiled-previews.js [levels-mappa]
const fs = require("fs");
const path = require("path");
const dir = path.resolve(process.argv[2] || path.join(__dirname, "..", "levels"));
const tsj = JSON.parse(fs.readFileSync(path.join(dir, "objects.tsj"), "utf8").replace(/^﻿/, ""));
const tiles = {};
for (const t of tsj.tiles) tiles[path.basename(t.image, ".png")] = { id: t.id, w: t.imagewidth, h: t.imageheight };
const ANCHOR = { Player: "b", Enemy: "b", Shroom: "b", Pickup: "c", Meteor: "c", Meteorfall: "c", Boss: "bl", End: "bl" };
const num = (n) => String(Math.round(n * 100) / 100);

function pickTile(cls, props) {
  const kind = (props.kind || "").toLowerCase();
  switch (cls) {
    case "Player": return "player";
    case "Enemy": return "enemy_" + kind;
    case "Pickup": return "pickup_" + kind;
    case "Shroom": return kind ? "shroom_" + kind : "shroom";
    case "Meteor": return props.reward && props.reward !== "NONE" ? "meteor_gold" : "meteor";
    case "Meteorfall": return "meteorfall";
    case "Boss": return "boss";
    case "End": return "end";
  }
  return null;
}

let prev = {};
try { prev = JSON.parse(fs.readFileSync(path.join(dir, "previews", "previews.json"), "utf8").replace(/^﻿/, "")); } catch (e) {}
let total = 0;
for (const f of fs.readdirSync(dir).filter((n) => n.endsWith(".tmx"))) {
  const p = path.join(dir, f);
  let txt = fs.readFileSync(p, "utf8");
  const bom = txt.charCodeAt(0) === 0xfeff;
  if (bom) txt = txt.slice(1);
  let n = 0;
  txt = txt.replace(/<object ([^>]*?)(\/?)>([\s\S]*?)(?:<\/object>|(?=<object |<\/objectgroup>))/g, (m, attrs, selfClose, body) => {
    if (selfClose || !/<point\s*\/>/.test(body)) return m;
    const a = {};
    attrs.replace(/(\w+)="([^"]*)"/g, (_, k, v) => (a[k] = v));
    const cls = a.class || a.type;
    if (!cls || !ANCHOR[cls]) return m;
    const props = {};
    body.replace(/<property name="([^"]+)"[^>]*value="([^"]*)"/g, (_, k, v) => (props[k] = v));
    const name = pickTile(cls, props);
    const tile = name && tiles[name];
    if (!tile) { console.warn(`${f}: #${a.id} ${cls}: nincs csempe (${name}), pont marad`); return m; }
    const x = parseFloat(a.x), y = parseFloat(a.y);
    const an = ANCHOR[cls];
    const tx = an === "bl" ? x : x - tile.w / 2;
    const ty = an === "c" ? y + tile.h / 2 : y;
    const rest = Object.keys(a).filter((k) => !["x", "y", "width", "height", "gid"].includes(k)).map((k) => `${k}="${a[k]}"`).join(" ");
    const newBody = body.replace(/\s*<point\s*\/>/, "");
    n++;
    const head = `<object ${rest} gid="${tile.id + 1}" x="${num(tx)}" y="${num(ty)}" width="${tile.w}" height="${tile.h}"`;
    return newBody.trim() === "" ? head + " />" : head + ">" + newBody + "</object>";
  });
  if (!/<tileset /.test(txt)) txt = txt.replace(/(<\/properties>\s*\n)/, `$1  <tileset firstgid="1" source="objects.tsj" />\n`);
  // talaj-előnézet: a játék festésével készült, zárolt háttér-képréteg (a téglalapok szerkesztése után a script újrafuttatásával frissül)
  const base = path.basename(f, ".tmx");
  if (prev[base]) {
    const img = '<image source="previews/' + base + '.png" width="' + prev[base].w + '" height="' + prev[base].h + '" />';
    if (/<imagelayer [^>]*name="terrain preview/.test(txt)) {
      txt = txt.replace(/(<imagelayer [^>]*name="terrain preview[^>]*>\s*)<image [^>]*\/>/, (m0, g1) => g1 + img);
    } else {
      const m = txt.match(/nextlayerid="(\d+)"/);
      const id = m ? parseInt(m[1], 10) : 99;
      txt = txt.replace(/nextlayerid="\d+"/, 'nextlayerid="' + (id + 1) + '"');
      txt = txt.replace(/(\r?\n\s*)<objectgroup /, (m0, ws) => ws + '<imagelayer id="' + id + '" name="terrain preview (auto - refresh: tiled-previews)" locked="1">' + ws + "  " + img + ws + "</imagelayer>" + ws + "<objectgroup ");
    }
  }
  fs.writeFileSync(p, (bom ? "\uFEFF" : "") + txt);
  console.log(`${f}: ${n} objektum csempére cserélve`);
  total += n;
}
console.log(`összesen: ${total}`);
