// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/auth_client.dart';
import 'clients/schedule_client.dart';
import 'clients/config_client.dart';
import 'clients/me_client.dart';
import 'clients/addresses_client.dart';
import 'clients/catalog_client.dart';
import 'clients/promotions_client.dart';
import 'clients/banners_client.dart';
import 'clients/app_versions_client.dart';
import 'clients/orders_client.dart';
import 'clients/payments_client.dart';

/// Laundry API `v1.0`.
///
/// Firebase phone-OTP ID token as Bearer. Money in paise. Dates are IST (YYYY-MM-DD).
class IronDostApi {
  IronDostApi(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0';

  AuthClient? _auth;
  ScheduleClient? _schedule;
  ConfigClient? _config;
  MeClient? _me;
  AddressesClient? _addresses;
  CatalogClient? _catalog;
  PromotionsClient? _promotions;
  BannersClient? _banners;
  AppVersionsClient? _appVersions;
  OrdersClient? _orders;
  PaymentsClient? _payments;

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  ScheduleClient get schedule => _schedule ??= ScheduleClient(_dio, baseUrl: _baseUrl);

  ConfigClient get config => _config ??= ConfigClient(_dio, baseUrl: _baseUrl);

  MeClient get me => _me ??= MeClient(_dio, baseUrl: _baseUrl);

  AddressesClient get addresses => _addresses ??= AddressesClient(_dio, baseUrl: _baseUrl);

  CatalogClient get catalog => _catalog ??= CatalogClient(_dio, baseUrl: _baseUrl);

  PromotionsClient get promotions => _promotions ??= PromotionsClient(_dio, baseUrl: _baseUrl);

  BannersClient get banners => _banners ??= BannersClient(_dio, baseUrl: _baseUrl);

  AppVersionsClient get appVersions => _appVersions ??= AppVersionsClient(_dio, baseUrl: _baseUrl);

  OrdersClient get orders => _orders ??= OrdersClient(_dio, baseUrl: _baseUrl);

  PaymentsClient get payments => _payments ??= PaymentsClient(_dio, baseUrl: _baseUrl);
}
