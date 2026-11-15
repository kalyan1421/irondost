import { ApiProperty, ApiPropertyOptional, OmitType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { PageQueryDto } from '../common/pagination.js';
import { customerPhone } from '../common/phone.js';
import { fromDbDate } from '../common/time.js';
import type { Order, OrderAdjustment, OrderCarePhoto, OrderEvent, OrderItem, Payment, Refund, User } from '../generated/prisma/client.js';
import {
  ItemUnit,
  AdjustmentStatus,
  OrderSource,
  OrderStatus,
  PaymentMethod,
  PaymentProvider,
  PaymentStatus,
  RefundMethod,
  RefundStatus,
  Role,
  TimeSlot,
} from '../generated/prisma/enums.js';
import { slotLabel } from '../scheduling/schedule-rules.js';
import { CARE_NOTE_MAX, CARE_PHOTOS_PER_ORDER, carePhotoUrl } from './care-note.js';
import { nextStatuses, type ActorKind } from './order-state.js';
import { refundablePaise } from './refund-due.js';
import { canReschedule, reschedulesRemaining } from './reschedule.js';

// ───────────── Requests ─────────────

export class OrderLineInput {
  @ApiProperty()
  @IsUUID()
  catalogItemId!: string;

  @ApiProperty({ minimum: 1, maximum: 500 })
  @IsInt()
  @Min(1)
  @Max(500)
  quantity!: number;
}

const upper = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toUpperCase() : value);

export class QuoteRequestDto {
  @ApiProperty({ type: [OrderLineInput] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => OrderLineInput)
  items!: OrderLineInput[];

  @ApiPropertyOptional({ example: 'FIRST50' })
  @IsOptional()
  @Transform(upper)
  @IsString()
  @MaxLength(20)
  promoCode?: string;
}

export class PlaceOrderDto extends QuoteRequestDto {
  @ApiProperty({ example: '2026-10-05', description: 'IST calendar date' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  pickupDate!: string;

  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' })
  @IsEnum(TimeSlot)
  pickupSlot!: TimeSlot;

  @ApiProperty({ example: '2026-10-06' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  deliveryDate!: string;

  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' })
  @IsEnum(TimeSlot)
  deliverySlot!: TimeSlot;

  @ApiProperty()
  @IsUUID()
  pickupAddressId!: string;

  @ApiPropertyOptional({ description: 'Defaults to the pickup address' })
  @IsOptional()
  @IsUUID()
  deliveryAddressId?: string;

  @ApiProperty({ enum: PaymentMethod, enumName: 'PaymentMethod' })
  @IsEnum(PaymentMethod)
  paymentMethod!: PaymentMethod;

  @ApiPropertyOptional({ example: 'Please call before arriving' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  instructions?: string;

  @ApiPropertyOptional({
    example: 'Red silk saree: stain on the pallu',
    maxLength: CARE_NOTE_MAX,
    description: 'What the workshop should know about the clothes (stains, delicate fabric). Separate from instructions, which are for the pickup partner.',
  })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(CARE_NOTE_MAX)
  careNote?: string;

  @ApiPropertyOptional({
    type: [String],
    maxItems: CARE_PHOTOS_PER_ORDER,
    description: 'Photos of the clothes: URLs returned by POST /v1/me/uploads/care-photos for this customer, each used once and not yet on an order.',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(CARE_PHOTOS_PER_ORDER)
  @ArrayUnique()
  @IsString({ each: true })
  @MaxLength(500, { each: true })
  carePhotoUrls?: string[];
}

/** The shortest typed reason staff must give to go past the service area or a full pickup window. */
export const OVERRIDE_REASON_MIN = 5;

/** A phone order takes a care note but no photos (staff cannot upload on the customer's behalf). */
export class AdminPlaceOrderDto extends OmitType(PlaceOrderDto, ['carePhotoUrls'] as const) {
  @ApiProperty()
  @IsUUID()
  customerId!: string;

  @ApiPropertyOptional({
    example: 'Regular customer, our partner passes that way daily',
    description:
      'Needed when the pickup or delivery address is outside the service area (ADDRESS_NOT_SERVICEABLE). Stored on the order and in the audit log. Ignored when the address is inside.',
  })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(OVERRIDE_REASON_MIN)
  @MaxLength(300)
  outsideAreaReason?: string;

  @ApiPropertyOptional({
    example: 'Customer is away on other days',
    description:
      'Needed when the pickup window is already full (SLOT_FULL). Stored on the order and in the audit log. Ignored when the window has room.',
  })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(OVERRIDE_REASON_MIN)
  @MaxLength(300)
  capacityOverrideReason?: string;
}

export class CancelOrderDto {
  @ApiPropertyOptional({ example: 'Changed my plans' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

export class RescheduleOrderDto {
  @ApiProperty({ example: '2026-10-05', description: 'New pickup date (IST calendar date)' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  pickupDate!: string;

  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' })
  @IsEnum(TimeSlot)
  pickupSlot!: TimeSlot;

  @ApiProperty({
    example: '2026-10-06',
    description: 'Delivery date. Send the current one to keep it; it is accepted only if it still follows the new pickup by the minimum turnaround.',
  })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  deliveryDate!: string;

  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' })
  @IsEnum(TimeSlot)
  deliverySlot!: TimeSlot;
}

export class UpdateItemsDto {
  @ApiPropertyOptional({ description: 'Revision displayed when this edit was started. A stale edit returns ORDER_CHANGED.' })
  @IsOptional() @IsInt() @Min(0)
  expectedRevision?: number;
  @ApiProperty({ type: [OrderLineInput] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => OrderLineInput)
  items!: OrderLineInput[];

  @ApiPropertyOptional({ example: '2 extra shirts counted at pickup' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}

export class ChangeStatusDto {
  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus' })
  @IsEnum(OrderStatus)
  status!: OrderStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;

  @ApiPropertyOptional({
    description: 'With status DELIVERED: the partner or staff collected the balance in cash, so record it with the delivery.',
  })
  @IsOptional()
  @IsBoolean()
  collectedCash?: boolean;

  @ApiPropertyOptional({
    description:
      'With status CANCELLED: the partner had already travelled, so keep the travel charge. It is not refunded and the ' +
      'refund due is reduced by it. Without it, everything paid is refunded, the charge included.',
  })
  @IsOptional()
  @IsBoolean()
  keepTravelCharge?: boolean;
}

export const ORDER_SCOPES = ['active', 'past'] as const;
export type OrderScope = (typeof ORDER_SCOPES)[number];

export class CustomerOrdersQuery extends PageQueryDto {
  @ApiPropertyOptional({ enum: ORDER_SCOPES, description: 'active = not yet delivered or cancelled; past = delivered or cancelled; omit for all' })
  @IsOptional()
  @IsIn(ORDER_SCOPES)
  scope?: OrderScope;
}

export class AdminOrdersQuery extends PageQueryDto {
  @ApiPropertyOptional() @IsOptional() @Matches(/^\d{4}-\d{2}-\d{2}$/) createdFrom?: string;
  @ApiPropertyOptional() @IsOptional() @Matches(/^\d{4}-\d{2}-\d{2}$/) createdTo?: string;
  @ApiPropertyOptional() @IsOptional() @Matches(/^\d{4}-\d{2}-\d{2}$/) deliveryFrom?: string;
  @ApiPropertyOptional() @IsOptional() @Matches(/^\d{4}-\d{2}-\d{2}$/) deliveryTo?: string;
  @ApiPropertyOptional() @IsOptional() @Transform(({ value }) => value === true || value === 'true') @IsBoolean() excludeCancelled?: boolean;
  @ApiPropertyOptional() @IsOptional() @Transform(({ value }) => value === true || value === 'true') @IsBoolean() approvalPending?: boolean;
  @ApiPropertyOptional() @IsOptional() @Transform(({ value }) => value === true || value === 'true') @IsBoolean() unpaid?: boolean;
  @ApiPropertyOptional({ enum: ['pickup', 'delivery'] }) @IsOptional() @IsIn(['pickup', 'delivery']) overdue?: 'pickup' | 'delivery';
  @ApiPropertyOptional({ enum: OrderStatus, enumName: 'OrderStatus', isArray: true })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.split(',') : value))
  @IsArray()
  @IsEnum(OrderStatus, { each: true })
  status?: OrderStatus[];

  @ApiPropertyOptional({ description: 'Order number, customer phone or name' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  search?: string;

  @ApiPropertyOptional({ example: '2026-10-01', description: 'Pickup date from (IST)' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  pickupFrom?: string;

  @ApiPropertyOptional({ example: '2026-10-31', description: 'Pickup date to (IST, inclusive)' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  pickupTo?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  customerId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  driverId?: string;

  @ApiPropertyOptional({ description: 'Only orders where automatic dispatch found no driver' })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => value === 'true' || value === true)
  dispatchFailed?: boolean;

  @ApiPropertyOptional({ description: 'Only orders where the customer is owed money back (cancelled after paying, or overpaid)' })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => value === 'true' || value === true)
  refundDue?: boolean;
}

// ───────────── Responses ─────────────

export class QuoteLineDto {
  @ApiProperty() catalogItemId!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ enum: ItemUnit, enumName: 'ItemUnit' }) unit!: ItemUnit;
  @ApiProperty() unitPricePaise!: number;
  @ApiProperty() quantity!: number;
  @ApiProperty() lineTotalPaise!: number;
}

export class QuoteDto {
  @ApiProperty({ type: [QuoteLineDto] }) lines!: QuoteLineDto[];
  @ApiProperty() subtotalPaise!: number;
  @ApiProperty() discountPaise!: number;
  /** The flat travel charge: 0 once the items total (before any coupon) reaches the free-from amount. */
  @ApiProperty() deliveryFeePaise!: number;
  @ApiProperty() totalPaise!: number;
  /** How much more of clothes (items total before any coupon) makes travel free. Null when travel is already free or there is no threshold. */
  @ApiProperty({ nullable: true, type: Number }) freeTravelShortfallPaise!: number | null;
  @ApiProperty({ nullable: true, type: String }) promoCode!: string | null;
  /** Why the promo code was not applied, if it was not. */
  @ApiProperty({
    nullable: true,
    type: String,
    enum: ['PROMO_NOT_FOUND', 'PROMO_EXPIRED', 'PROMO_LIMIT_REACHED', 'PROMO_MIN_ORDER'],
  })
  promoError!: string | null;
  @ApiProperty({ nullable: true, type: Number }) promoShortfallPaise!: number | null;
  @ApiProperty({ nullable: true, type: Number }) minOrderShortfallPaise!: number | null;
  @ApiProperty() canPlaceOrder!: boolean;
}

export class OrderAddressDto {
  @ApiProperty() label!: string;
  @ApiProperty() formatted!: string;
  @ApiProperty() houseNo!: string;
  @ApiProperty({ nullable: true, type: String }) building!: string | null;
  @ApiProperty() street!: string;
  @ApiProperty({ nullable: true, type: String }) area!: string | null;
  @ApiProperty({ nullable: true, type: String }) landmark!: string | null;
  @ApiProperty() city!: string;
  @ApiProperty() state!: string;
  @ApiProperty() pincode!: string;
  @ApiProperty({ nullable: true, type: Number }) latitude!: number | null;
  @ApiProperty({ nullable: true, type: Number }) longitude!: number | null;
  @ApiProperty({ nullable: true, type: String }) contactName!: string | null;
  @ApiProperty() contactPhone!: string;
}

export class OrderItemDto {
  @ApiProperty() id!: string;
  @ApiProperty({ nullable: true, type: String }) catalogItemId!: string | null;
  @ApiProperty() name!: string;
  @ApiProperty({ enum: ItemUnit, enumName: 'ItemUnit' }) unit!: ItemUnit;
  @ApiProperty() unitPricePaise!: number;
  @ApiProperty() quantity!: number;
  @ApiProperty() lineTotalPaise!: number;
}

export class PersonRefDto {
  @ApiProperty() id!: string;
  @ApiProperty({ nullable: true, type: String }) name!: string | null;
  @ApiProperty({ nullable: true, type: String }) phone!: string | null;
}

export class OrderEventDto {
  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus', nullable: true }) fromStatus!: OrderStatus | null;
  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus' }) toStatus!: OrderStatus;
  @ApiProperty({ enum: Role, enumName: 'Role', nullable: true }) actorRole!: Role | null;
  @ApiProperty({ nullable: true, type: String }) note!: string | null;
  @ApiProperty() createdAt!: Date;
}

export class StaffRefDto {
  @ApiProperty() id!: string;
  @ApiProperty({ nullable: true, type: String }) name!: string | null;
}

/** Money returned to the customer. */
export class RefundDto {
  @ApiProperty() id!: string;
  @ApiProperty() amountPaise!: number;
  @ApiProperty({ enum: RefundMethod, enumName: 'RefundMethod' }) method!: RefundMethod;
  /** PENDING: Razorpay is still sending it. Only PENDING and PROCESSED count toward refundedPaise. */
  @ApiProperty({ enum: RefundStatus, enumName: 'RefundStatus' }) status!: RefundStatus;
  /** Staff note to the customer. */
  @ApiProperty() note!: string;
  @ApiProperty() createdAt!: Date;
  @ApiProperty({ nullable: true, type: Date }) processedAt!: Date | null;
  @ApiProperty({ nullable: true, type: String }) failureReason!: string | null;
  /** Staff member who issued it. Admin view only. */
  @ApiPropertyOptional({ type: StaffRefDto, nullable: true }) createdBy?: StaffRefDto | null;
}

export class OrderDto {
  @ApiPropertyOptional() revision?: number;
  @ApiPropertyOptional({ type: () => [OrderAdjustmentDto] }) adjustments?: OrderAdjustmentDto[];
  @ApiProperty() id!: string;
  @ApiProperty({ example: 'LD001042' }) orderNumber!: string;
  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus' }) status!: OrderStatus;
  @ApiProperty({ enum: OrderSource, enumName: 'OrderSource' }) source!: OrderSource;
  @ApiProperty() pickupDate!: string;
  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' }) pickupSlot!: TimeSlot;
  @ApiProperty() pickupSlotLabel!: string;
  @ApiProperty() deliveryDate!: string;
  @ApiProperty({ enum: TimeSlot, enumName: 'TimeSlot' }) deliverySlot!: TimeSlot;
  @ApiProperty() deliverySlotLabel!: string;
  @ApiProperty({ type: OrderAddressDto }) pickupAddress!: OrderAddressDto;
  @ApiProperty({ type: OrderAddressDto }) deliveryAddress!: OrderAddressDto;
  @ApiProperty({ nullable: true, type: String }) instructions!: string | null;
  /** What the customer told the workshop about their clothes. Separate from instructions, which are for the pickup partner. */
  @ApiProperty({ nullable: true, type: String }) careNote!: string | null;
  /** Photos that came with the care note, oldest first. Full-size URLs. */
  @ApiProperty({ type: [String] }) carePhotoUrls!: string[];
  @ApiProperty({ type: [OrderItemDto] }) items!: OrderItemDto[];
  @ApiProperty() subtotalPaise!: number;
  @ApiProperty() discountPaise!: number;
  @ApiProperty() deliveryFeePaise!: number;
  @ApiProperty() totalPaise!: number;
  @ApiProperty() paidPaise!: number;
  /** Sum of PENDING and PROCESSED refunds. */
  @ApiProperty() refundedPaise!: number;
  /** What can still be refunded (paidPaise - refundedPaise, less the travel charge when it was kept). Admin view only. */
  @ApiPropertyOptional() refundablePaise?: number;
  /** Staff cancelled after the partner had already travelled, so the travel charge (deliveryFeePaise) was kept, not refunded. */
  @ApiProperty() travelChargeKept!: boolean;
  @ApiProperty() amountDuePaise!: number;
  @ApiProperty({ nullable: true, type: String }) promoCode!: string | null;
  @ApiProperty({ enum: PaymentMethod, enumName: 'PaymentMethod' }) paymentMethod!: PaymentMethod;
  @ApiProperty({ enum: PaymentStatus, enumName: 'PaymentStatus' }) paymentStatus!: PaymentStatus;
  @ApiProperty({ type: PersonRefDto, nullable: true }) customer!: PersonRefDto | null;
  @ApiProperty({ type: PersonRefDto, nullable: true }) pickupDriver!: PersonRefDto | null;
  @ApiProperty({ type: PersonRefDto, nullable: true }) deliveryDriver!: PersonRefDto | null;
  /** Statuses the caller is allowed to move this order to. */
  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus', isArray: true }) allowedNextStatuses!: OrderStatus[];
  @ApiProperty({ nullable: true, type: Date }) dispatchFailedAt!: Date | null;
  @ApiProperty({ nullable: true, type: String }) cancelReason!: string | null;
  @ApiProperty({ nullable: true, type: Date }) pickedUpAt!: Date | null;
  @ApiProperty({ nullable: true, type: Date }) deliveredAt!: Date | null;
  @ApiProperty({ nullable: true, type: Date }) cancelledAt!: Date | null;
  /** How many times the customer has moved the pickup or delivery time. */
  @ApiProperty() rescheduleCount!: number;
  /** Moves the customer has left on this order. */
  @ApiProperty() reschedulesRemaining!: number;
  /** Customer view: the pickup time can be changed now (not yet picked up, and moves remain). Always false for staff and partners. */
  @ApiProperty() canReschedule!: boolean;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
  @ApiPropertyOptional({ type: [OrderEventDto] }) events?: OrderEventDto[];
  /** Oldest first. Customer and admin views only. */
  @ApiPropertyOptional({ type: [RefundDto] }) refunds?: RefundDto[];
  /** Captured transactions only; excludes raw provider payloads and staff identities. */
  @ApiPropertyOptional({ type: () => [OrderPaymentDto] }) payments?: OrderPaymentDto[];
  /** Staff view only: why a phone order was placed for an address outside the service area. Null when it was inside. */
  @ApiPropertyOptional({ nullable: true, type: String }) areaOverrideReason?: string | null;
  /** Staff view only: why a phone order was booked into a pickup window that was already full. Null when there was room. */
  @ApiPropertyOptional({ nullable: true, type: String }) capacityOverrideReason?: string | null;
}

export class OrderPaymentDto {
  @ApiProperty() id!: string;
  @ApiProperty({ enum: PaymentProvider, enumName: 'PaymentProvider' }) provider!: PaymentProvider;
  @ApiProperty() amountPaise!: number;
  @ApiProperty({ nullable: true, type: String }) reference!: string | null;
  @ApiProperty() capturedAt!: Date;
}

export class OrderAdjustmentDto {
  @ApiProperty() id!: string;
  @ApiProperty({ enum: AdjustmentStatus, enumName: 'AdjustmentStatus' }) status!: AdjustmentStatus;
  @ApiProperty() reason!: string;
  @ApiProperty() oldTotalPaise!: number;
  @ApiProperty() newTotalPaise!: number;
  @ApiProperty() subtotalPaise!: number;
  @ApiProperty() discountPaise!: number;
  @ApiProperty() deliveryFeePaise!: number;
  @ApiProperty({ type: () => [AdjustmentLineDto] }) itemsBefore!: AdjustmentLineDto[];
  @ApiProperty({ type: () => [AdjustmentLineDto] }) itemsAfter!: AdjustmentLineDto[];
  @ApiProperty() expiresAt!: Date;
  @ApiProperty({ nullable: true, type: Date }) decidedAt!: Date | null;
  @ApiProperty() createdAt!: Date;
}

export class AdjustmentLineDto {
  @ApiProperty({ nullable: true, type: String }) catalogItemId!: string | null;
  @ApiProperty() name!: string;
  @ApiProperty({ enum: ItemUnit, enumName: 'ItemUnit' }) unit!: ItemUnit;
  @ApiProperty() unitPricePaise!: number;
  @ApiProperty() quantity!: number;
  @ApiProperty() lineTotalPaise!: number;
}

export class ItemEditPreviewDto {
  @ApiProperty() revision!: number;
  @ApiProperty() oldTotalPaise!: number;
  @ApiProperty() newTotalPaise!: number;
  @ApiProperty() subtotalPaise!: number;
  @ApiProperty() discountPaise!: number;
  @ApiProperty() deliveryFeePaise!: number;
  /** The travel charge the order has now, so a screen can show it changing. */
  @ApiProperty() oldDeliveryFeePaise!: number;
  @ApiProperty() requiresApproval!: boolean;
  @ApiProperty({ type: [QuoteLineDto] }) lines!: QuoteLineDto[];
}

export class OrderPageDto {
  @ApiProperty({ type: [OrderDto] }) items!: OrderDto[];
  @ApiProperty() page!: number;
  @ApiProperty() pageSize!: number;
  @ApiProperty() total!: number;
}

export type OrderWithRelations = Order & {
  items: OrderItem[];
  customer?: User | null;
  pickupDriver?: User | null;
  deliveryDriver?: User | null;
  events?: OrderEvent[];
  payments?: Payment[];
  adjustments?: OrderAdjustment[];
  carePhotos?: OrderCarePhoto[];
  refunds?: (Refund & { createdBy?: { id: string; name: string | null } | null })[];
};

const person = (u: User | null | undefined): PersonRefDto | null =>
  u ? { id: u.id, name: u.name, phone: customerPhone(u) } : null;

function toRefundDto(r: NonNullable<OrderWithRelations['refunds']>[number], viewer: ActorKind): RefundDto {
  return {
    id: r.id,
    amountPaise: r.amountPaise,
    method: r.method,
    status: r.status,
    note: r.note,
    createdAt: r.createdAt,
    processedAt: r.processedAt,
    failureReason: r.failureReason,
    ...(viewer === 'ADMIN' ? { createdBy: r.createdBy ? { id: r.createdBy.id, name: r.createdBy.name } : null } : {}),
  };
}

export function toOrderDto(o: OrderWithRelations, viewer: ActorKind): OrderDto {
  const showRefunds = viewer === 'CUSTOMER' || viewer === 'ADMIN';
  return {
    id: o.id,
    revision: o.revision,
    ...(o.adjustments ? { adjustments: o.adjustments.map((a) => ({
      id: a.id, status: a.status, reason: a.reason, oldTotalPaise: a.oldTotalPaise, newTotalPaise: a.newTotalPaise,
      subtotalPaise: a.subtotalPaise, discountPaise: a.discountPaise, deliveryFeePaise: a.deliveryFeePaise,
      itemsBefore: a.itemsBefore as unknown as AdjustmentLineDto[], itemsAfter: a.itemsAfter as unknown as AdjustmentLineDto[],
      expiresAt: a.expiresAt, decidedAt: a.decidedAt, createdAt: a.createdAt,
    })) } : {}),
    orderNumber: o.orderNumber,
    status: o.status,
    source: o.source,
    pickupDate: fromDbDate(o.pickupDate),
    pickupSlot: o.pickupSlot,
    pickupSlotLabel: slotLabel(o.pickupSlot),
    deliveryDate: fromDbDate(o.deliveryDate),
    deliverySlot: o.deliverySlot,
    deliverySlotLabel: slotLabel(o.deliverySlot),
    pickupAddress: o.pickupAddress as unknown as OrderAddressDto,
    deliveryAddress: o.deliveryAddress as unknown as OrderAddressDto,
    instructions: o.instructions,
    careNote: o.careNote,
    carePhotoUrls: (o.carePhotos ?? []).map((p) => carePhotoUrl(p.key)),
    items: o.items.map((i) => ({
      id: i.id,
      catalogItemId: i.catalogItemId,
      name: i.name,
      unit: i.unit,
      unitPricePaise: i.unitPricePaise,
      quantity: i.quantity,
      lineTotalPaise: i.lineTotalPaise,
    })),
    subtotalPaise: o.subtotalPaise,
    discountPaise: o.discountPaise,
    deliveryFeePaise: o.deliveryFeePaise,
    totalPaise: o.totalPaise,
    paidPaise: o.paidPaise,
    refundedPaise: o.refundedPaise,
    ...(viewer === 'ADMIN' ? { refundablePaise: refundablePaise(o) } : {}),
    travelChargeKept: o.travelChargeKept,
    amountDuePaise: Math.max(0, o.totalPaise - o.paidPaise),
    promoCode: o.promoCode,
    paymentMethod: o.paymentMethod,
    paymentStatus: o.paymentStatus,
    customer: person(o.customer),
    pickupDriver: person(o.pickupDriver),
    deliveryDriver: person(o.deliveryDriver),
    allowedNextStatuses: nextStatuses(o.status, viewer),
    dispatchFailedAt: o.dispatchFailedAt,
    cancelReason: o.cancelReason,
    pickedUpAt: o.pickedUpAt,
    deliveredAt: o.deliveredAt,
    cancelledAt: o.cancelledAt,
    rescheduleCount: o.rescheduleCount,
    reschedulesRemaining: reschedulesRemaining(o.rescheduleCount),
    canReschedule: viewer === 'CUSTOMER' && canReschedule(o.status, o.rescheduleCount),
    createdAt: o.createdAt,
    updatedAt: o.updatedAt,
    ...(o.events
      ? {
          events: o.events.map((e) => ({
            fromStatus: e.fromStatus,
            toStatus: e.toStatus,
            actorRole: e.actorRole,
            note: e.note,
            createdAt: e.createdAt,
          })),
        }
      : {}),
    ...(viewer === 'ADMIN' ? { areaOverrideReason: o.areaOverrideReason, capacityOverrideReason: o.capacityOverrideReason } : {}),
    ...(showRefunds && o.refunds ? { refunds: o.refunds.map((r) => toRefundDto(r, viewer)) } : {}),
    ...(showRefunds && o.payments ? { payments: o.payments.filter((p) => p.status === 'CAPTURED').map((p) => ({
      id: p.id, provider: p.provider, amountPaise: p.amountPaise,
      reference: p.razorpayPaymentId, capturedAt: p.capturedAt ?? p.updatedAt,
    })) } : {}),
  };
}
