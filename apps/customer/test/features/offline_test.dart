import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/data/reachability.dart';
import 'package:irondost_customer/features/offers/promotions.dart';
import 'package:irondost_customer/features/shell/offline_banner.dart';

import '../helpers.dart';

/// Answers each request as [next] says: a status, or an error of a given kind.
class _Adapter implements HttpClientAdapter {
  Object next = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final answer = next;
    if (answer is DioExceptionType) throw DioException(requestOptions: options, type: answer);
    return ResponseBody.fromString('{}', answer as int, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('learning whether the API is reachable', () {
    late _Adapter adapter;
    late Dio dio;
    late List<bool> reports;

    setUp(() {
      adapter = _Adapter();
      reports = [];
      dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(ReachabilityInterceptor(reports.add));
    });

    Future<void> call() async {
      try {
        await dio.get<Object?>('/x');
      } on DioException {
        // The outcome is what is being tested.
      }
    }

    test('an answer from the server means reachable, even an error answer', () async {
      adapter.next = 200;
      await call();
      adapter.next = 404;
      await call();
      adapter.next = 500;
      await call();
      expect(reports, [true, true, true]);
    });

    test('no connection or a timeout means unreachable', () async {
      for (final kind in [DioExceptionType.connectionError, DioExceptionType.connectionTimeout, DioExceptionType.sendTimeout, DioExceptionType.receiveTimeout]) {
        adapter.next = kind;
        await call();
      }
      expect(reports, [false, false, false, false]);
    });

    test('a request the app cancelled says nothing either way', () async {
      adapter.next = DioExceptionType.cancel;
      await call();
      expect(reports, isEmpty);
    });
  });

  group('the reachability state', () {
    test('goes offline on a failure and back on the next answer, announcing only changes', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final seen = <bool>[];
      c.listen(reachabilityProvider, (_, now) => seen.add(now), fireImmediately: true);
      final reach = c.read(reachabilityProvider.notifier);

      reach.reached();
      reach.lost();
      reach.lost();
      reach.reached();
      reach.reached();
      expect(seen, [true, false, true]);
    });
  });

  group('the offline banner', () {
    late ProviderContainer container;
    late Future<void> Function() probe;
    var probes = 0;

    Future<void> pump(WidgetTester tester) async {
      probes = 0;
      probe = () async => probes++;
      await tester.pumpWidget(
        themed(
          const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: OfflineBanner())),
          overrides: [connectionProbeProvider.overrideWithValue(() => probe())],
        ),
      );
      container = ProviderScope.containerOf(tester.element(find.byType(OfflineBanner)));
    }

    testWidgets('is not there while the API can be reached', (tester) async {
      await pump(tester);
      expect(find.textContaining("You're offline"), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('appears when a request fails to connect, and goes when one succeeds', (tester) async {
      await pump(tester);
      container.read(reachabilityProvider.notifier).lost();
      await tester.pumpAndSettle();
      expect(find.text("You're offline. Some things may be out of date."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      container.read(reachabilityProvider.notifier).reached();
      await tester.pumpAndSettle();
      expect(find.textContaining("You're offline"), findsNothing);
    });

    testWidgets('Retry asks the API and clears the banner when it answers', (tester) async {
      await pump(tester);
      probe = () async {
        probes++;
        container.read(reachabilityProvider.notifier).reached(); // what the interceptor does on an answer
      };
      container.read(reachabilityProvider.notifier).lost();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(probes, 1);
      expect(find.textContaining("You're offline"), findsNothing);
    });

    testWidgets('a Retry that fails keeps the banner and can be tried again', (tester) async {
      await pump(tester);
      final gate = Completer<void>();
      probe = () async {
        probes++;
        await gate.future;
        throw const ApiFailure(ApiFailureKind.offline);
      };
      container.read(reachabilityProvider.notifier).lost();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'the button shows it is trying');
      expect(find.text('Retry'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(probes, 1);
    });

    testWidgets('is announced to screen readers when it appears', (tester) async {
      await pump(tester);
      container.read(reachabilityProvider.notifier).lost();
      await tester.pumpAndSettle();
      final live = tester.widgetList<Semantics>(find.byType(Semantics)).where((s) => s.properties.liveRegion == true);
      expect(live, isNotEmpty);
    });
  });

  group('coming back online', () {
    testWidgets('reloads what the tabs show', (tester) async {
      var promoLoads = 0;
      late WidgetRef captured;
      await tester.pumpWidget(
        themed(
          Consumer(
            builder: (context, ref, _) {
              captured = ref;
              ref.watch(promotionsProvider);
              return const SizedBox();
            },
          ),
          overrides: [
            promotionsProvider.overrideWith((ref) async {
              promoLoads++;
              return <PromotionDto>[];
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(promoLoads, 1);

      refreshAfterReconnect(captured);
      await tester.pumpAndSettle();
      expect(promoLoads, 2);
    });
  });
}
