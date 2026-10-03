import { randomUUID } from 'node:crypto';
import { Body, Controller, HttpCode, Module, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
import { APP_ENV } from '../config/config.module.js';
import type { Env } from '../config/env.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { createFileStorage, FileStorage } from './file-storage.js';
import { IMAGE_PURPOSES, ImageRejectedError, processImage, type ImagePurpose } from './image-processing.js';

export const MAX_UPLOAD_BYTES = 8 * 1024 * 1024;

export class ImageUploadBodyDto {
  @ApiProperty({ enum: IMAGE_PURPOSES, description: 'Decides the maximum size the image is scaled to' })
  @IsIn(IMAGE_PURPOSES)
  purpose!: ImagePurpose;
}

export class ImageUploadDto {
  @ApiProperty({ description: 'Public URL to save in imageUrl fields' }) url!: string;
  @ApiProperty() width!: number;
  @ApiProperty() height!: number;
  @ApiProperty({ description: 'Stored size in bytes' }) bytes!: number;
}

@ApiTags('admin · uploads')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/uploads')
export class UploadsController {
  constructor(
    private readonly storage: FileStorage,
    private readonly audit: AuditService,
  ) {}

  /** Upload an image (max 8 MB). It is cleaned, resized and stored as WebP; use the returned URL in imageUrl. */
  @Post('images')
  @HttpCode(201)
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file', 'purpose'],
      properties: { file: { type: 'string', format: 'binary' }, purpose: { type: 'string', enum: [...IMAGE_PURPOSES] } },
    },
  })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_UPLOAD_BYTES, files: 1 } }))
  async uploadImage(
    @CurrentUser() actor: User,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: ImageUploadBodyDto,
  ): Promise<ImageUploadDto> {
    if (!file?.buffer?.length) throw AppError.badRequest('FILE_REQUIRED', 'Choose an image to upload');

    let image;
    try {
      image = await processImage(file.buffer, body.purpose);
    } catch (err) {
      if (err instanceof ImageRejectedError) throw AppError.badRequest('INVALID_IMAGE', err.message);
      throw err;
    }

    const now = new Date();
    const key = `${body.purpose}/${now.getUTCFullYear()}/${String(now.getUTCMonth() + 1).padStart(2, '0')}/${randomUUID()}.webp`;
    await this.storage.put(key, image.data, 'image/webp');
    const url = this.storage.publicUrl(key);
    this.audit.log(actor.id, 'upload.image', 'upload', key, { purpose: body.purpose, bytes: image.data.length });
    return { url, width: image.width, height: image.height, bytes: image.data.length };
  }
}

@Module({
  controllers: [UploadsController],
  providers: [{ provide: FileStorage, inject: [APP_ENV], useFactory: (env: Env) => createFileStorage(env) }],
})
export class UploadsModule {}
