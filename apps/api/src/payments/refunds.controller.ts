import { Body, Controller, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEnum, IsInt, IsString, Length, Min } from 'class-validator';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Roles } from '../auth/decorators.js';
import { rupees } from '../common/money.js';
import type { User } from '../generated/prisma/client.js';
import { RefundMethod, Role } from '../generated/prisma/enums.js';
import { OrderDto, toOrderDto } from '../orders/order.dto.js';
import { gatewayError, RefundsService } from './refunds.service.js';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class CreateRefundDto {
  @ApiProperty({ description: 'Amount to refund, in paise. At most what was paid minus earlier refunds.', minimum: 1 })
  @IsInt()
  @Min(1)
  amountPaise!: number;

  @ApiProperty({
    enum: RefundMethod,
    enumName: 'RefundMethod',
    description:
      'RAZORPAY sends the money back to the card/UPI the customer paid with. ' +
      'CASH and BANK_TRANSFER record money staff already returned outside the app.',
  })
  @IsEnum(RefundMethod)
  method!: RefundMethod;

  @ApiProperty({ minLength: 3, maxLength: 500, description: 'Shown to the customer in the app and in their notification' })
  @Transform(trim)
  @IsString()
  @Length(3, 500)
  note!: string;
}

@ApiTags('admin · orders')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/orders/:id/refunds')
export class AdminRefundsController {
  constructor(
    private readonly refunds: RefundsService,
    private readonly audit: AuditService,
  ) {}

  @ApiOperation({
    summary: 'Refund money on an order, with a note the customer sees. Works in any status.',
    description:
      'Errors: NOTHING_TO_REFUND, REFUND_EXCEEDS_PAID and REFUND_EXCEEDS_ONLINE_PAID (409, details.refundablePaise), ' +
      "NO_ONLINE_PAYMENT (409), REFUND_GATEWAY_ERROR (502, with Razorpay's message; nothing is saved).",
  })
  @Post()
  async create(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateRefundDto,
  ): Promise<OrderDto> {
    const outcome = await this.refunds.refund(id, dto, actor);
    this.audit.log(actor.id, 'order.refunded', 'order', id, {
      amountPaise: outcome.refundedPaise,
      requestedPaise: dto.amountPaise,
      method: dto.method,
      note: dto.note,
      refundIds: outcome.refundIds,
    });
    if (outcome.gatewayError) {
      // Part of a split Razorpay refund went through; the rest was refused.
      throw gatewayError(
        `Refunded ${rupees(outcome.refundedPaise)} of ${rupees(dto.amountPaise)}. Razorpay refused the rest: ${outcome.gatewayError}`,
      );
    }
    return toOrderDto(outcome.order, 'ADMIN');
  }
}
