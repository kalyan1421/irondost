import { Module } from '@nestjs/common';
import { DispatchService } from '../dispatch/dispatch.service.js';
import { OrdersModule } from '../orders/orders.module.js';
import { PaymentsModule } from '../payments/payments.module.js';
import { AdminDriversController, DriverController } from './drivers.controller.js';
import { DriversService } from './drivers.service.js';

@Module({
  imports: [OrdersModule, PaymentsModule],
  controllers: [DriverController, AdminDriversController],
  providers: [DriversService, DispatchService],
})
export class DriversModule {}
