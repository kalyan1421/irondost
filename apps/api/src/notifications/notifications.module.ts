import { Module } from '@nestjs/common';
import { NotificationDeliveriesController } from './deliveries.controller.js';
import { NotificationDeliveriesService } from './deliveries.service.js';
import { NotificationsController } from './notifications.controller.js';
import { NotificationsListener } from './notifications.listener.js';
import { PushService } from './push.service.js';

@Module({
  controllers: [NotificationsController, NotificationDeliveriesController],
  providers: [PushService, NotificationsListener, NotificationDeliveriesService],
})
export class NotificationsModule {}
