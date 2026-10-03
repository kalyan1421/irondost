import { Module } from '@nestjs/common';
import { AddressesModule } from '../addresses/addresses.module.js';
import { AdminOrdersController } from './admin-orders.controller.js';
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';

@Module({
  imports: [AddressesModule],
  controllers: [OrdersController, AdminOrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
