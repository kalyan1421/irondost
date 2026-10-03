// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/slot_option_dto.dart';
import '../models/time_slot.dart';

part 'schedule_client.g.dart';

@RestApi()
abstract class ScheduleClient {
  factory ScheduleClient(Dio dio, {String? baseUrl}) = _ScheduleClient;

  @GET('/v1/schedule/pickup-slots')
  Future<List<SlotOptionDto>> schedulingControllerPickupSlots({
    @Query('days') num? days = 7,
  });

  @GET('/v1/schedule/delivery-slots')
  Future<List<SlotOptionDto>> schedulingControllerDeliverySlots({
    @Query('pickupDate') required String pickupDate,
    @Query('pickupSlot') required TimeSlot pickupSlot,
    @Query('days') num? days = 7,
  });
}
