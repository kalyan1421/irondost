import '../data/api/export.dart';

/// Chip tones from the design system's "Order status" page.
enum StatusTone { info, accent, success, neutral }

/// Customer-facing words for each API status. Internal dispatch steps are never mentioned.
extension OrderStatusCopy on OrderStatus {
  String get customerLabel => switch (this) {
        OrderStatus.pending => 'Booked',
        OrderStatus.pickupAssigned => 'Partner assigned',
        OrderStatus.pickedUp => 'Picked up',
        OrderStatus.processing => 'Being ironed',
        OrderStatus.readyForDelivery => 'Ready',
        OrderStatus.deliveryAssigned => 'Out for delivery soon',
        OrderStatus.outForDelivery => 'Out for delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.$unknown => 'Updating',
      };

  StatusTone get tone => switch (this) {
        OrderStatus.deliveryAssigned || OrderStatus.outForDelivery => StatusTone.accent,
        OrderStatus.delivered => StatusTone.success,
        OrderStatus.cancelled || OrderStatus.$unknown => StatusTone.neutral,
        _ => StatusTone.info,
      };

  /// Step 1–5 on the customer timeline: Booked, Picked up, Ironing, Out for delivery, Delivered.
  int get timelineStep => switch (this) {
        OrderStatus.pending || OrderStatus.pickupAssigned => 1,
        OrderStatus.pickedUp => 2,
        OrderStatus.processing || OrderStatus.readyForDelivery => 3,
        OrderStatus.deliveryAssigned || OrderStatus.outForDelivery => 4,
        OrderStatus.delivered => 5,
        OrderStatus.cancelled || OrderStatus.$unknown => 0,
      };
}
