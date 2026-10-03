import { Module } from '@nestjs/common';
import { AddressesModule } from '../addresses/addresses.module.js';
import { AdminController, AdminStaffController } from './admin.controller.js';
import { AdminService } from './admin.service.js';

@Module({
  imports: [AddressesModule],
  controllers: [AdminController, AdminStaffController],
  providers: [AdminService],
})
export class AdminModule {}
