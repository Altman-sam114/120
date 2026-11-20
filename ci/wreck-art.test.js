const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");
const { rgbaPNG } = require("./png-pixels");

const image = rgbaPNG(path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets/WreckAtlas.imageset/wrecks-v1.png"));
test("wreck atlas has four isolated detailed transparent cells", () => {
  assert.equal(image.width, 1254);
  assert.equal(image.height, 1254);
  for (let cell = 0; cell < 4; cell++) {
    const left = (cell % 2) * 627, top = Math.floor(cell / 2) * 627;
    let opaque = 0, transparent = 0, border = 0, low = 255, high = 0;
    for (let y = 0; y < 627; y++) for (let x = 0; x < 627; x++) {
      const alpha = image.alpha(left + x, top + y);
      if (alpha === 0) transparent++;
      if (alpha >= 192) {
        opaque++;
        const luma = (image.channel(left + x, top + y, 0) + image.channel(left + x, top + y, 1) + image.channel(left + x, top + y, 2)) / 3;
        low = Math.min(low, luma); high = Math.max(high, luma);
      }
      if ((x < 2 || y < 2 || x >= 625 || y >= 625) && alpha > 16) border++;
    }
    console.log(`Wreck ${cell + 1}: opaque=${opaque}, transparent=${transparent}, border=${border}, range=${high-low}`);
    assert.ok(opaque > 20000, "cell must contain a substantial wreck");
    assert.ok(transparent > 50000, "cell must have true transparent padding");
    assert.equal(border, 0, "no clipping or adjacent cell bleed");
    assert.ok(high - low > 60, "metal must retain visible detail");
  }
});

test("gunboat wreck has transparent margins and detailed opaque hull", () => {
  const boat = rgbaPNG(path.join(__dirname, "../ios/RustwarIOS/RustwarIOS/Assets.xcassets/WreckGunboat.imageset/gunboat-wreck-v1.png"));
  assert.equal(boat.width, 2172);
  assert.equal(boat.height, 724);
  let opaque = 0, transparent = 0, border = 0, low = 255, high = 0;
  for (let y = 0; y < boat.height; y++) for (let x = 0; x < boat.width; x++) {
    const alpha = boat.alpha(x, y);
    if (alpha === 0) transparent++;
    if (alpha >= 192) {
      opaque++;
      const luma = (boat.channel(x, y, 0) + boat.channel(x, y, 1) + boat.channel(x, y, 2)) / 3;
      low = Math.min(low, luma); high = Math.max(high, luma);
    }
    if ((x < 2 || y < 2 || x >= boat.width - 2 || y >= boat.height - 2) && alpha > 16) border++;
  }
  console.log(`Gunboat wreck: opaque=${opaque}, transparent=${transparent}, border=${border}, range=${high-low}`);
  assert.ok(opaque > 100000);
  assert.ok(transparent > 100000);
  assert.equal(border, 0);
  assert.ok(high - low > 60);
});
