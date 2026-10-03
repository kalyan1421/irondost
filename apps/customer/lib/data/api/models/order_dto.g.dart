// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => OrderDto(
  instructions: json['instructions'] as String?,
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
  id: json['id'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotalPaise: json['subtotalPaise'] as num,
  discountPaise: json['discountPaise'] as num,
  deliveryFeePaise: json['deliveryFeePaise'] as num,
  totalPaise: json['totalPaise'] as num,
  paidPaise: json['paidPaise'] as num,
  refundedPaise: json['refundedPaise'] as num,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  amountDuePaise: json['amountDuePaise'] as num,
  promoCode: json['promoCode'] as String?,
  paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  customer: json['customer'] == null
      ? null
      : PersonRefDto.fromJson(json['customer'] as Map<String, dynamic>),
  pickupDriver: json['pickupDriver'] == null
      ? null
      : PersonRefDto.fromJson(json['pickupDriver'] as Map<String, dynamic>),
  deliveryDriver: json['deliveryDriver'] == null
      ? null
      : PersonRefDto.fromJson(json['deliveryDriver'] as Map<String, dynamic>),
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
  paymentStatus: PaymentStatus.fromJson(json['paymentStatus'] as String),
  refundablePaise: json['refundablePaise'] as num?,
  events: (json['events'] as List<dynamic>?)
      ?.map((e) => OrderEventDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  refunds: (json['refunds'] as List<dynamic>?)
      ?.map((e) => RefundDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OrderDtoToJson(OrderDto instance) => <String, dynamic>{
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
  'items': instance.items,
  'subtotalPaise': instance.subtotalPaise,
  'discountPaise': instance.discountPaise,
  'deliveryFeePaise': instance.deliveryFeePaise,
  'totalPaise': instance.totalPaise,
  'paidPaise': instance.paidPaise,
  'refundedPaise': instance.refundedPaise,
  'refundablePaise': instance.refundablePaise,
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
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'events': instance.events,
  'refunds': instance.refunds,
};
