const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");
const { createHash } = require("node:crypto");
const { decodePNG, rgbaPNG } = require("./png-pixels");

const assets = path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets");
const terrainEntries = [
  { key: "grass", set: "TerrainGrass.imageset", file: "terrain-grass-v1.png" },
  { key: "dirt", set: "TerrainDirt.imageset", file: "terrain-dirt-v1.png" },
  { key: "sand", set: "TerrainSand.imageset", file: "terrain-sand-v1.png" },
  { key: "rock", set: "TerrainRock.imageset", file: "terrain-rock-v1.png" },
  { key: "water", set: "TerrainWater.imageset", file: "terrain-water-v1.png" },
  { key: "deep", set: "TerrainDeep.imageset", file: "terrain-deep-v1.png" },
  { key: "lava", set: "TerrainLava.imageset", file: "terrain-lava-v1.png" }
];

function terrainStats(entry) {
  const image = decodePNG(path.join(assets, entry.set, entry.file));
  const count = image.width * image.height;
  let sumR = 0, sumG = 0, sumB = 0, sumLuma = 0;
  let low = 255, high = 0, minAlpha = 255, darkBasalt = 0, magmaGlow = 0;
  const hash = createHash("sha256").update(image.pixels).digest("hex");
  for (let offset = 0; offset < image.pixels.length; offset += 4) {
    const r = image.pixels[offset];
    const g = image.pixels[offset + 1];
    const b = image.pixels[offset + 2];
    const a = image.pixels[offset + 3];
    sumR += r;
    sumG += g;
    sumB += b;
    const luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    sumLuma += luma;
    if (luma < low) low = luma;
    if (luma > high) high = luma;
    if (a < minAlpha) minAlpha = a;
    if (luma < 65) darkBasalt += 1;
    if (r > 140 && r > b + 60) magmaGlow += 1;
  }
  return {
    key: entry.key,
    width: image.width,
    height: image.height,
    meanR: sumR / count,
    meanG: sumG / count,
    meanB: sumB / count,
    meanLuma: sumLuma / count,
    range: high - low,
    minAlpha,
    darkBasaltRatio: darkBasalt / count,
    magmaGlowRatio: magmaGlow / count,
    hash
  };
}

const results = new Map(terrainEntries.map((entry) => [entry.key, terrainStats(entry)]));

for (const entry of terrainEntries) {
  test(`terrain material ${entry.key} is a high-resolution opaque detailed tile`, () => {
    const stats = results.get(entry.key);
    console.log(
      `Terrain ${entry.key}: ${stats.width}x${stats.height}, luma=${stats.meanLuma.toFixed(1)}, range=${stats.range.toFixed(1)}, rgb=(${stats.meanR.toFixed(0)},${stats.meanG.toFixed(0)},${stats.meanB.toFixed(0)})`
    );
    assert.equal(stats.width, stats.height, "Terrain material must be square for seamless tiling");
    assert.ok(stats.width >= 512, "Terrain material must exceed placeholder resolution");
    assert.ok(stats.minAlpha >= 250, "Terrain ground material must be opaque");
    assert.ok(stats.range >= 45, "Terrain material must have real surface detail instead of flat fill");
    assert.ok(stats.meanLuma >= 18 && stats.meanLuma <= 210, "Terrain brightness must preserve unit legibility");
  });
}

test("all seven terrain materials are distinct and biome-consistent", () => {
  assert.equal(new Set([...results.values()].map((stats) => stats.hash)).size, 7);
  const grass = results.get("grass");
  const water = results.get("water");
  const deep = results.get("deep");
  const lava = results.get("lava");
  assert.ok(grass.meanG > grass.meanB, "Grassland must remain greenish rather than cool blue");
  assert.ok(water.meanB > water.meanR && water.meanG > water.meanR, "Coastal water must stay cool blue-teal");
  assert.ok(deep.meanB > deep.meanR, "Deep water must stay cool pelagic blue");
  assert.ok(deep.meanLuma < water.meanLuma, "Deep ocean must read darker than shallow coastal water");
  assert.ok(lava.darkBasaltRatio > 0.35, "Volcanic crust must preserve dark basalt contrast for units");
  assert.ok(lava.magmaGlowRatio > 0.005, "Volcanic terrain must include glowing molten fissures");
});

test("building concrete foundation pad has true RGBA transparency, zero border clipping and concrete detail", () => {
  const pad = rgbaPNG(path.join(assets, "BuildingPad.imageset/building-pad-v1.png"));
  const count = pad.width * pad.height;
  assert.equal(pad.width, pad.height);
  assert.ok(pad.width >= 512);
  let opaque = 0, transparent = 0, border = 0, low = 255, high = 0;
  for (let y = 0; y < pad.height; y += 1) {
    for (let x = 0; x < pad.width; x += 1) {
      const alpha = pad.alpha(x, y);
      if (alpha === 0) transparent += 1;
      if (alpha >= 192) {
        opaque += 1;
        const luma = (pad.channel(x, y, 0) + pad.channel(x, y, 1) + pad.channel(x, y, 2)) / 3;
        if (luma < low) low = luma;
        if (luma > high) high = luma;
      }
      if ((x <= 1 || x >= pad.width - 2 || y <= 1 || y >= pad.height - 2) && alpha > 16) border += 1;
    }
  }
  console.log(
    `BuildingPad: ${pad.width}x${pad.height}, opaque=${(opaque / count).toFixed(3)}, transparent=${(transparent / count).toFixed(3)}, border=${border}, range=${(high - low).toFixed(1)}`
  );
  assert.equal(border, 0, "Foundation pad must not clip against PNG borders");
  assert.ok(transparent > count * 0.20, "Foundation pad needs genuine transparent margins");
  assert.ok(opaque > count * 0.30, "Foundation pad must contain a substantial concrete slab");
  assert.ok(pad.alpha(Math.floor(pad.width / 2), Math.floor(pad.height / 2)) >= 200, "Center must be solid concrete");
  assert.ok(high - low > 55, "Foundation pad must have weathered surface detail");
});
