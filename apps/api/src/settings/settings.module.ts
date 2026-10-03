import { Global, Module } from '@nestjs/common';
import { Clock } from '../common/clock.js';
import { SchedulingController } from '../scheduling/scheduling.controller.js';
import { PublicConfigController } from './public-config.controller.js';
import { ServiceAreaController } from './service-area.controller.js';
import { SettingsService } from './settings.service.js';

@Global()
@Module({
  controllers: [SchedulingController, PublicConfigController, ServiceAreaController],
  providers: [SettingsService, Clock],
  exports: [SettingsService, Clock],
})
export class SettingsModule {}
