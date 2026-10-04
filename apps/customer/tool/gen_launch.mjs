// Run from the repository: node apps/customer/tool/gen_launch.mjs.
// Uses the existing brand rasterizer dependency and the outlined wordmark assets.
import { createRequire } from 'node:module';
import { readFile, writeFile } from 'node:fs/promises';
const require = createRequire(new URL('../../../packages/brand/package.json', import.meta.url));
const sharp = require('sharp');
const app = new URL('../', import.meta.url);
for (const dark of [false, true]) {
  for (const scale of [1, 2, 3]) {
    const suffix = `${dark ? '-dark' : ''}${scale === 1 ? '' : `@${scale}x`}`;
    await sharp(new URL(`assets/brand/irondost-wordmark${dark ? '-reverse' : ''}.png`, app).pathname)
      .resize({ height: 32 * scale })
      .png()
      .toFile(new URL(`ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage${suffix}.png`, app).pathname);
  }
}
const meta = await sharp(new URL('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png', app).pathname).metadata();
const path = new URL('ios/Runner/Base.lproj/LaunchScreen.storyboard', app);
const source = await readFile(path, 'utf8');
await writeFile(path, source
  .replace(/<rect key="frame" x="56" y="390" width="281" height="72"\/>/, `<rect key="frame" x="${(393 - meta.width) / 2}" y="410" width="${meta.width}" height="32"/>`)
  .replace(/<image name="LaunchImage" width="\d+" height="\d+"\/>/, `<image name="LaunchImage" width="${meta.width}" height="32"/>`));
