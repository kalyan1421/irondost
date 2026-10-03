import { Module } from '@nestjs/common';
import { AdminPromotionsController, PromotionsController } from './promotions.controller.js';

@Module({ controllers: [PromotionsController, AdminPromotionsController] })
export class PromotionsModule {}
