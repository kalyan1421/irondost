import { randomUUID } from 'node:crypto';
import { Controller, HttpStatus, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser, Roles } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { CARE_PHOTOS_PER_DAY, carePhotoPrefix } from '../orders/care-note.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { FileStorage } from './file-storage.js';
import { ImageRejectedError, processImage, type ProcessedImage } from './image-processing.js';
import { ImageUploadDto } from './image-upload.dto.js';

@ApiTags('uploads')
@ApiBearerAuth()
@Roles(Role.CUSTOMER)
@Controller('me/uploads')
export class CustomerUploadsController {
  constructor(
    private readonly storage: FileStorage,
    private readonly prisma: PrismaService,
  ) {}
  @Post('images')
  @Throttle({ default: { limit: 6, ttl: 60_000 } })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: { type: 'object', required: ['file'], properties: { file: { type: 'string', format: 'binary' } } },
  })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 8 * 1024 * 1024, files: 1, fields: 0 } }))
  async upload(
    @CurrentUser() user: User,
    @UploadedFile() file: Express.Multer.File | undefined,
  ): Promise<ImageUploadDto> {
    const image = await this.cleaned(file);
    const id = randomUUID();
    const key = `issues/${user.id}/${id}.webp`;
    const day = new Date();
    day.setUTCHours(0, 0, 0, 0);
    await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM users WHERE id = ${user.id}::uuid FOR UPDATE`;
      const count = await tx.issuePhoto.count({ where: { userId: user.id, createdAt: { gte: day } } });
      if (count >= 20)
        throw new AppError(
          HttpStatus.TOO_MANY_REQUESTS,
          'PHOTO_LIMIT',
          'You can upload 20 report photos per day. Contact support if you need help.',
        );
      await tx.issuePhoto.create({ data: { id, userId: user.id, key } });
    });
    try {
      await this.storage.put(key, image.data, 'image/webp');
    } catch (e) {
      await this.prisma.issuePhoto.delete({ where: { id } });
      throw e;
    }
    return { url: this.storage.publicUrl(key), width: image.width, height: image.height, bytes: image.data.length };
  }

  /**
   * A photo of the clothes for a care note, added before the order exists. Same image limits as report photos. It stays free
   * until an order is placed with its URL; one photo goes to one order, up to 3 on each order.
   */
  @Post('care-photos')
  @Throttle({ default: { limit: 6, ttl: 60_000 } })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: { type: 'object', required: ['file'], properties: { file: { type: 'string', format: 'binary' } } },
  })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 8 * 1024 * 1024, files: 1, fields: 0 } }))
  async uploadCarePhoto(
    @CurrentUser() user: User,
    @UploadedFile() file: Express.Multer.File | undefined,
  ): Promise<ImageUploadDto> {
    const image = await this.cleaned(file);
    const id = randomUUID();
    const key = `${carePhotoPrefix(user.id)}${id}.webp`;
    const day = new Date();
    day.setUTCHours(0, 0, 0, 0);
    await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM users WHERE id = ${user.id}::uuid FOR UPDATE`;
      const count = await tx.orderCarePhoto.count({ where: { userId: user.id, createdAt: { gte: day } } });
      if (count >= CARE_PHOTOS_PER_DAY)
        throw new AppError(
          HttpStatus.TOO_MANY_REQUESTS,
          'PHOTO_LIMIT',
          `You can add ${CARE_PHOTOS_PER_DAY} photos to care notes per day. Contact support if you need help.`,
        );
      await tx.orderCarePhoto.create({ data: { id, userId: user.id, key } });
    });
    try {
      await this.storage.put(key, image.data, 'image/webp');
    } catch (e) {
      await this.prisma.orderCarePhoto.delete({ where: { id } });
      throw e;
    }
    return { url: this.storage.publicUrl(key), width: image.width, height: image.height, bytes: image.data.length };
  }

  /** Decodes, orients, strips metadata from and resizes the upload; a file that is not a readable image is refused. */
  private async cleaned(file: Express.Multer.File | undefined): Promise<ProcessedImage> {
    if (!file?.buffer?.length) throw AppError.badRequest('FILE_REQUIRED', 'Choose an image.');
    try {
      return await processImage(file.buffer, 'promotion');
    } catch (e) {
      if (e instanceof ImageRejectedError) throw AppError.badRequest('INVALID_IMAGE', e.message);
      throw e;
    }
  }
}
