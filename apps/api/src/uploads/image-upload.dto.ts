import { ApiProperty } from '@nestjs/swagger';

export class ImageUploadDto {
  @ApiProperty({ description: 'Public URL to save in imageUrl fields' }) url!: string;
  @ApiProperty() width!: number;
  @ApiProperty() height!: number;
  @ApiProperty({ description: 'Stored size in bytes' }) bytes!: number;
}
