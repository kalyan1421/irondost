import { Body, Controller, Get, Module, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsUrl, Matches, MaxLength } from 'class-validator';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Public, Roles } from '../auth/decorators.js';
import type { AppVersion, User } from '../generated/prisma/client.js';
import { ClientApp, DevicePlatform, Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';

const SEMVER = /^\d+\.\d+\.\d+$/;

class AppVersionQuery {
  @ApiProperty({ enum: ClientApp, enumName: 'ClientApp' })
  @IsEnum(ClientApp)
  app!: ClientApp;

  @ApiProperty({ enum: DevicePlatform, enumName: 'DevicePlatform' })
  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;
}

export class UpsertAppVersionDto extends AppVersionQuery {
  @ApiProperty({ example: '1.0.0', description: 'Older versions are forced to update' })
  @Matches(SEMVER)
  minVersion!: string;

  @ApiProperty({ example: '1.2.0', description: 'Older versions see an optional update prompt' })
  @Matches(SEMVER)
  latestVersion!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl({ protocols: ['https'], require_protocol: true })
  storeUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  message?: string;
}

export class AppVersionDto {
  @ApiProperty({ enum: ClientApp, enumName: 'ClientApp' }) app!: ClientApp;
  @ApiProperty({ enum: DevicePlatform, enumName: 'DevicePlatform' }) platform!: DevicePlatform;
  @ApiProperty() minVersion!: string;
  @ApiProperty() latestVersion!: string;
  @ApiProperty({ nullable: true, type: String }) storeUrl!: string | null;
  @ApiProperty({ nullable: true, type: String }) message!: string | null;
}

const toDto = (v: AppVersion): AppVersionDto => ({
  app: v.app,
  platform: v.platform,
  minVersion: v.minVersion,
  latestVersion: v.latestVersion,
  storeUrl: v.storeUrl,
  message: v.message,
});

@ApiTags('app-versions')
@Controller('app-versions')
export class AppVersionsController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  /** Apps call this on launch: below minVersion → force update; below latestVersion → suggest update. */
  @Public()
  @Get()
  async get(@Query() q: AppVersionQuery): Promise<AppVersionDto | null> {
    const v = await this.prisma.appVersion.findUnique({ where: { app_platform: { app: q.app, platform: q.platform } } });
    return v ? toDto(v) : null;
  }

  @ApiBearerAuth()
  @Roles(Role.SUPER_ADMIN)
  @Put()
  async upsert(@CurrentUser() actor: User, @Body() dto: UpsertAppVersionDto): Promise<AppVersionDto> {
    const { app, platform, ...rest } = dto;
    const v = await this.prisma.appVersion.upsert({
      where: { app_platform: { app, platform } },
      create: dto,
      update: rest,
    });
    this.audit.log(actor.id, 'app_version.updated', 'app_version', v.id, dto);
    return toDto(v);
  }
}

@Module({ controllers: [AppVersionsController] })
export class AppVersionsModule {}
