import sharp from 'sharp';
import { isImageUrl, setUploadsBaseUrl } from '../common/validators.js';
import { ImageRejectedError, processImage } from './image-processing.js';

const photo = (width: number, height: number) =>
  sharp({ create: { width, height, channels: 3, background: { r: 200, g: 120, b: 40 } } });

describe('processImage', () => {
  it('scales large banners down to fit and re-encodes as WebP', async () => {
    const input = await photo(3200, 1800).jpeg().toBuffer();
    const out = await processImage(input, 'banner');
    expect(out).toMatchObject({ width: 1600, height: 900 });
    expect((await sharp(out.data).metadata()).format).toBe('webp');
  });

  it('never enlarges small images', async () => {
    const out = await processImage(await photo(300, 200).png().toBuffer(), 'catalog');
    expect(out).toMatchObject({ width: 300, height: 200 });
  });

  it('strips camera metadata such as GPS location', async () => {
    const input = await photo(400, 300)
      .jpeg()
      .withExif({ IFD0: { Copyright: 'Customer phone', Model: 'Pixel' }, IFD3: { GPSLatitudeRef: 'N' } })
      .toBuffer();
    expect((await sharp(input).metadata()).exif).toBeDefined();
    const out = await processImage(input, 'promotion');
    expect((await sharp(out.data).metadata()).exif).toBeUndefined();
  });

  it('rejects files that are not images, whatever their name', async () => {
    await expect(processImage(Buffer.from('<svg onload="alert(1)"/>'), 'banner')).rejects.toBeInstanceOf(ImageRejectedError);
    await expect(processImage(Buffer.from('plain text pretending to be a png'), 'catalog')).rejects.toBeInstanceOf(
      ImageRejectedError,
    );
  });
});

describe('isImageUrl', () => {
  it('accepts https links and our own uploads, nothing else', () => {
    setUploadsBaseUrl('http://localhost:4000/uploads/');
    expect(isImageUrl('https://cdn.example.com/a.webp')).toBe(true);
    expect(isImageUrl('http://localhost:4000/uploads/banner/2026/10/x.webp')).toBe(true);
    expect(isImageUrl('http://example.com/a.png')).toBe(false);
    expect(isImageUrl('http://localhost:4000/uploadsevil/x.webp')).toBe(false);
    expect(isImageUrl('javascript:alert(1)')).toBe(false);
    expect(isImageUrl(42)).toBe(false);
  });
});
