import { Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Public, Roles } from '../auth/decorators.js';
import { Clock } from '../common/clock.js';
import { AppError } from '../common/errors.js';
import { DeleteResultDto } from '../common/pagination.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreatePromotionDto, PromotionDto, toPromotionDto, UpdatePromotionDto } from './promotion.dto.js';

@ApiTags('promotions')
@Controller('promotions')
export class PromotionsController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  /** Promotions currently running, for the home screen. Codes are validated when quoting an order. */
  @Public()
  @Get()
  async active(): Promise<PromotionDto[]> {
    const now = this.clock.now();
    const rows = await this.prisma.promotion.findMany({
      where: { isActive: true, validFrom: { lte: now }, validTo: { gt: now } },
      orderBy: { validTo: 'asc' },
    });
    return rows.map(toPromotionDto);
  }
}

@ApiTags('admin · promotions')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/promotions')
export class AdminPromotionsController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  @Get()
  async list(): Promise<PromotionDto[]> {
    const rows = await this.prisma.promotion.findMany({ orderBy: { createdAt: 'desc' } });
    return rows.map(toPromotionDto);
  }

  @Post()
  async create(@CurrentUser() actor: User, @Body() dto: CreatePromotionDto): Promise<PromotionDto> {
    validate(dto.discountType, dto.discountValue, dto.validFrom, dto.validTo);
    const p = await this.prisma.promotion.create({ data: dto });
    this.audit.log(actor.id, 'promotion.created', 'promotion', p.id, dto);
    return toPromotionDto(p);
  }

  @Patch(':id')
  async update(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePromotionDto,
  ): Promise<PromotionDto> {
    const current = await this.prisma.promotion.findUnique({ where: { id } });
    if (!current) throw AppError.notFound('Promotion');
    validate(
      dto.discountType ?? current.discountType,
      dto.discountValue ?? current.discountValue,
      dto.validFrom ?? current.validFrom,
      dto.validTo ?? current.validTo,
    );
    const p = await this.prisma.promotion.update({ where: { id }, data: dto });
    this.audit.log(actor.id, 'promotion.updated', 'promotion', id, dto);
    return toPromotionDto(p);
  }

  /** Used promotions are deactivated instead of deleted. */
  @Delete(':id')
  async remove(@CurrentUser() actor: User, @Param('id', ParseUUIDPipe) id: string): Promise<DeleteResultDto> {
    const used = await this.prisma.order.count({ where: { promotionId: id } });
    if (used > 0) await this.prisma.promotion.update({ where: { id }, data: { isActive: false } });
    else await this.prisma.promotion.delete({ where: { id } });
    this.audit.log(actor.id, used > 0 ? 'promotion.deactivated' : 'promotion.deleted', 'promotion', id);
    return { deleted: used === 0 };
  }
}

function validate(type: string, value: number, from: Date, to: Date): void {
  if (type === 'PERCENT' && (value < 1 || value > 100)) {
    throw AppError.badRequest('INVALID_DISCOUNT', 'Percentage discount must be between 1 and 100');
  }
  if (to <= from) throw AppError.badRequest('INVALID_WINDOW', 'validTo must be after validFrom');
}
