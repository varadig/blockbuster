const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 960, height: 540 } });
  await p.goto((process.env.URL || 'http://localhost:8765') + '/index.html');
  await p.waitForTimeout(1500);
  await p.mouse.click(480, 270);
  await p.evaluate(() => { const g = window.__game; g.blocks.forEachAlive(b => b.kill());
    const sx = g.player.get_camera().scroll.x;
    const seg = g.ground.members.filter(m => m.alive && m.height > 20 && m.width > 60 && m.x > sx + 150).sort((a,b)=>a.x-b.x)[0];
    g.player.x = seg.x + 20; g.player.y = seg.y - 20; g.player.velocity.set(0,0); });
  await p.waitForTimeout(700);
  console.log('player', await p.evaluate(() => [window.__game.player.y, window.__game.player.isTouching(4096)]));
  // Blokk közvetlenül a játékos fölé, aztán felfelé lövés
  await p.evaluate(() => { const g = window.__game; g.spawnTimer = 999;
    (g.spawnTimer = 0, g.updateSpawner(0), g.spawnTimer = 999, g.blocks.members.filter(m => m.alive && !m.landed).pop()).spawn(g.player.x + 6, 0, 30); });
  await p.keyboard.down('ArrowUp'); await p.keyboard.down('x');
  await p.waitForTimeout(1500);
  await p.keyboard.up('x');
  const s = await p.evaluate(() => ({ destroyed: window.__game.blocksDestroyed, dead: window.__game.dead }));
  console.log('shoot-up test:', s);
  // Blokk a fejre, nem lő -> energiát veszít (nem hal meg azonnal)
  await p.evaluate(() => { const g = window.__game;
    (g.spawnTimer = 0, g.updateSpawner(0), g.spawnTimer = 999, g.blocks.members.filter(m => m.alive && !m.landed).pop()).spawn(g.player.x + 6, g.player.y - 60, 200); });
  await p.waitForTimeout(800);
  console.log('crush test (energy < 100, alive):', await p.evaluate(() => ({ dead: window.__game.dead, energy: window.__game.player.energy })));
  await b.close();
})();
