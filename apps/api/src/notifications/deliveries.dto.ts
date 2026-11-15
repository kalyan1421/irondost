import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsIn, IsOptional, IsString, Matches, MaxLength } from 'class-validator';
import { PageQueryDto } from '../common/pagination.js';
import { ClientApp, PushDeliveryStatus } from '../generated/prisma/enums.js';

export const FOLLOW_UP_FILTERS = ['OPEN', 'DONE', 'ALL'] as const;
export type FollowUpFilter = (typeof FOLLOW_UP_FILTERS)[number];

export class DeliveriesQuery extends PageQueryDto {
  @ApiPropertyOptional({
    enum: PushDeliveryStatus,
    enumName: 'PushDeliveryStatus',
    description: 'Only this outcome. Without it the list shows every alert that did not fully arrive (everything but SENT).',
  })
  @IsOptional()
  @IsEnum(PushDeliveryStatus)
  status?: PushDeliveryStatus;

  @ApiPropertyOptional({ enum: ClientApp, enumName: 'ClientApp', description: 'Which app the alert was for' })
  @IsOptional()
  @IsEnum(ClientApp)
  app?: ClientApp;

  @ApiPropertyOptional({ description: 'First day, YYYY-MM-DD (IST)' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  from?: string;

  @ApiPropertyOptional({ description: 'Last day, YYYY-MM-DD (IST)' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  to?: string;

  @ApiPropertyOptional({ description: 'Order number, or part of it' })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  orderNumber?: string;

  @ApiPropertyOptional({
    enum: FOLLOW_UP_FILTERS,
    enumName: 'DeliveryFollowUp',
    default: 'OPEN',
    description: 'OPEN: nobody has followed up yet (the default). DONE: followed up or retried. ALL: both.',
  })
  @IsOptional()
  @IsIn(FOLLOW_UP_FILTERS)
  followUp?: FollowUpFilter;
}

export class DeliveryRecipientDto {
  @ApiProperty() id!: string;
  @ApiProperty({ nullable: true, type: String }) name!: string | null;
  @ApiProperty({ nullable: true, type: String, description: 'E.164, e.g. +919876543210' }) phone!: string | null;
}

export class DeliveryDto {
  @ApiProperty() id!: string;
  @ApiProperty({ enum: PushDeliveryStatus, enumName: 'PushDeliveryStatus' }) status!: PushDeliveryStatus;
  @ApiProperty({ enum: ClientApp, enumName: 'ClientApp' }) app!: ClientApp;
  @ApiProperty({ description: 'Kind of alert, e.g. order_status, payment_received' }) type!: string;
  @ApiProperty({ description: 'Heading of the alert that was sent' }) title!: string;
  @ApiProperty({ description: 'Phones the person has registered for this app' }) deviceCount!: number;
  @ApiProperty({ description: 'How many of those phones refused it' }) failedCount!: number;
  @ApiProperty({ nullable: true, type: String, description: 'Firebase error code of the first failure' })
  errorCode!: string | null;
  @ApiProperty({ description: 'Why it did not arrive, in plain words' }) reason!: string;
  @ApiProperty({ type: DeliveryRecipientDto }) recipient!: DeliveryRecipientDto;
  @ApiProperty({ nullable: true, type: String }) orderId!: string | null;
  @ApiProperty({ nullable: true, type: String }) orderNumber!: string | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty({ nullable: true, type: Date }) handledAt!: Date | null;
  @ApiProperty({ nullable: true, type: String }) handledByName!: string | null;
  @ApiProperty({ description: 'False once it arrived, was already retried, or the notification is gone' })
  canRetry!: boolean;
  @ApiProperty({ nullable: true, type: String, description: 'Why Retry is not offered, in plain words' })
  retryBlockedReason!: string | null;
}

export class DeliveryPageDto {
  @ApiProperty({ type: [DeliveryDto] }) items!: DeliveryDto[];
  @ApiProperty() page!: number;
  @ApiProperty() pageSize!: number;
  @ApiProperty() total!: number;
}
