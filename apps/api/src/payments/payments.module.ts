import { Module } from '@nestjs/common';
import { AdminPaymentsController, PaymentsController, WebhooksController } from './payments.controller.js';
import { PaymentsService } from './payments.service.js';
import { RazorpayGateway, RazorpaySdkGateway } from './razorpay.gateway.js';
import { AdminRefundsController } from './refunds.controller.js';
import { RefundsService } from './refunds.service.js';

@Module({
  controllers: [PaymentsController, WebhooksController, AdminPaymentsController, AdminRefundsController],
  providers: [PaymentsService, RefundsService, { provide: RazorpayGateway, useClass: RazorpaySdkGateway }],
  exports: [PaymentsService],
})
export class PaymentsModule {}
