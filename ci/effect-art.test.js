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
