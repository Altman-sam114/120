const assert = require("node:assert/strict");
const fs = require("node:fs");
const zlib = require("node:zlib");

// Decode source RGBA pixels without an image-library or network dependency.
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
  return { width, height, pixels,
    alpha: (x, y) => pixels[(y * width + x) * 4 + 3],
    channel: (x, y, channel) => pixels[(y * width + x) * 4 + channel] };
}

module.exports = { rgbaPNG };
