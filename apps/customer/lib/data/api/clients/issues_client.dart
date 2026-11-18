// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_issue_dto.dart';
import '../models/issue_dto.dart';
import '../models/issue_message_body_dto.dart';
import '../models/issue_page_dto.dart';
import '../models/issue_status.dart';

part 'issues_client.g.dart';

@RestApi()
abstract class IssuesClient {
  factory IssuesClient(Dio dio, {String? baseUrl}) = _IssuesClient;

  /// [idempotencyKey] - Reuse one key to retry the same report after a lost response.
  @POST('/v1/orders/{id}/issues')
  Future<IssueDto> customerIssuesControllerCreate({
    @Path('id') required String id,
    @Body() required CreateIssueDto body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  @GET('/v1/me/issues')
  Future<IssuePageDto> customerIssuesControllerList({
    @Query('status') IssueStatus? status,
    @Query('orderId') String? orderId,
    @Query('handledById') String? handledById,
    @Query('search') String? search,
    @Query('overdue') bool? overdue,
    @Query('page') num? page = 1,
    @Query('pageSize') num? pageSize = 20,
  });

  @GET('/v1/me/issues/{id}')
  Future<IssueDto> customerIssuesControllerGet({
    @Path('id') required String id,
  });

  @POST('/v1/me/issues/{id}/messages')
  Future<IssueDto> customerIssuesControllerMessage({
    @Path('id') required String id,
    @Body() required IssueMessageBodyDto body,
  });
}
