// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_address_dto.dart';
import 'order_adjustment_dto.dart';
import 'order_event_dto.dart';
import 'order_item_dto.dart';
import 'order_payment_dto.dart';
import 'order_source.dart';
import 'order_status.dart';
import 'payment_method.dart';
import 'payment_status.dart';
import 'person_ref_dto.dart';
import 'refund_dto.dart';
import 'time_slot.dart';

part 'order_dto.g.dart';

@JsonSerializable()
class OrderDto {
  const OrderDto({
    required this.instructions,
    required this.updatedAt,
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.source,
    required this.pickupDate,
    required this.pickupSlot,
    required this.pickupSlotLabel,
    required this.deliveryDate,
    required this.deliverySlot,
    required this.deliverySlotLabel,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.createdAt,
    required this.items,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.deliveryFeePaise,
    required this.totalPaise,
    required this.paidPaise,
    required this.refundedPaise,
    required this.canReschedule,
    required this.amountDuePaise,
    required this.promoCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.customer,
    required this.reschedulesRemaining,
    required this.deliveryDriver,
    required this.allowedNextStatuses,
    required this.dispatchFailedAt,
    required this.cancelReason,
    required this.pickedUpAt,
    required this.deliveredAt,
    required this.cancelledAt,
    required this.rescheduleCount,
    required this.pickupDriver,
    this.refundablePaise,
    this.revision,
    this.adjustments,
    this.events,
    this.refunds,
    this.payments,
  });
  
  factory OrderDto.fromJson(Map<String, Object?> json) => _$OrderDtoFromJson(json);
  
  final num? revision;
  final List<OrderAdjustmentDto>? adjustments;
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final OrderSource source;
  final String pickupDate;
  final TimeSlot pickupSlot;
  final String pickupSlotLabel;
  final String deliveryDate;
  final TimeSlot deliverySlot;
  final String deliverySlotLabel;
  final OrderAddressDto pickupAddress;
  final OrderAddressDto deliveryAddress;
  final String? instructions;
  final List<OrderItemDto> items;
  final num subtotalPaise;
  final num discountPaise;
  final num deliveryFeePaise;
  final num totalPaise;
  final num paidPaise;

  /// Sum of PENDING and PROCESSED refunds.
  final num refundedPaise;

  /// What can still be refunded (paidPaise - refundedPaise). Admin view only.
  final num? refundablePaise;
  final num amountDuePaise;
  final String? promoCode;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final PersonRefDto? customer;
  final PersonRefDto? pickupDriver;
  final PersonRefDto? deliveryDriver;

  /// Statuses the caller is allowed to move this order to.
  final List<OrderStatus> allowedNextStatuses;
  final DateTime? dispatchFailedAt;
  final String? cancelReason;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  /// How many times the customer has moved the pickup or delivery time.
  final num rescheduleCount;

  /// Moves the customer has left on this order.
  final num reschedulesRemaining;

  /// Customer view: the pickup time can be changed now (not yet picked up, and moves remain). Always false for staff and partners.
  final bool canReschedule;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderEventDto>? events;

  /// Oldest first. Customer and admin views only.
  final List<RefundDto>? refunds;

  /// Captured transactions only; excludes raw provider payloads and staff identities.
  final List<OrderPaymentDto>? payments;

  Map<String, Object?> toJson() => _$OrderDtoToJson(this);
}
