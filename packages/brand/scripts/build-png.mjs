// Rasterises the SVGs from build-svg.py into logo PNGs, app icons, favicons
// and social images. Run after build-svg.py: `pnpm --filter @laundry/brand build:png`.
import { copyFile, mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = (p) => join(root, p);

/** Width of the SVG at 72 dpi: its width attribute, else its viewBox width. */
function intrinsicWidth(svg) {
  const width = svg.match(/<svg[^>]*\swidth="([\d.]+)"/);
  return width ? Number(width[1]) : Number(svg.match(/viewBox="[^"]*"/)[0].split(/[\s"]+/)[3]);
}

/** Render an SVG file to a PNG buffer `width` pixels wide, rasterised at that size. */
async function render(file, width, { opaque } = {}) {
  const svg = await readFile(src(file), "utf8");
  let img = sharp(Buffer.from(svg), { density: (72 * width) / intrinsicWidth(svg) }).resize({ width });
  if (opaque) img = img.flatten({ background: opaque }).removeAlpha();
  return img.png({ compressionLevel: 9 }).toBuffer();
}

async function out(path, buffer) {
  await mkdir(dirname(src(path)), { recursive: true });
  await writeFile(src(path), buffer);
}

/** Pack PNGs into a .ico (PNG-compressed entries, supported by every current browser). */
function ico(images) {
  const header = Buffer.alloc(6 + 16 * images.length);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(images.length, 4);
  let offset = header.length;
  images.forEach(({ size, data }, i) => {
    const e = 6 + 16 * i;
    header.writeUInt8(size >= 256 ? 0 : size, e);
    header.writeUInt8(size >= 256 ? 0 : size, e + 1);
    header.writeUInt16LE(1, e + 4);
    header.writeUInt16LE(32, e + 6);
    header.writeUInt32LE(data.length, e + 8);
    header.writeUInt32LE(offset, e + 12);
    offset += data.length;
  });
  return Buffer.concat([header, ...images.map((i) => i.data)]);
}

// Every icon sits on white.
const BG = "#FFFFFF";

// Logos: one high-resolution transparent PNG per SVG.
const logoWidths = { "logo-stacked": 1600, "mark-small": 512, mark: 1024, wordmark: 2000, logo: 2400 };
for (const file of await readdir(src("logo/svg"))) {
  const name = file.replace(/\.svg$/, "");
  const key = Object.keys(logoWidths).find((k) => name.startsWith(`irondost-${k}`));
  await out(`logo/png/${name}.png`, await render(`logo/svg/${file}`, logoWidths[key]));
}

// iOS: Xcode 14+ takes a single 1024px opaque icon.
const appIcon = await render("icons/src/app-icon.svg", 1024, { opaque: BG });
await out("icons/ios/AppIcon.appiconset/AppIcon-1024.png", appIcon);
await out(
  "icons/ios/AppIcon.appiconset/Contents.json",
  JSON.stringify(
    {
      images: [{ filename: "AppIcon-1024.png", idiom: "universal", platform: "ios", size: "1024x1024" }],
      info: { author: "xcode", version: 1 },
    },
    null,
    2,
  ) + "\n",
);

// Android: adaptive icon layers (background is solid white), Play Store
// listing icon, and the white status-bar notification icon per density.
await out("icons/android/play-store-512.png", await render("icons/src/app-icon.svg", 512, { opaque: BG }));
await out("icons/android/adaptive-foreground-1024.png", await render("icons/src/adaptive-foreground.svg", 1024));
await out("icons/android/adaptive-monochrome-1024.png", await render("icons/src/adaptive-monochrome.svg", 1024));
for (const [density, size] of Object.entries({ mdpi: 24, hdpi: 36, xhdpi: 48, xxhdpi: 72, xxxhdpi: 96 })) {
  await out(`icons/android/notification/drawable-${density}/ic_stat_irondost.png`, await render("icons/src/notification.svg", size));
}

// Web: favicon.ico (washer glyph at 16px, simplified mark above), SVG favicon,
// Apple touch icon and PWA icons.
await out(
  "icons/web/favicon.ico",
  ico([
    { size: 16, data: await render("icons/src/favicon-tiny.svg", 16) },
    { size: 32, data: await render("icons/src/favicon.svg", 32) },
    { size: 48, data: await render("icons/src/favicon.svg", 48) },
  ]),
);
await copyFile(src("icons/src/favicon.svg"), src("icons/web/favicon.svg"));
await out("icons/web/apple-touch-icon.png", await render("icons/src/app-icon.svg", 180, { opaque: BG }));
await out("icons/web/icon-192.png", await render("icons/src/app-icon.svg", 192, { opaque: BG }));
await out("icons/web/icon-512.png", await render("icons/src/app-icon.svg", 512, { opaque: BG }));
await out("icons/web/icon-maskable-512.png", await render("icons/src/maskable.svg", 512, { opaque: BG }));

// Social.
await out("social/avatar-1080.png", await render("icons/src/social-avatar.svg", 1080, { opaque: BG }));
await out("social/og-image-1200x630.png", await render("icons/src/og-image.svg", 1200, { opaque: BG }));

console.log("PNG export done.");
