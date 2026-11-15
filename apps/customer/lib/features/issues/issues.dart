import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/api_client.dart';
import '../basket/basket.dart';

abstract class IssueRepository {
  Future<IssuePageDto> list({String? orderId, int page = 1});
  Future<IssueDto> get(String id);
  Future<IssueDto> create(String orderId, CreateIssueDto body, String requestKey);
  Future<IssueDto> reply(String id, String body);
  Future<String> upload(Uint8List bytes, String name, {CancelToken? cancelToken, void Function(int, int)? onProgress});
}
class ApiIssueRepository implements IssueRepository {
  ApiIssueRepository(this.api, this.dio);
  final IronDostApi api;
  final Dio dio;
  @override
  Future<IssuePageDto> list({String? orderId, int page = 1}) => api.issues.customerIssuesControllerList(orderId: orderId, page: page);
  @override
  Future<IssueDto> get(String id) => api.issues.customerIssuesControllerGet(id: id);
  @override
  Future<IssueDto> create(String orderId, CreateIssueDto body, String requestKey) async {
    final response = await dio.post<Map<String, dynamic>>('/v1/orders/$orderId/issues', data: body.toJson(),
      options: Options(headers: {'Idempotency-Key': requestKey}));
    return IssueDto.fromJson(response.data!.cast<String, Object?>());
  }
  @override
  Future<IssueDto> reply(String id, String body) => api.issues.customerIssuesControllerMessage(id: id, body: IssueMessageBodyDto(body: body));
  @override
  Future<String> upload(Uint8List bytes, String name, {CancelToken? cancelToken, void Function(int, int)? onProgress}) async {
    final response = await dio.post<Map<String, dynamic>>('/v1/me/uploads/images', data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: name)}),
      cancelToken: cancelToken, onSendProgress: onProgress);
    return response.data!['url'] as String;
  }
}
final issueRepositoryProvider = Provider<IssueRepository>((ref) => ApiIssueRepository(ref.watch(apiProvider), ref.watch(dioProvider)));
final issuesProvider = FutureProvider.autoDispose.family<IssuePageDto, ({String? orderId, int page})>((ref, q) => ref.watch(issueRepositoryProvider).list(orderId: q.orderId, page: q.page));
final issueProvider = FutureProvider.autoDispose.family<IssueDto, String>((ref, id) {
  final timer = Timer.periodic(const Duration(seconds: 20), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(issueRepositoryProvider).get(id);
});

abstract class IssuePhotoPicker {
  Future<List<XFile>> pick(int remaining);
  Future<List<XFile>> recover();
}
class GalleryIssuePhotoPicker implements IssuePhotoPicker {
  final picker = ImagePicker();
  @override
  Future<List<XFile>> pick(int remaining) async {
    if (remaining <= 0) return [];
    if (remaining == 1) {
      final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85, requestFullMetadata: false);
      return file == null ? [] : [file];
    }
    return picker.pickMultiImage(limit: remaining, maxWidth: 1600, imageQuality: 85, requestFullMetadata: false);
  }
  @override
  Future<List<XFile>> recover() async => (await picker.retrieveLostData()).files ?? [];
}
final issuePhotoPickerProvider = Provider<IssuePhotoPicker>((_) => GalleryIssuePhotoPicker());
// Recover Android picker results after activity recreation, without requesting any permission.
final issuePhotoRecoveryProvider = FutureProvider<void>((ref) async {
  try {
    final files = await ref.read(issuePhotoPickerProvider).recover();
    if (files.isNotEmpty) await ref.read(sharedPreferencesProvider).setStringList('issue.recoveredPhotos', files.map((f) => f.path).toList());
  } catch (_) { /* Photo selection is optional; not supported on every test/device platform. */ }
});
const issueCategories = <IssueCategory, String>{
  IssueCategory.valueLate: 'Late delivery', IssueCategory.missedPickup: 'Missed pickup', IssueCategory.damaged: 'Damaged garment',
  IssueCategory.missingItem: 'Missing garment', IssueCategory.quality: 'Cleaning or ironing quality', IssueCategory.billing: 'Bill or payment',
  IssueCategory.rider: 'Pickup or delivery partner', IssueCategory.other: 'Something else',
};
String issueStatusLabel(IssueStatus status) => switch (status) {
  IssueStatus.open => 'Open', IssueStatus.acknowledged => 'Seen by our team', IssueStatus.resolved => 'Resolved', IssueStatus.rejected => 'Closed with an explanation', _ => 'Check with support',
};
