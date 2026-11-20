// Moonshard fejlesztői szerver (függőség nélküli Node): statikus kiszolgálás az export/html5/bin mappából + élő napló a böngészőtől.
//   node scripts/devserver.js <mappa> [port]
// A böngésző a `?log=1` URL-paraméterrel a `POST /__log` végpontra küldi a méréseit (Perf.hx), amiket itt színesen kiírunk.
// A serve-lan.ps1 a lime csomagolt node-jával indítja (0.0.0.0-n, így telefonról is elérhető).
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.argv[2] || 'export/html5/bin');
const port = parseInt(process.argv[3] || '3000', 10);

const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.json': 'application/json', '.png': 'image/png',
  '.css': 'text/css', '.ico': 'image/x-icon', '.wav': 'audio/wav', '.mp3': 'audio/mpeg', '.ogg': 'audio/ogg', '.svg': 'image/svg+xml',
  '.woff': 'font/woff', '.woff2': 'font/woff2', '.ttf': 'font/ttf', '.map': 'application/json', '.xml': 'application/xml',
};

// Napló fájlba is: logs/phone.log (olvasható szöveg, színek nélkül) és logs/phone.jsonl (nyers üzenetek soronként). Indításkor új fájl,
// a régit a phone.prev.log őrzi meg. Így a naplót utólag is el lehet olvasni / elemezni (pl. Claude Code).
const logDir = process.env.MOONSHARD_LOG_DIR || path.resolve(__dirname, '..', 'logs');
fs.mkdirSync(logDir, { recursive: true });
const textPath = path.join(logDir, 'phone.log'), jsonPath = path.join(logDir, 'phone.jsonl');
try { if (fs.existsSync(textPath)) fs.copyFileSync(textPath, path.join(logDir, 'phone.prev.log')); } catch (e) {}
fs.writeFileSync(textPath, '');
fs.writeFileSync(jsonPath, '');
const strip = (s) => s.replace(/\x1b\[[0-9;]*m/g, '');
// A console.log kimenetét a fájlba is tükrözzük (a színkódok nélkül)
const origLog = console.log.bind(console);
console.log = (...args) => {
  origLog(...args);
  try { fs.appendFileSync(textPath, strip(args.join(' ')) + '\n'); } catch (e) {}
};

const c = { reset: '\x1b[0m', dim: '\x1b[2m', red: '\x1b[31m', green: '\x1b[32m', yellow: '\x1b[33m', cyan: '\x1b[36m', magenta: '\x1b[35m', bold: '\x1b[1m' };

// Egy eszköz azonosítója a naplóban: az IP utolsó része (a telefon és a gép megkülönböztetésére)
function who(req) {
  const a = (req.socket.remoteAddress || '').replace('::ffff:', '');
  return a === '127.0.0.1' || a === '::1' ? 'local' : a;
}

function stamp() {
  const d = new Date();
  return d.toTimeString().slice(0, 8) + '.' + String(d.getMilliseconds()).padStart(3, '0');
}

function color(v, warn, bad, invert) {
  // invert: kisebb = rosszabb (fps)
  const w = invert ? v < warn : v > warn, b = invert ? v < bad : v > bad;
  return b ? c.red : (w ? c.yellow : c.green);
}

function printLog(req, msg) {
  const id = c.dim + stamp() + c.reset + ' ' + c.cyan + who(req) + c.reset + ' ';
  const d = msg.data || {};
  switch (msg.kind) {
    case 'hello':
      console.log(id + c.bold + c.magenta + 'CONNECTED ' + c.reset + d.ua);
      console.log('    screen ' + d.screen + '  inner ' + d.inner + '  dpr ' + d.dpr + '  touchPoints ' + d.touchPoints);
      console.log('    canvas ' + JSON.stringify(d.canvas));
      console.log('    ' + c.dim + d.url + c.reset);
      break;
    case 'perf': {
      const g = d.game || {};
      let extra = g.state ? g.state : '';
      if (g.level !== undefined) extra += ' L' + g.level + ' ' + g.levelState + ' blocks ' + g.blocks + ' debris ' + g.debris + ' enemies ' + g.enemies + ' bullets ' + g.bullets + (g.sub ? ' [menu]' : '');
      console.log(
        id +
          color(d.fps, 50, 30, true) + String(d.fps).padStart(3) + ' fps' + c.reset +
          '  avg ' + String(d.avg).padStart(5) +
          '  worst ' + color(d.worst, 40, 80, false) + String(d.worst).padStart(6) + c.reset +
          '  slow ' + (d.slow ? c.yellow : c.dim) + d.slow + c.reset +
          '  upd ' + color(d.upd, 8, 14, false) + String(d.upd).padStart(5) + c.reset +
          '  drw ' + color(d.drw, 8, 14, false) + String(d.drw).padStart(5) + c.reset +
          '  gap ' + color(d.gap, 8, 20, false) + d.gap + c.reset + '  ev ' + d.ev + '  actx ' + d.actx + '  filters ' + d.filters + '  snd ' + (d.nosfx ? 'OFF' : d.aud) + (d.lite ? ' LITE' : '') + '  ' + c.dim + extra + c.reset
      );
      break;
    }
    case 'audiotest':
      console.log(id + c.bold + c.magenta + 'AUDIOTEST ' + c.reset + (d.msg || ''));
      break;
    case 'canvas':
      console.log(id + c.magenta + 'CANVAS ' + c.reset + JSON.stringify(d));
      break;
    case 'resize':
      console.log(id + c.dim + 'resize ' + JSON.stringify(d) + c.reset);
      break;
    case 'error':
      console.log(id + c.bold + c.red + 'JS ERROR ' + c.reset + (d.msg || '') + (d.src ? ' (' + d.src + ':' + d.line + ')' : '') + (d.stack ? '\n' + d.stack : ''));
      break;
    default:
      console.log(id + c.yellow + msg.kind + c.reset + ' ' + JSON.stringify(d));
  }
}

const mockScores = [];
const server = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || '/').split('?')[0]);

  // Fejlesztői mock a ranglistához (Supabase REST /rest/v1/scores): memóriában tárol, újraindításkor elvész. Tesztelés: ?lburl=http://127.0.0.1:<port>&lbkey=x
  if (url.startsWith('/rest/v1/')) {
    const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': '*', 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS' };
    if (req.method === 'OPTIONS') { res.writeHead(204, cors); res.end(); return; }
    if (req.method === 'POST') {
      let body = '';
      req.on('data', (ch) => { body += ch; });
      req.on('end', () => {
        try {
          const r = JSON.parse(body);
          if (typeof r.name !== 'string' || r.name.length !== 3 || !(r.score >= 0)) throw new Error('bad row');
          mockScores.push({ name: r.name, score: r.score | 0, level: r.level | 0, difficulty: r.difficulty });
          console.log(c.dim + stamp() + c.reset + ' ' + c.cyan + who(req) + c.reset + ' ' + c.green + 'SCORE ' + c.reset + r.name + ' ' + r.score + ' L' + r.level + ' ' + r.difficulty);
          res.writeHead(201, cors); res.end();
        } catch (e) { res.writeHead(400, cors); res.end('bad request'); }
      });
      return;
    }
    const q = new URL(req.url, 'http://x').searchParams;
    const diff = (q.get('difficulty') || '').replace('eq.', '');
    const limit = parseInt(q.get('limit') || '10', 10);
    const rows = mockScores.filter((r) => !diff || r.difficulty === diff).sort((a, b) => b.score - a.score).slice(0, limit).map((r) => ({ name: r.name, score: r.score, level: r.level }));
    res.writeHead(200, Object.assign({ 'Content-Type': 'application/json' }, cors));
    res.end(JSON.stringify(rows));
    return;
  }
  if (req.method === 'POST' && url === '/__log') {
    let body = '';
    req.on('data', (ch) => { body += ch; if (body.length > 64 * 1024) req.destroy(); });
    req.on('end', () => {
      try { const m = JSON.parse(body); fs.appendFileSync(jsonPath, JSON.stringify({ ip: who(req), ...m }) + '\n'); printLog(req, m); } catch (e) { console.log(c.red + 'rossz naplóüzenet: ' + c.reset + body.slice(0, 200)); }
      res.writeHead(204, { 'Access-Control-Allow-Origin': '*' });
      res.end();
    });
    return;
  }

  if (url === '/audiotest') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
    res.end(fs.readFileSync(path.join(__dirname, 'audiotest.html')));
    return;
  }

  let rel = url === '/' ? '/index.html' : url;
  const file = path.normalize(path.join(root, rel));
  if (!file.startsWith(root)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, {
      'Content-Type': types[path.extname(file).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(data);
  });
});

server.on('error', (e) => {
  console.error(c.red + 'A szerver nem indult el (' + e.code + '): ' + e.message + c.reset);
  process.exit(1);
});
server.listen(port, '0.0.0.0', () => {
  console.log('Kiszolgálás: http://0.0.0.0:' + port + '/  (mappa: ' + root + ')  Leállítás: Ctrl+C');
  console.log(c.dim + 'Napló fájlban: ' + textPath + c.reset);
  console.log(c.dim + 'Élő napló: nyisd meg a játékot ?log=1 paraméterrel (pl. http://<gép-IP>:' + port + '/?log=1&touch=1)' + c.reset);
});
