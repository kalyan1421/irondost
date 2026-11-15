import { Body, Controller, Get, HttpCode, Param, ParseUUIDPipe, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { AreaInterestDto, AreaInterestItemDto, AreaInterestOverviewDto, AreaInterestQuery, RegisterAreaInterestDto } from './area-interest.dto.js';
import { AreaInterestService } from './area-interest.service.js';

@ApiTags('area-interest')
@ApiBearerAuth()
@Roles(Role.CUSTOMER)
@Controller('me/area-interest')
export class AreaInterestController {
  constructor(private readonly interest: AreaInterestService) {}

  /**
   * "Tell me when you're here": for a saved address outside the service area. Uses the signed-in customer's own number.
   * Idempotent: asking again for the same PIN code returns the open request.
   */
  @Post()
  @HttpCode(200)
  register(@CurrentUser() user: User, @Body() dto: RegisterAreaInterestDto): Promise<AreaInterestDto> {
    return this.interest.register(user, dto.addressId);
  }
}

@ApiTags('admin · area interest')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/area-interest')
export class AdminAreaInterestController {
  constructor(
    private readonly interest: AreaInterestService,
    private readonly audit: AuditService,
  ) {}

  /** Who asked to be told when we reach them: counts by PIN code, locality and distance band, and the requests newest first. */
  @Get()
  overview(@Query() q: AreaInterestQuery): Promise<AreaInterestOverviewDto> {
    return this.interest.overview(q);
  }

  /** Staff have told this customer we now serve them. */
  @Post(':id/told')
  @HttpCode(200)
  async told(@CurrentUser() actor: User, @Param('id', ParseUUIDPipe) id: string): Promise<AreaInterestItemDto> {
    const { alreadyTold, ...item } = await this.interest.markTold(id);
    if (!alreadyTold) this.audit.log(actor.id, 'area_interest.told', 'area_interest', id, { customerId: item.customerId, pincode: item.pincode, locality: item.locality });
    return item;
  }
}
