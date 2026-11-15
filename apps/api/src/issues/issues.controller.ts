import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Module,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { ApiBearerAuth, ApiHeader, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser, Roles } from '../auth/decorators.js';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { Role } from '../generated/prisma/enums.js';
import { UploadsModule } from '../uploads/uploads.controller.js';
import {
  CreateIssueDto,
  IssueDto,
  IssueMessageBodyDto,
  IssuePageDto,
  IssuesQuery,
  UpdateIssueDto,
} from './issue.dto.js';
import { IssuesService } from './issues.service.js';

@ApiTags('issues')
@ApiBearerAuth()
@Roles(Role.CUSTOMER)
@Controller()
export class CustomerIssuesController {
  constructor(private readonly issues: IssuesService) {}
  @Post('orders/:id/issues')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiHeader({
    name: 'Idempotency-Key',
    required: false,
    description: 'Reuse one key to retry the same report after a lost response.',
  })
  async create(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateIssueDto,
    @Headers('idempotency-key') key: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ): Promise<IssueDto> {
    if (key !== undefined && !/^[A-Za-z0-9_-]{8,100}$/.test(key))
      throw AppError.badRequest('INVALID_IDEMPOTENCY_KEY', 'Use an 8–100 character request key.');
    const result = await this.issues.create(user, id, dto, key);
    if (result.replayed) res.setHeader('Idempotent-Replayed', 'true');
    return result.issue;
  }
  @Get('me/issues')
  list(@CurrentUser() user: User, @Query() q: IssuesQuery): Promise<IssuePageDto> {
    return this.issues.list(user, q);
  }
  @Get('me/issues/:id')
  get(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<IssueDto> {
    return this.issues.get(user, id);
  }
  @Post('me/issues/:id/messages')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  message(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: IssueMessageBodyDto,
  ): Promise<IssueDto> {
    return this.issues.message(user, id, dto.body);
  }
}
@ApiTags('admin · reports')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/issues')
export class AdminIssuesController {
  constructor(private readonly issues: IssuesService) {}
  @Get()
  list(@CurrentUser() user: User, @Query() q: IssuesQuery): Promise<IssuePageDto> {
    return this.issues.list(user, q);
  }
  @Get(':id')
  get(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<IssueDto> {
    return this.issues.get(user, id);
  }
  @Patch(':id')
  update(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateIssueDto,
  ): Promise<IssueDto> {
    return this.issues.update(user, id, dto);
  }
  @Post(':id/messages')
  @HttpCode(200)
  message(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: IssueMessageBodyDto,
  ): Promise<IssueDto> {
    return this.issues.message(user, id, dto.body);
  }
}
@Module({
  imports: [UploadsModule],
  controllers: [CustomerIssuesController, AdminIssuesController],
  providers: [IssuesService],
  exports: [IssuesService],
})
export class IssuesModule {}
