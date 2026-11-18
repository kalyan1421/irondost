import { Module } from '@nestjs/common';
import { AddressesModule } from '../addresses/addresses.module.js';
import { AdminAreaInterestController, AreaInterestController } from './area-interest.controller.js';
import { AreaInterestService } from './area-interest.service.js';

@Module({
  imports: [AddressesModule],
  controllers: [AreaInterestController, AdminAreaInterestController],
  providers: [AreaInterestService],
})
export class AreaInterestModule {}
