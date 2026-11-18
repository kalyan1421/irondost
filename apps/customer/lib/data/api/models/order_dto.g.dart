// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => OrderDto(
  carePhotoUrls: (json['carePhotoUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String,
  orderNumber: json['orderNumber'] as String,
  status: OrderStatus.fromJson(json['status'] as String),
  source: OrderSource.fromJson(json['source'] as String),
  pickupDate: json['pickupDate'] as String,
  pickupSlot: TimeSlot.fromJson(json['pickupSlot'] as String),
  pickupSlotLabel: json['pickupSlotLabel'] as String,
  deliveryDate: json['deliveryDate'] as String,
  deliverySlot: TimeSlot.fromJson(json['deliverySlot'] as String),
  deliverySlotLabel: json['deliverySlotLabel'] as String,
  pickupAddress: OrderAddressDto.fromJson(
    json['pickupAddress'] as Map<String, dynamic>,
  ),
  deliveryAddress: OrderAddressDto.fromJson(
    json['deliveryAddress'] as Map<String, dynamic>,
  ),
  instructions: json['instructions'] as String?,
  careNote: json['careNote'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotalPaise: json['subtotalPaise'] as num,
  discountPaise: json['discountPaise'] as num,
  deliveryFeePaise: json['deliveryFeePaise'] as num,
  totalPaise: json['totalPaise'] as num,
  paidPaise: json['paidPaise'] as num,
  refundedPaise: json['refundedPaise'] as num,
  deliveryDriver: json['deliveryDriver'] == null
      ? null
      : PersonRefDto.fromJson(json['deliveryDriver'] as Map<String, dynamic>),
  travelChargeKept: json['travelChargeKept'] as bool,
  amountDuePaise: json['amountDuePaise'] as num,
  promoCode: json['promoCode'] as String?,
  paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
  paymentStatus: PaymentStatus.fromJson(json['paymentStatus'] as String),
  customer: json['customer'] == null
      ? null
      : PersonRefDto.fromJson(json['customer'] as Map<String, dynamic>),
  pickupDriver: json['pickupDriver'] == null
      ? null
      : PersonRefDto.fromJson(json['pickupDriver'] as Map<String, dynamic>),
  canReschedule: json['canReschedule'] as bool,
  allowedNextStatuses: (json['allowedNextStatuses'] as List<dynamic>)
      .map((e) => OrderStatus.fromJson(e as String))
      .toList(),
  dispatchFailedAt: json['dispatchFailedAt'] == null
      ? null
      : DateTime.parse(json['dispatchFailedAt'] as String),
  cancelReason: json['cancelReason'] as String?,
  pickedUpAt: json['pickedUpAt'] == null
      ? null
      : DateTime.parse(json['pickedUpAt'] as String),
  deliveredAt: json['deliveredAt'] == null
      ? null
      : DateTime.parse(json['deliveredAt'] as String),
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
  reschedulesRemaining: json['reschedulesRemaining'] as num,
  rescheduleCount: json['rescheduleCount'] as num,
  capacityOverrideReason: json['capacityOverrideReason'] as String?,
  revision: json['revision'] as num?,
  adjustments: (json['adjustments'] as List<dynamic>?)
      ?.map((e) => OrderAdjustmentDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  events: (json['events'] as List<dynamic>?)
      ?.map((e) => OrderEventDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  refunds: (json['refunds'] as List<dynamic>?)
      ?.map((e) => RefundDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  payments: (json['payments'] as List<dynamic>?)
      ?.map((e) => OrderPaymentDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  areaOverrideReason: json['areaOverrideReason'] as String?,
  refundablePaise: json['refundablePaise'] as num?,
);

Map<String, dynamic> _$OrderDtoToJson(OrderDto instance) => <String, dynamic>{
  'revision': instance.revision,
  'adjustments': instance.adjustments,
  'id': instance.id,
  'orderNumber': instance.orderNumber,
  'status': instance.status,
  'source': instance.source,
  'pickupDate': instance.pickupDate,
  'pickupSlot': instance.pickupSlot,
  'pickupSlotLabel': instance.pickupSlotLabel,
  'deliveryDate': instance.deliveryDate,
  'deliverySlot': instance.deliverySlot,
  'deliverySlotLabel': instance.deliverySlotLabel,
  'pickupAddress': instance.pickupAddress,
  'deliveryAddress': instance.deliveryAddress,
  'instructions': instance.instructions,
  'careNote': instance.careNote,
  'carePhotoUrls': instance.carePhotoUrls,
  'items': instance.items,
  'subtotalPaise': instance.subtotalPaise,
  'discountPaise': instance.discountPaise,
  'deliveryFeePaise': instance.deliveryFeePaise,
  'totalPaise': instance.totalPaise,
  'paidPaise': instance.paidPaise,
  'refundedPaise': instance.refundedPaise,
  'refundablePaise': instance.refundablePaise,
  'travelChargeKept': instance.travelChargeKept,
  'amountDuePaise': instance.amountDuePaise,
  'promoCode': instance.promoCode,
  'paymentMethod': instance.paymentMethod,
  'paymentStatus': instance.paymentStatus,
  'customer': instance.customer,
  'pickupDriver': instance.pickupDriver,
  'deliveryDriver': instance.deliveryDriver,
  'allowedNextStatuses': instance.allowedNextStatuses,
  'dispatchFailedAt': instance.dispatchFailedAt?.toIso8601String(),
  'cancelReason': instance.cancelReason,
  'pickedUpAt': instance.pickedUpAt?.toIso8601String(),
  'deliveredAt': instance.deliveredAt?.toIso8601String(),
  'cancelledAt': instance.cancelledAt?.toIso8601String(),
  'rescheduleCount': instance.rescheduleCount,
  'reschedulesRemaining': instance.reschedulesRemaining,
  'canReschedule': instance.canReschedule,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'events': instance.events,
  'refunds': instance.refunds,
  'payments': instance.payments,
  'areaOverrideReason': instance.areaOverrideReason,
  'capacityOverrideReason': instance.capacityOverrideReason,
};
