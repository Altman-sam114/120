const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const zlib = require("node:zlib");

const assets = path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets");
const catalog = JSON.parse(fs.readFileSync(path.join(assets, "UnitArtLayout.dataset/layout.json"), "utf8"));

// Decode the actual source pixels without downloading an image library. These
// generated PNGs must retain RGBA alpha; an opaque black matte is not a sprite.
function rgbaPNG(file) {
  const data = fs.readFileSync(file);
  assert.equal(data.subarray(0, 8).toString("hex"), "89504e470d0a1a0a");
  let width, height;
  const compressed = [];
  for (let i = 8; i < data.length;) {
    const length = data.readUInt32BE(i);
    const type = data.toString("ascii", i + 4, i + 8);
    const chunk = data.subarray(i + 8, i + 8 + length);
    if (type === "IHDR") {
      width = chunk.readUInt32BE(0);
      height = chunk.readUInt32BE(4);
      assert.equal(chunk[8], 8, "Expected 8-bit source artwork");
      assert.equal(chunk[9], 6, "Source artwork must have a real RGBA channel");
      assert.equal(chunk[12], 0, "Expected noninterlaced source artwork");
    }
    if (type === "IDAT") compressed.push(chunk);
    i += length + 12;
  }
  const scanlines = zlib.inflateSync(Buffer.concat(compressed));
  const stride = width * 4;
  assert.equal(scanlines.length, (stride + 1) * height);
  const pixels = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y += 1) {
    const filter = scanlines[y * (stride + 1)];
    assert.ok(filter >= 0 && filter <= 4);
    for (let x = 0; x < stride; x += 1) {
      const left = x >= 4 ? pixels[y * stride + x - 4] : 0;
      const up = y > 0 ? pixels[(y - 1) * stride + x] : 0;
      const upperLeft = y > 0 && x >= 4 ? pixels[(y - 1) * stride + x - 4] : 0;
      let predictor = 0;
      if (filter === 1) predictor = left;
      if (filter === 2) predictor = up;
      if (filter === 3) predictor = Math.floor((left + up) / 2);
      if (filter === 4) {
        const p = left + up - upperLeft;
        const a = Math.abs(p - left), b = Math.abs(p - up), c = Math.abs(p - upperLeft);
        predictor = a <= b && a <= c ? left : b <= c ? up : upperLeft;
      }
      pixels[y * stride + x] = (scanlines[y * (stride + 1) + x + 1] + predictor) & 255;
    }
  }
  return { width, height, alpha: (x, y) => pixels[(y * width + x) * 4 + 3] };
}

const hull = rgbaPNG(path.join(assets, "UnitHullAtlas.imageset/unit-hulls-v1.png"));
const mount = rgbaPNG(path.join(assets, "UnitMountAtlas.imageset/unit-mounts-v1.png"));

test("generated catalog covers the eight native units with finite authored pivots", () => {
  assert.deepEqual(Object.keys(catalog.units).sort(),
    ["builder", "scout", "tank", "heavyTank", "hover", "aaTank", "artillery", "gunboat"].sort());
  assert.deepEqual(catalog.referenceSize, [1776, 888]);
  for (const entry of Object.values(catalog.units)) {
    assert.ok(entry.hullLength > 1.5 && entry.hullLength < 2.6);
    assert.ok(Number.isFinite(entry.weaponCutX) && entry.weaponCutX > entry.mount[0] &&
      entry.weaponCutX < entry.mount[0] + entry.mount[2], "Recoil split must stay inside the authored mount");
    for (const kind of ["hull", "mount"]) {
      const [x, y, w, h] = entry[kind];
      const [px, py] = entry[`${kind}Pivot`];
      assert.ok([x, y, w, h, px, py].every(Number.isFinite));
      assert.ok(x >= 0 && y >= 0 && w > 0 && h > 0);
      assert.ok(x + w <= catalog.referenceSize[0] && y + h <= catalog.referenceSize[1]);
      assert.ok(px > x && px < x + w && py > y && py < y + h);
    }
  }
});

for (const [name, entry] of Object.entries(catalog.units)) {
  for (const [kind, image] of [["hull", hull], ["mount", mount]]) {
    test(`${name} ${kind} has real transparency, visible detail and unclipped crop gutters`, () => {
      const [x, y, w, h] = entry[kind];
      const sx = image.width / catalog.referenceSize[0], sy = image.height / catalog.referenceSize[1];
      const left = Math.floor(x * sx), top = Math.floor(y * sy);
      const right = Math.ceil((x + w) * sx), bottom = Math.ceil((y + h) * sy);
      let opaque = 0, transparent = 0, border = 0;
      for (let py = top; py < bottom; py += 1) {
        for (let px = left; px < right; px += 1) {
          const alpha = image.alpha(px, py);
          if (alpha >= 192) opaque += 1;
          if (alpha === 0) transparent += 1;
          if ((px === left || px === right - 1 || py === top || py === bottom - 1) && alpha > 16) border += 1;
        }
      }
      const count = (right - left) * (bottom - top);
      assert.ok(opaque / count > 0.15, `${name}: missing artwork`);
      assert.ok(transparent / count > 0.08, `${name}: opaque matte or missing padding`);
      assert.equal(border, 0, `${name}: authored crop clips artwork or includes a neighbouring sprite`);
      const pivot = entry[`${kind}Pivot`];
      assert.ok(image.alpha(Math.round(pivot[0] * sx), Math.round(pivot[1] * sy)) > 192,
        `${name}: pivot must land on the actual model, not transparent space`);
    });
  }
}
