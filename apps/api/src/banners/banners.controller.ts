import { Body, Controller, Delete, Get, HttpCode, Module, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, MaxLength, Min, ValidateIf } from 'class-validator';
import { blankToNull } from '../common/transforms.js';
import { IsImageUrl } from '../common/validators.js';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Public, Roles } from '../auth/decorators.js';
import type { Banner, User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';

export class CreateBannerDto {
  @ApiProperty()
  @IsImageUrl()
  imageUrl!: string;

  @ApiPropertyOptional({ nullable: true, type: String })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(80)
  title?: string | null;

  @ApiPropertyOptional({ nullable: true, type: String, description: 'Deep link or web URL opened on tap' })
  @IsOptional()
  @Transform(blankToNull)
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(300)
  linkUrl?: string | null;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateBannerDto extends PartialType(CreateBannerDto) {}

export class BannerDto {
  @ApiProperty() id!: string;
  @ApiProperty() imageUrl!: string;
  @ApiProperty({ nullable: true, type: String }) title!: string | null;
  @ApiProperty({ nullable: true, type: String }) linkUrl!: string | null;
  @ApiProperty() sortOrder!: number;
  @ApiProperty() isActive!: boolean;
}

const toDto = (b: Banner): BannerDto => ({
  id: b.id,
  imageUrl: b.imageUrl,
  title: b.title,
  linkUrl: b.linkUrl,
  sortOrder: b.sortOrder,
  isActive: b.isActive,
});

@ApiTags('banners')
@Controller('banners')
export class BannersController {
  constructor(private readonly prisma: PrismaService) {}

  @Public()
  @Get()
  async active(): Promise<BannerDto[]> {
    const rows = await this.prisma.banner.findMany({ where: { isActive: true }, orderBy: { sortOrder: 'asc' } });
    return rows.map(toDto);
  }
}

@ApiTags('admin · banners')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/banners')
export class AdminBannersController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  @Get()
  async list(): Promise<BannerDto[]> {
    return (await this.prisma.banner.findMany({ orderBy: { sortOrder: 'asc' } })).map(toDto);
  }

  @Post()
  async create(@CurrentUser() actor: User, @Body() dto: CreateBannerDto): Promise<BannerDto> {
    const b = await this.prisma.banner.create({ data: dto });
    this.audit.log(actor.id, 'banner.created', 'banner', b.id, dto);
    return toDto(b);
  }

  @Patch(':id')
  async update(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBannerDto,
  ): Promise<BannerDto> {
    const b = await this.prisma.banner.update({ where: { id }, data: dto });
    this.audit.log(actor.id, 'banner.updated', 'banner', id, dto);
    return toDto(b);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@CurrentUser() actor: User, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.prisma.banner.delete({ where: { id } });
    this.audit.log(actor.id, 'banner.deleted', 'banner', id);
  }
}

@Module({ controllers: [BannersController, AdminBannersController] })
export class BannersModule {}
