const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { rgbaPNG } = require("./png-pixels");

const assets = path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets");
const catalog = JSON.parse(fs.readFileSync(path.join(assets, "UnitArtLayout.dataset/layout.json"), "utf8"));

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
