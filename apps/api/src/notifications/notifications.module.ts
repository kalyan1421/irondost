import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller.js';
import { NotificationsListener } from './notifications.listener.js';
import { PushService } from './push.service.js';

@Module({
  controllers: [NotificationsController],
  providers: [PushService, NotificationsListener],
})
export class NotificationsModule {}
