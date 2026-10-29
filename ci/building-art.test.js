const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { rgbaPNG } = require("./png-pixels");

const assets = path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets");
const catalog = JSON.parse(fs.readFileSync(path.join(assets, "BuildingArtLayout.dataset/layout.json"), "utf8"));
const base = rgbaPNG(path.join(assets, "BuildingBaseAtlas.imageset/building-bases-v1.png"));
const weapon = rgbaPNG(path.join(assets, "BuildingWeapon.imageset/building-weapon-v1.png"));

function pixel(image, point) {
  return [Math.round(point[0] * image.width / catalog.referenceSize[0]),
    Math.round(point[1] * image.height / catalog.referenceSize[1])];
}

function cropStats(image, crop) {
  const [x, y, w, h] = crop;
  const sx = image.width / catalog.referenceSize[0], sy = image.height / catalog.referenceSize[1];
  const left = Math.floor(x * sx), right = Math.ceil((x + w) * sx);
  const top = Math.floor(y * sy), bottom = Math.ceil((y + h) * sy);
  let opaque = 0, transparent = 0, border = 0, darkest = 255, lightest = 0, maxX = left;
  const borderSides = { left: 0, right: 0, top: 0, bottom: 0 };
  for (let py = top; py < bottom; py += 1) {
    for (let px = left; px < right; px += 1) {
      const alpha = image.alpha(px, py);
      if (alpha === 0) transparent += 1;
      if (alpha >= 192) {
        opaque += 1;
        const brightness = (image.channel(px, py, 0) + image.channel(px, py, 1) + image.channel(px, py, 2)) / 3;
        darkest = Math.min(darkest, brightness);
        lightest = Math.max(lightest, brightness);
        maxX = Math.max(maxX, px);
      }
      if ((px <= left + 1 || px >= right - 2 || py <= top + 1 || py >= bottom - 2) && alpha > 16) border += 1;
      if (alpha > 16) {
        if (px <= left + 1) borderSides.left += 1;
        if (px >= right - 2) borderSides.right += 1;
        if (py <= top + 1) borderSides.top += 1;
        if (py >= bottom - 2) borderSides.bottom += 1;
      }
    }
  }
  return { opaque, transparent, border, borderSides, darkest, lightest, maxX,
    width: right - left, height: bottom - top, count: (right - left) * (bottom - top) };
}

function assertCrop(image, crop, name, minimumContent) {
  const stats = cropStats(image, crop);
  console.log(`Building crop ${name}: ${stats.width}x${stats.height}, opaque=${(stats.opaque / stats.count).toFixed(3)}, transparent=${(stats.transparent / stats.count).toFixed(3)}, border=${stats.border}, sides=${JSON.stringify(stats.borderSides)}`);
  assert.ok(stats.opaque / stats.count > minimumContent, `${name}: missing or effectively empty artwork`);
  assert.ok(stats.transparent / stats.count > 0.05, `${name}: opaque matte or insufficient transparent gutters`);
  assert.equal(stats.border, 0, `${name}: crop clips artwork or includes a neighboring building`);
  assert.ok(stats.lightest - stats.darkest > 90, `${name}: missing readable material detail`);
  return stats;
}

test("building catalog covers all nine native type/tier variants with bounded authored footprint coordinates", () => {
  assert.deepEqual(Object.keys(catalog.buildings).sort(), ["command-1", "landFactory-1", "landFactory-2",
    "extractor-1", "extractor-2", "extractor-3", "radar-1", "radar-2", "turret-1"].sort());
  assert.deepEqual(catalog.referenceSize, [base.width, base.height], "Authored pixel coordinates must use the actual source dimensions, not display scaling");
  assert.deepEqual([weapon.width, weapon.height], catalog.referenceSize);
  for (const entry of Object.values(catalog.buildings)) {
    const [x, y, w, h] = entry.crop;
    const [px, py] = entry.pivot;
    assert.ok([...entry.crop, px, py, entry.footprintSpan].every(Number.isFinite));
    assert.ok(x >= 0 && y >= 0 && w > 0 && h > 0 && x + w <= base.width && y + h <= base.height);
    assert.ok(px > x && px < x + w && py > y && py < y + h);
    assert.ok(entry.footprintSpan >= 270 && entry.footprintSpan <= 430);
    assert.ok(Math.max(px - x, x + w - px, py - y, y + h - py) / entry.footprintSpan < 0.66,
      "Art must remain near the existing Core footprint rather than inflate the selection or collider");
  }
});

for (const [name, entry] of Object.entries(catalog.buildings)) {
  test(`${name} actual base has RGBA detail, transparent gutters and a solid authored anchor`, () => {
    const stats = assertCrop(base, entry.crop, name, 0.30);
    assert.ok(Math.min(stats.width, stats.height) >= 256, "Final building crop must retain useful source detail");
    assert.ok(base.alpha(...pixel(base, entry.pivot)) >= 192, "The world anchor must land on the actual structure");
  });
}

function silhouette(entry) {
  const mask = [];
  for (let y = 0; y < 40; y += 1) {
    for (let x = 0; x < 40; x += 1) {
      const point = [entry.pivot[0] + ((x + 0.5) / 40 - 0.5) * entry.footprintSpan * 1.3,
        entry.pivot[1] + ((y + 0.5) / 40 - 0.5) * entry.footprintSpan * 1.3];
      const [px, py] = pixel(base, point);
      const [left, top, width, height] = entry.crop;
      mask.push(point[0] >= left && point[0] < left + width && point[1] >= top && point[1] < top + height &&
        px >= 0 && py >= 0 && px < base.width && py < base.height && base.alpha(px, py) >= 128);
    }
  }
  return mask;
}

test("factory, extractor and radar upgrades have distinct actual normalized silhouettes, not just tier labels", () => {
  for (const [first, second] of [["landFactory-1", "landFactory-2"], ["extractor-1", "extractor-2"],
    ["extractor-2", "extractor-3"], ["radar-1", "radar-2"]]) {
    const a = silhouette(catalog.buildings[first]), b = silhouette(catalog.buildings[second]);
    const difference = a.filter((value, index) => value !== b[index]).length / a.length;
    console.log(`Building silhouettes ${first}/${second}: ${(difference * 100).toFixed(2)}% different.`);
    assert.ok(difference > 0.025, `${first}/${second}: upgraded tiers must be readable by shape`);
  }
});

test("standalone turret has real transparent padding, an opaque pivot and a correctly authored muzzle edge", () => {
  const entry = catalog.turret;
  assert.ok([...entry.crop, ...entry.pivot, ...entry.muzzle, entry.weaponCutX, entry.muzzleDistance].every(Number.isFinite));
  assert.ok(entry.weaponCutX > entry.pivot[0] && entry.weaponCutX < entry.muzzle[0]);
  assert.ok(entry.muzzleDistance > 1 && entry.muzzleDistance < 1.7);
  assert.equal(entry.muzzle[1], entry.pivot[1], "Forward fire must share the actual horizontal barrel centerline");
  const stats = assertCrop(weapon, entry.crop, "turret-weapon", 0.15);
  assert.ok(weapon.alpha(...pixel(weapon, entry.pivot)) >= 192);
  const [muzzleX, muzzleY] = pixel(weapon, entry.muzzle);
  assert.ok(Math.abs(stats.maxX - muzzleX) <= 8, "Muzzle must track visible source edge, not crop padding");
  assert.ok(weapon.alpha(muzzleX - 4, muzzleY) >= 192, "Muzzle must lie on the actual cannon, not empty space");
});

test("independent recoil split stays on the solid barrel and preserves the fixed housing pivot", () => {
  const entry = catalog.turret;
  const [cutX, centerY] = pixel(weapon, [entry.weaponCutX, entry.pivot[1]]);
  for (const dx of [-2, -1, 0, 1, 2]) {
    assert.ok(weapon.alpha(cutX + dx, centerY) >= 192, "No transparent break at the recoil split");
  }
  const [x, y, w, h] = entry.crop;
  const housing = cropStats(weapon, [x, y, entry.weaponCutX - x + 0.5, h]);
  const barrel = cropStats(weapon, [entry.weaponCutX - 0.5, y, x + w - entry.weaponCutX + 0.5, h]);
  assert.ok(housing.opaque > 10_000 && barrel.opaque > 10_000, "Both moving layers must contain actual source pixels");
  const [pivotX, pivotY] = pixel(weapon, entry.pivot);
  assert.ok(pivotX < cutX && weapon.alpha(pivotX, pivotY) >= 192,
    "The bearing must remain on the fixed housing rather than the recoiling barrel");
});
