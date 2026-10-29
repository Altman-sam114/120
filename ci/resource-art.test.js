const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { createHash } = require("node:crypto");
const { rgbaPNG } = require("./png-pixels");

const assets = path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets");
const catalog = JSON.parse(fs.readFileSync(path.join(assets, "ResourceArtLayout.dataset/layout.json"), "utf8"));
const image = rgbaPNG(path.join(assets, "ResourceAtlas.imageset/resource-deposits-v1.png"));

test("mineral layout covers four original patches using actual source pixels and the existing resource radius", () => {
  assert.deepEqual(catalog.referenceSize, [image.width, image.height]);
  assert.equal(catalog.patches.length, 4);
  assert.ok(catalog.diameterInRadii >= 1.5 && catalog.diameterInRadii <= 1.8);
  for (const entry of catalog.patches) {
    const [x, y, w, h] = entry.crop;
    const [px, py] = entry.pivot;
    assert.ok([...entry.crop, ...entry.pivot, entry.span].every(Number.isFinite));
    assert.ok(x >= 0 && y >= 0 && w >= 256 && h >= 256 && x + w <= image.width && y + h <= image.height);
    assert.ok(px > x && px < x + w && py > y && py < y + h);
    assert.ok(entry.span > 0 && Math.max(px - x, x + w - px, py - y, y + h - py) *
      catalog.diameterInRadii / entry.span <= 1, "Artwork must not grow beyond the existing resource footprint");
  }
});

function stats(entry) {
  const [left, top, w, h] = entry.crop;
  const right = left + w, bottom = top + h;
  const hash = createHash("sha256");
  let opaque = 0, transparent = 0, border = 0, low = 255, high = 0, cyan = 0;
  for (let y = top; y < bottom; y += 1) {
    hash.update(image.pixels.subarray((y * image.width + left) * 4, (y * image.width + right) * 4));
    for (let x = left; x < right; x += 1) {
      const alpha = image.alpha(x, y);
      if (alpha === 0) transparent += 1;
      if (alpha >= 192) {
        opaque += 1;
        const r = image.channel(x, y, 0), g = image.channel(x, y, 1), b = image.channel(x, y, 2);
        const luma = (r + g + b) / 3;
        low = Math.min(low, luma);
        high = Math.max(high, luma);
        if (g > 150 && b > 150 && b > r * 1.3) cyan += 1;
      }
      if ((x <= left + 1 || x >= right - 2 || y <= top + 1 || y >= bottom - 2) && alpha > 16) border += 1;
    }
  }
  return { opaque, transparent, border, low, high, cyan, total: w * h, hash: hash.digest("hex") };
}

for (const [index, entry] of catalog.patches.entries()) {
  test(`mineral patch ${index + 1} has true RGBA padding, material detail and a solid build anchor`, () => {
    const result = stats(entry);
    console.log(`Mineral patch ${index + 1}: opaque=${(result.opaque / result.total).toFixed(3)}, transparent=${(result.transparent / result.total).toFixed(3)}, border=${result.border}`);
    assert.ok(result.opaque > result.total * 0.20, "Missing or effectively empty mineral patch");
    assert.ok(result.transparent > result.total * 0.10, "Opaque matte or insufficient transparent padding");
    assert.equal(result.border, 0, "Crop clips the deposit or includes neighboring artwork");
    assert.ok(result.high - result.low > 90, "Flat placeholder instead of material detail");
    assert.ok(result.cyan < result.opaque * 0.20, "A natural deposit must not become an emissive cyan disc");
    assert.ok(image.alpha(...entry.pivot) >= 192, "The build anchor must land on the actual outcrop");
  });
}

test("all four mineral patches contain different actual source artwork", () => {
  assert.equal(new Set(catalog.patches.map((entry) => stats(entry).hash)).size, 4);
});
