const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");
const { createHash } = require("node:crypto");
const { rgbaPNG } = require("./png-pixels");

const image = rgbaPNG(path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets/ExplosionAtlas.imageset/explosion-v1.png"));
const side = image.width / 4;
console.log(`Explosion source pixels: ${image.width}x${image.height}; UV grid: 4x2.`);

function frameStats(index) {
  const column = index % 4, row = Math.floor(index / 4);
  const left = Math.floor(column * image.width / 4), right = Math.floor((column + 1) * image.width / 4);
  const top = Math.floor(row * image.height / 2), bottom = Math.floor((row + 1) * image.height / 2);
  const hash = createHash("sha256");
  let transparent = 0, visible = 0, border = 0, alphaMass = 0, warm = 0;
  for (let y = top; y < bottom; y += 1) {
    hash.update(image.pixels.subarray((y * image.width + left) * 4, (y * image.width + right) * 4));
    for (let x = left; x < right; x += 1) {
      const alpha = image.alpha(x, y);
      if (alpha === 0) transparent += 1;
      if (alpha > 16) visible += 1;
      if ((x === left || x === right - 1 || y === top || y === bottom - 1) && alpha > 16) border += 1;
      alphaMass += alpha / 255;
      if (alpha >= 128 && image.channel(x, y, 0) > image.channel(x, y, 2) + 40) warm += 1;
    }
  }
  return { transparent, visible, border, alphaMass, warm, count: (right - left) * (bottom - top), hash: hash.digest("hex") };
}

test("explosion atlas contains eight equal square RGBA UV cells", () => {
  assert.equal(image.width, image.height * 2, "A 4x2 square-cell atlas must have an exact 2:1 aspect ratio");
  assert.equal(image.height / 2, side);
  assert.ok(side >= 256, "Final effects need detail beyond placeholder-resolution textures");
});

for (let index = 0; index < 8; index += 1) {
  test(`explosion frame ${index + 1} has real alpha, visible content and clear crop boundaries`, () => {
    const frame = frameStats(index), count = frame.count;
    assert.ok(frame.transparent > count * 0.08, "Opaque matte or missing transparent padding");
    assert.ok(frame.visible > count * 0.02, "Missing or effectively empty frame");
    assert.equal(frame.border, 0, "A cell clips the blast or includes neighboring artwork");
  });
}

test("explosion stages are genuinely distinct and decay from fire into translucent smoke", () => {
  const frames = Array.from({ length: 8 }, (_, index) => frameStats(index));
  console.log(`Explosion frame alpha mass: ${frames.map((frame) => frame.alphaMass.toFixed(1)).join(", ")}`);
  assert.ok(frames.every((frame) => Number.isFinite(frame.alphaMass)));
  assert.equal(new Set(frames.map((frame) => frame.hash)).size, 8, "Repeated stills cannot stand in for animation");
  assert.ok(frames[0].alphaMass < frames[3].alphaMass * 0.65, "The ignition must be smaller than the peak blast");
  assert.ok(frames[7].alphaMass < frames[3].alphaMass * 0.7, "The last smoke frame must visibly dissipate");
  assert.ok(frames[3].warm > side * side * 0.03, "Peak blast is missing the actual warm flame artwork");
  assert.ok(frames[7].warm < frames[3].warm * 0.1, "The final stage must be smoke, not a repeated fireball");
});

test("PNG sampling rejects fractional or out-of-bounds coordinates instead of reading another byte", () => {
  for (const [x, y] of [[0.5, 0], [0, 0.5], [-1, 0], [image.width, 0], [0, image.height]]) {
    assert.throws(() => image.alpha(x, y), RangeError);
    assert.throws(() => image.channel(x, y, 0), RangeError);
  }
});

test("water impact contains isolated translucent foam with padding", () => {
  const splash = rgbaPNG(path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets/WaterImpact.imageset/water-impact-v1.png"));
  const count = splash.width * splash.height;
  assert.equal(splash.width, splash.height, "The water sprite uses a square world footprint");
  let clear = 0, border = 0, foam = 0;
  for (let y = 0; y < splash.height; y += 1) {
    for (let x = 0; x < splash.width; x += 1) {
      const alpha = splash.alpha(x, y);
      if (alpha <= 8) clear += 1;
      if ((x === 0 || x === splash.width - 1 || y === 0 || y === splash.height - 1) && alpha > 16) border += 1;
      if (alpha >= 128 && splash.channel(x, y, 1) > 145 && splash.channel(x, y, 2) > 145) foam += 1;
    }
  }
  console.log(`Water impact: ${splash.width}x${splash.height}, clear=${clear}, foam=${foam}, border=${border}.`);
  assert.equal(border, 0, "Splash must fade into open water with no clipped artwork");
  assert.ok(clear > count * 0.45, "The sprite needs substantial genuine transparency");
  assert.ok(foam > count * 0.06, "Foam must be visible at battlefield scale");
  assert.ok(splash.alpha(Math.floor(splash.width / 2), Math.floor(splash.height / 2)) <= 16,
    "The center must reveal the underlying water");
});

function verify2x2Atlas(relPath, label, minVisibleFraction) {
  const atlas = rgbaPNG(path.join(__dirname, relPath));
  assert.equal(atlas.width, atlas.height, `${label} must be a square 2x2 atlas`);
  assert.ok(atlas.width >= 512, `${label} must have production resolution`);
  const hashes = new Set();
  for (let index = 0; index < 4; index += 1) {
    const col = index % 2, row = Math.floor(index / 2);
    const left = Math.floor(col * atlas.width / 2), right = Math.floor((col + 1) * atlas.width / 2);
    const top = Math.floor(row * atlas.height / 2), bottom = Math.floor((row + 1) * atlas.height / 2);
    const hash = createHash("sha256");
    let transparent = 0, visible = 0, border = 0;
    for (let y = top; y < bottom; y += 1) {
      hash.update(atlas.pixels.subarray((y * atlas.width + left) * 4, (y * atlas.width + right) * 4));
      for (let x = left; x < right; x += 1) {
        const alpha = atlas.alpha(x, y);
        if (alpha <= 8) transparent += 1;
        if (alpha > 16) visible += 1;
        if ((x === left || x === right - 1 || y === top || y === bottom - 1) && alpha > 16) border += 1;
      }
    }
    const count = (right - left) * (bottom - top);
    assert.ok(transparent > count * 0.2, `${label} cell ${index + 1} needs transparent padding`);
    assert.ok(visible > count * minVisibleFraction, `${label} cell ${index + 1} is empty or too faint`);
    assert.equal(border, 0, `${label} cell ${index + 1} clips or bleeds across cell edge`);
    hashes.add(hash.digest("hex"));
  }
  assert.equal(hashes.size, 4, `${label} must contain 4 distinct variants`);
}

test("muzzle flash atlas contains four distinct isolated RGBA variants", () => {
  verify2x2Atlas("../ios/RustwarIOS/RustwarIOS/Assets.xcassets/MuzzleFlashAtlas.imageset/muzzle-flashes-v1.png", "MuzzleFlashAtlas", 0.04);
});

test("crater atlas contains four distinct isolated RGBA variants", () => {
  verify2x2Atlas("../ios/RustwarIOS/RustwarIOS/Assets.xcassets/CraterAtlas.imageset/crater-decals-v1.png", "CraterAtlas", 0.08);
});

test("damage smoke atlas contains four distinct isolated RGBA variants", () => {
  verify2x2Atlas("../ios/RustwarIOS/RustwarIOS/Assets.xcassets/DamageSmokeAtlas.imageset/damage-smoke-v1.png", "DamageSmokeAtlas", 0.10);
});

test("water wake contains isolated translucent V-wake with padding", () => {
  const wake = rgbaPNG(path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets/WaterWake.imageset/water-wake-v1.png"));
  assert.ok(wake.width > wake.height, "Water wake should be wider than tall along hull axis");
  const count = wake.width * wake.height;
  let clear = 0, visible = 0, border = 0;
  for (let y = 0; y < wake.height; y += 1) {
    for (let x = 0; x < wake.width; x += 1) {
      const alpha = wake.alpha(x, y);
      if (alpha <= 8) clear += 1;
      if (alpha > 16) visible += 1;
      if ((x === 0 || x === wake.width - 1 || y === 0 || y === wake.height - 1) && alpha > 16) border += 1;
    }
  }
  console.log(`Water wake: ${wake.width}x${wake.height}, clear=${clear}, visible=${visible}, border=${border}.`);
  assert.equal(border, 0, "Water wake must fade cleanly inside canvas edges");
  assert.ok(clear > count * 0.45, "Water wake needs genuine transparent margins");
  assert.ok(visible > count * 0.08, "Water wake foam must be visible at battlefield scale");
});
