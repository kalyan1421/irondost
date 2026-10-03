import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';

/// Things only the signed-in customer can do to their own account.
abstract class AccountRepository {
  /// Deletes the account: name, number, email and addresses go; past orders stay without them.
  /// Refused with `ACTIVE_ORDERS` (and `details.activeOrders`) while orders are in progress.
  Future<void> deleteAccount();
}

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._api);
  final IronDostApi _api;

  @override
  Future<void> deleteAccount() async {
    try {
      await _api.me.usersControllerDeleteAccount();
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) => ApiAccountRepository(ref.watch(apiProvider)));
