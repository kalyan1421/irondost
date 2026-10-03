import { Body, Controller, Get, Headers, HttpCode, Param, ParseUUIDPipe, Post, Req, UnauthorizedException } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import { ApiBearerAuth, ApiExcludeEndpoint, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { IsInt, IsString, Length, Min } from 'class-validator';
import type { Request } from 'express';
import { AuditService } from '../audit/audit.service.js';
import { CurrentUser, Public, Roles } from '../auth/decorators.js';
import type { Payment, User } from '../generated/prisma/client.js';
import { PaymentProvider, PaymentRecordStatus, Role } from '../generated/prisma/enums.js';
import { PaymentsService } from './payments.service.js';

export class VerifyCheckoutDto {
  @ApiProperty() @IsString() @Length(5, 100) razorpayOrderId!: string;
  @ApiProperty() @IsString() @Length(5, 100) razorpayPaymentId!: string;
  @ApiProperty() @IsString() @Length(10, 200) razorpaySignature!: string;
}

class CheckoutPrefillDto {
  @ApiProperty({ nullable: true, type: String }) name!: string | null;
  @ApiProperty() contact!: string;
  @ApiProperty({ nullable: true, type: String }) email!: string | null;
}

/** Everything Razorpay Checkout needs on the device. */
export class CheckoutParamsDto {
  @ApiProperty() keyId!: string;
  @ApiProperty() razorpayOrderId!: string;
  @ApiProperty() amountPaise!: number;
  @ApiProperty({ enum: ['INR'] }) currency!: 'INR';
  @ApiProperty() orderNumber!: string;
  @ApiProperty({ type: CheckoutPrefillDto }) prefill!: CheckoutPrefillDto;
}

export class PaymentStatusDto {
  @ApiProperty() paymentStatus!: string;
}

export class RecordCashDto {
  @ApiProperty({ description: 'Amount received, in paise' })
  @IsInt()
  @Min(1)
  amountPaise!: number;
}

export class PaymentDto {
  @ApiProperty() id!: string;
  @ApiProperty({ enum: PaymentProvider, enumName: 'PaymentProvider' }) provider!: PaymentProvider;
  @ApiProperty({ enum: PaymentRecordStatus, enumName: 'PaymentRecordStatus' }) status!: PaymentRecordStatus;
  @ApiProperty() amountPaise!: number;
  @ApiPropertyOptional({ nullable: true, type: String }) razorpayPaymentId!: string | null;
  @ApiProperty() createdAt!: Date;
}

const toDto = (p: Payment): PaymentDto => ({
  id: p.id,
  provider: p.provider,
  status: p.status,
  amountPaise: p.amountPaise,
  razorpayPaymentId: p.razorpayPaymentId,
  createdAt: p.createdAt,
});

@ApiTags('payments')
@ApiBearerAuth()
@Roles(Role.CUSTOMER)
@Controller()
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  /** Returns the parameters for Razorpay Checkout on the device. */
  @Post('orders/:id/payments/razorpay')
  createRazorpayOrder(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<CheckoutParamsDto> {
    return this.payments.createRazorpayOrder(user, id);
  }

  @Post('payments/razorpay/verify')
  @HttpCode(200)
  verify(@CurrentUser() user: User, @Body() dto: VerifyCheckoutDto): Promise<PaymentStatusDto> {
    return this.payments.verifyCheckout(user, dto.razorpayOrderId, dto.razorpayPaymentId, dto.razorpaySignature);
  }
}

@ApiTags('webhooks')
@Public()
@SkipThrottle()
@Controller('webhooks')
export class WebhooksController {
  constructor(private readonly payments: PaymentsService) {}

  @ApiExcludeEndpoint()
  @Post('razorpay')
  @HttpCode(200)
  async razorpay(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-razorpay-signature') signature?: string,
  ): Promise<{ ok: true }> {
    if (!(await this.payments.handleWebhook(req.rawBody, signature))) {
      throw new UnauthorizedException('Invalid signature');
    }
    return { ok: true };
  }
}

@ApiTags('admin · payments')
@ApiBearerAuth()
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('admin/orders/:id/payments')
export class AdminPaymentsController {
  constructor(
    private readonly payments: PaymentsService,
    private readonly audit: AuditService,
  ) {}

  @Get()
  async list(@Param('id', ParseUUIDPipe) id: string): Promise<PaymentDto[]> {
    return (await this.payments.listForOrder(id)).map(toDto);
  }

  @Post('cash')
  @HttpCode(204)
  async recordCash(
    @CurrentUser() actor: User,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RecordCashDto,
  ): Promise<void> {
    await this.payments.recordCash(id, dto.amountPaise, actor);
    this.audit.log(actor.id, 'payment.cash_recorded', 'order', id, dto);
  }
}
