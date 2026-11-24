const assert = require("node:assert/strict");
const fs = require("node:fs");
const zlib = require("node:zlib");

// Decode source PNG pixels without an image-library or network dependency.
function decodePNG(file, { requireAlpha = false } = {}) {
  const data = fs.readFileSync(file);
  assert.equal(data.subarray(0, 8).toString("hex"), "89504e470d0a1a0a");
  let width, height, colorType;
  const compressed = [];
  for (let i = 8; i < data.length;) {
    const length = data.readUInt32BE(i);
    const type = data.toString("ascii", i + 4, i + 8);
    const chunk = data.subarray(i + 8, i + 8 + length);
    if (type === "IHDR") {
      width = chunk.readUInt32BE(0);
      height = chunk.readUInt32BE(4);
      colorType = chunk[9];
      assert.equal(chunk[8], 8, "Expected 8-bit source artwork");
      if (requireAlpha) {
        assert.equal(colorType, 6, "Source artwork must have a real RGBA channel");
      } else {
        assert.ok(colorType === 2 || colorType === 6, "Source artwork must be 8-bit RGB or RGBA");
      }
      assert.equal(chunk[12], 0, "Expected noninterlaced source artwork");
    }
    if (type === "IDAT") compressed.push(chunk);
    i += length + 12;
  }
  const bpp = colorType === 6 ? 4 : 3;
  const scanlines = zlib.inflateSync(Buffer.concat(compressed));
  const stride = width * bpp;
  assert.equal(scanlines.length, (stride + 1) * height);
  const raw = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y += 1) {
    const filter = scanlines[y * (stride + 1)];
    assert.ok(filter >= 0 && filter <= 4);
    for (let x = 0; x < stride; x += 1) {
      const left = x >= bpp ? raw[y * stride + x - bpp] : 0;
      const up = y > 0 ? raw[(y - 1) * stride + x] : 0;
      const upperLeft = y > 0 && x >= bpp ? raw[(y - 1) * stride + x - bpp] : 0;
      let predictor = 0;
      if (filter === 1) predictor = left;
      if (filter === 2) predictor = up;
      if (filter === 3) predictor = Math.floor((left + up) / 2);
      if (filter === 4) {
        const p = left + up - upperLeft;
        const a = Math.abs(p - left), b = Math.abs(p - up), c = Math.abs(p - upperLeft);
        predictor = a <= b && a <= c ? left : b <= c ? up : upperLeft;
      }
      raw[y * stride + x] = (scanlines[y * (stride + 1) + x + 1] + predictor) & 255;
    }
  }
  let pixels;
  if (bpp === 4) {
    pixels = raw;
  } else {
    pixels = Buffer.alloc(width * height * 4);
    for (let p = 0; p < width * height; p += 1) {
      pixels[p * 4] = raw[p * 3];
      pixels[p * 4 + 1] = raw[p * 3 + 1];
      pixels[p * 4 + 2] = raw[p * 3 + 2];
      pixels[p * 4 + 3] = 255;
    }
  }
  const pixelOffset = (x, y) => {
    if (!Number.isInteger(x) || !Number.isInteger(y) || x < 0 || y < 0 || x >= width || y >= height) {
      throw new RangeError(`Invalid source pixel ${x},${y} in ${width}x${height}`);
    }
    return (y * width + x) * 4;
  };
  return { width, height, colorType, pixels,
    alpha: (x, y) => pixels[pixelOffset(x, y) + 3],
    channel: (x, y, channel) => pixels[pixelOffset(x, y) + channel] };
}

function rgbaPNG(file) {
  return decodePNG(file, { requireAlpha: true });
}

module.exports = { rgbaPNG, decodePNG };
