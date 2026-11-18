import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/issues/issues.dart';
import 'package:irondost_customer/features/issues/issue_screens.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import '../helpers.dart';

IssueDto report({IssueStatus status = IssueStatus.open}) => IssueDto(id: 'issue-1', orderId: 'o-1', orderNumber: 'ID001046',
  category: IssueCategory.quality, status: status, description: 'The shirt needs another press.', photoUrls: [],
  firstResponseDueAt: null, acknowledgedAt: null, resolvedAt: status == IssueStatus.resolved ? DateTime.utc(2026, 11, 14) : null,
  resolutionNote: status == IssueStatus.resolved ? 'Re-ironing arranged with you.' : null,
  compensationPaise: status == IssueStatus.resolved ? 5000 : null,
  createdAt: DateTime.utc(2026, 11, 14), updatedAt: DateTime.utc(2026, 11, 14), messages: []);

class Reports implements IssueRepository {
  bool getFails = false;
  IssueStatus status = IssueStatus.open;
  CreateIssueDto? submitted;
  String? requestKey;
  final replies = <String>[];
  @override
  Future<IssuePageDto> list({String? orderId, int page = 1}) async => IssuePageDto(items: [report(status: status)], page: 1, pageSize: 25, total: 1);
  @override
  Future<IssueDto> get(String id) async { if (getFails) throw const ApiFailure(ApiFailureKind.offline); return report(status: status); }
  @override
  Future<IssueDto> create(String orderId, CreateIssueDto body, String key) async { submitted = body; requestKey = key; throw const ApiFailure(ApiFailureKind.offline); }
  @override
  Future<IssueDto> reply(String id, String body) async { replies.add(body); throw const ApiFailure(ApiFailureKind.offline); }
  @override
  Future<String> upload(Uint8List bytes, String name, {CancelToken? cancelToken, void Function(int, int)? onProgress}) async => 'https://example.com/photo.webp';
}

void main() {
  testWidgets('report restores its draft and preserves category and text after a failed send', (tester) async {
    final repo = Reports();
    final overrides = await basketOverrides(saved: {'issue.draft.o-1': jsonEncode({'category': 'QUALITY', 'description': 'My shirt still has creases.', 'photos': [], 'pending': []})});
    await tester.pumpWidget(themed(const ReportProblemScreen(orderId: 'o-1'), overrides: [...overrides,
      orderRepositoryProvider.overrideWithValue(FakeOrderRepository()), issueRepositoryProvider.overrideWithValue(repo)]));
    await tester.pumpAndSettle();
    expect(find.text('My shirt still has creases.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Send report'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(repo.submitted?.category, IssueCategory.quality);
    expect(repo.submitted?.description, 'My shirt still has creases.');
    expect(find.textContaining('Could not confirm this report'), findsOneWidget);
    expect(find.text('Retry same report'), findsOneWidget);
    expect(find.text('My shirt still has creases.'), findsOneWidget);
    final firstKey = repo.requestKey;
    await tester.tap(find.text('Retry same report'));
    await tester.pumpAndSettle();
    expect(repo.requestKey, firstKey);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(themed(const ReportProblemScreen(orderId: 'o-1'), overrides: [...overrides,
      orderRepositoryProvider.overrideWithValue(FakeOrderRepository()), issueRepositoryProvider.overrideWithValue(repo)]));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Retry same report'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Retry same report'), findsOneWidget);
    await tester.tap(find.text('Retry same report'));
    await tester.pumpAndSettle();
    expect(repo.requestKey, firstKey);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new report asks for a problem type and a description before it sends anything', (tester) async {
    final repo = Reports();
    final overrides = await basketOverrides();
    await tester.pumpWidget(themed(const ReportProblemScreen(orderId: 'o-1'), overrides: [...overrides,
      orderRepositoryProvider.overrideWithValue(FakeOrderRepository()), issueRepositoryProvider.overrideWithValue(repo)]));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Send report'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a problem type.'), findsOneWidget);
    expect(find.text('Describe the problem.'), findsOneWidget);
    expect(repo.submitted, isNull);

    await tester.scrollUntilVisible(find.text('Choose one'), -200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Choose one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(issueCategories[IssueCategory.quality]!));
    await tester.pumpAndSettle();
    expect(find.text('Choose a problem type.'), findsNothing);
    expect(find.text(issueCategories[IssueCategory.quality]!), findsOneWidget);
    expect(find.text('Describe the problem.'), findsOneWidget);
  });

  testWidgets('report detail recovers from offline, keeps failed replies, and shows no invented deadline', (tester) async {
    final repo = Reports()..getFails = true;
    await tester.pumpWidget(themed(const IssueDetailScreen(id: 'issue-1'), overrides: [issueRepositoryProvider.overrideWithValue(repo)]));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load this report"), findsOneWidget);
    repo.getFails = false;
    await tester.tap(find.text('Try again')); await tester.pumpAndSettle();
    expect(find.textContaining('First response target:'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Please call before collection.');
    await tester.ensureVisible(find.text('Send reply')); await tester.tap(find.text('Send reply')); await tester.pumpAndSettle();
    expect(repo.replies, ['Please call before collection.']);
    expect(find.text('Please call before collection.'), findsOneWidget);
    expect(find.textContaining('Could not send your reply'), findsOneWidget);
  });

  testWidgets('closed report shows its resolution at 200% text on a small phone', (tester) async {
    tester.view.physicalSize = const Size(960, 2220); tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(themed(const IssueDetailScreen(id: 'issue-1'), textScale: 2,
      overrides: [issueRepositoryProvider.overrideWithValue(Reports()..status = IssueStatus.resolved)]));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Resolution: Re-ironing arranged with you.'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Agreed remedy: ₹50'), findsOneWidget);
    expect(find.text('Send reply'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
