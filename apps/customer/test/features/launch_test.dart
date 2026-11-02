import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_failure.dart';
import 'package:irondost_customer/data/wake_retry.dart';
import 'package:irondost_customer/features/system/system_screens.dart';

import '../helpers.dart';

void main() {
  late Duration savedDelay;

  setUp(() {
    savedDelay = WakeRetry.delay;
    WakeRetry.delay = Duration.zero;
  });
  tearDown(() => WakeRetry.delay = savedDelay);

  /// A call that fails with each of [failures] in turn, then answers.
  Future<String> Function() flaky(List<ApiFailure> failures, List<int> calls) {
    final queue = [...failures];
    return () async {
      calls.add(calls.length + 1);
      if (queue.isNotEmpty) throw queue.removeAt(0);
      return 'ok';
    };
  }

  group('waiting for a sleeping API', () {
    test('a call that times out is made again until the API answers', () async {
      final calls = <int>[];
      final result = await WakeRetry.run(
        flaky(const [ApiFailure(ApiFailureKind.timeout), ApiFailure(ApiFailureKind.timeout)], calls),
      );
      expect(result, 'ok');
      expect(calls, hasLength(3));
    });

    test('a gateway answer (502, 503, 504) is treated as the API still waking', () async {
      for (final status in [502, 503, 504]) {
        final calls = <int>[];
        final result = await WakeRetry.run(flaky([ApiFailure(ApiFailureKind.server, statusCode: status)], calls));
        expect(result, 'ok', reason: '$status');
        expect(calls, hasLength(2), reason: '$status');
      }
    });

    test('gives up after four calls and reports the failure', () async {
      final calls = <int>[];
      final failures = List.generate(10, (_) => const ApiFailure(ApiFailureKind.timeout));
      await expectLater(
        WakeRetry.run(flaky(failures, calls)),
        throwsA(isA<ApiFailure>().having((f) => f.kind, 'kind', ApiFailureKind.timeout)),
      );
      expect(calls, hasLength(WakeRetry.attempts));
    });

    test('does not wait on offline, a refusal or a real server error', () async {
      for (final failure in const [
        ApiFailure(ApiFailureKind.offline),
        ApiFailure(ApiFailureKind.rejected, statusCode: 400),
        ApiFailure(ApiFailureKind.unauthorized, statusCode: 401),
        ApiFailure(ApiFailureKind.server, statusCode: 500),
      ]) {
        final calls = <int>[];
        await expectLater(WakeRetry.run(flaky([failure], calls)), throwsA(isA<ApiFailure>()), reason: '${failure.kind}');
        expect(calls, hasLength(1), reason: '${failure.kind}');
      }
    });
  });

  group('launch screen', () {
    testWidgets('shows only the logo at first, then says the first open can take a minute', (tester) async {
      await tester.pumpWidget(themed(const LaunchScreen()));
      expect(find.textContaining('Getting things ready'), findsNothing);

      await tester.pump(const Duration(seconds: 7));
      expect(find.textContaining('Getting things ready'), findsOneWidget);
    });
  });
}
