import sharp from 'sharp';

export const IMAGE_PURPOSES = ['catalog', 'promotion', 'banner'] as const;
export type ImagePurpose = (typeof IMAGE_PURPOSES)[number];

/** Largest size kept for each use; bigger images are scaled down, smaller ones are left alone. */
export const MAX_SIZE: Record<ImagePurpose, { width: number; height: number }> = {
  catalog: { width: 800, height: 800 },
  promotion: { width: 1200, height: 1200 },
  banner: { width: 1600, height: 1600 },
};

const ACCEPTED_FORMATS = new Set(['jpeg', 'png', 'webp', 'avif', 'gif']);

export class ImageRejectedError extends Error {}

export interface ProcessedImage {
  data: Buffer;
  width: number;
  height: number;
}

/**
 * Decodes the upload (so a renamed non-image fails here), applies the camera
 * orientation, drops all metadata (EXIF, including GPS location), scales it
 * down for its use and re-encodes it as WebP.
 */
export async function processImage(input: Buffer, purpose: ImagePurpose): Promise<ProcessedImage> {
  let format: string | undefined;
  try {
    format = (await sharp(input).metadata()).format;
  } catch {
    throw new ImageRejectedError('This file is not an image we can read');
  }
  if (!format || !ACCEPTED_FORMATS.has(format)) {
    throw new ImageRejectedError('Upload a JPG, PNG, WebP, AVIF or GIF image');
  }

  const { width, height } = MAX_SIZE[purpose];
  const { data, info } = await sharp(input, { limitInputPixels: 40_000_000 })
    .rotate()
    .resize({ width, height, fit: 'inside', withoutEnlargement: true })
    .webp({ quality: 82 })
    .toBuffer({ resolveWithObject: true });
  return { data, width: info.width, height: info.height };
}
