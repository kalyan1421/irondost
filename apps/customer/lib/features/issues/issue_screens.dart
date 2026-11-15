import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/routes.dart';
import '../../core/money.dart';
import '../../core/slots.dart';
import '../../core/uuid.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/state_view.dart';
import '../../design/widgets/surfaces.dart';
import '../basket/basket.dart';
import '../orders/order_repository.dart';
import 'issues.dart';

class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<ReportProblemScreen> createState() => _ReportProblemState();
}
class _ReportProblemState extends ConsumerState<ReportProblemScreen> {
  final description = TextEditingController();
  final formKey = GlobalKey<FormState>();
  IssueCategory? category;
  final urls = <String>[];
  final pending = <XFile>[];
  bool sending = false, uploading = false;
  String? error;
  String progress = '';
  CancelToken? upload;
  String requestKey = newUuid();
  CreateIssueDto? submitted;
  late final prefs = ref.read(sharedPreferencesProvider);
  String get draftKey => 'issue.draft.${widget.orderId}';
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => restore()); }
  Future<void> restore() async {
    try {
      final data = jsonDecode(prefs.getString(draftKey) ?? '{}') as Map<String, dynamic>;
      description.text = data['description'] as String? ?? '';
      category = issueCategories.keys.where((c) => c.json == data['category']).firstOrNull;
      urls.addAll((data['photos'] as List? ?? []).cast<String>().take(5));
      pending.addAll((data['pending'] as List? ?? []).cast<String>().take(5 - urls.length).map(XFile.new));
      requestKey = data['requestKey'] as String? ?? newUuid();
      final savedRequest = data['submitted'];
      if (savedRequest is Map) {
        submitted = CreateIssueDto.fromJson(savedRequest.cast<String, Object?>());
        error = 'Your last report may have been sent. Retry the same report to confirm it, or check Your reports.';
      }
      if (prefs.getString('issue.recoveryOrder') == widget.orderId) {
        final recovered = prefs.getStringList('issue.recoveredPhotos') ?? [];
        for (final path in recovered) { if (urls.length + pending.length < 5 && !pending.any((f) => f.path == path)) pending.add(XFile(path)); }
        await prefs.remove('issue.recoveredPhotos');
      }
    } catch (_) { /* A damaged optional local draft must not block reporting. */ }
    if (mounted) setState(() {});
  }
  Future<void> persist() => prefs.setString(draftKey, jsonEncode({'description': description.text, 'category': category?.json,
    'photos': urls, 'pending': pending.map((f) => f.path).toList(), 'requestKey': requestKey, 'submitted': submitted?.toJson()}));
  @override
  void dispose() { upload?.cancel(); description.dispose(); super.dispose(); }
  Future<void> choosePhotos() async {
    if (submitted != null) return;
    try {
      await prefs.setString('issue.recoveryOrder', widget.orderId);
      final files = await ref.read(issuePhotoPickerProvider).pick(5 - urls.length - pending.length);
      if (!mounted) return;
      setState(() => pending.addAll(files.take(5 - urls.length - pending.length)));
      await persist();
      await uploadPending();
    } catch (_) { if (mounted) setState(() => error = 'Could not open photos. You can still send a report without a photo.'); }
  }
  Future<void> uploadPending() async {
    if (uploading) return;
    setState(() { uploading = true; error = null; });
    try {
      for (final file in [...pending]) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 8 * 1024 * 1024) throw StateError('Choose a photo smaller than 8 MB.');
        upload = CancelToken();
        final url = await ref.read(issueRepositoryProvider).upload(bytes, file.name, cancelToken: upload, onProgress: (sent, total) {
          if (mounted) setState(() => progress = total > 0 ? 'Uploading photo ${(100 * sent / total).round()}%' : 'Uploading photo…');
        });
        if (!mounted) return;
        setState(() { urls.add(url); pending.remove(file); });
        await persist();
      }
    } catch (e) {
      if (mounted) setState(() => error = e is StateError ? e.message.toString() : 'Photo upload stopped. Retry or remove the pending photo before sending.');
    } finally { if (mounted) setState(() { uploading = false; progress = ''; }); }
  }
  Future<void> send() async {
    if (sending || uploading || pending.isNotEmpty || (submitted == null && !formKey.currentState!.validate())) return;
    setState(() { sending = true; error = null; });
    try {
      submitted ??= CreateIssueDto(category: category!, description: description.text.trim(), photoUrls: [...urls]);
      await persist();
      final issue = await ref.read(issueRepositoryProvider).create(widget.orderId, submitted!, requestKey);
      await prefs.remove(draftKey);
      ref.invalidate(issuesProvider);
      if (mounted) context.pushReplacement(Routes.issue(issue.id));
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      final rejected = failure.kind == ApiFailureKind.rejected && failure.code != 'IDEMPOTENCY_KEY_REUSED';
      setState(() {
        sending = false;
        if (rejected) {
          submitted = null;
          requestKey = newUuid();
          error = failure.message ?? 'The report needs a correction. Your draft is kept.';
        } else {
          error = 'Could not confirm this report. Retry sends the same details without creating a duplicate. You can also check Your reports.';
        }
      });
      if (rejected) await persist();
    }
  }
  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.orderId));
    final t = context.text;
    if (order.value == null) { return Scaffold(appBar: AppBar(title: const Text('Report a problem')), body: order.hasError
      ? StateView(icon: LucideIcons.circleAlert, title: "Couldn't load this order", body: 'Try again before sending a report.',
        primary: IdButton(label: 'Try again', onPressed: () => ref.invalidate(orderProvider(widget.orderId)))) : const Center(child: CircularProgressIndicator())); }
    return PopScope(canPop: !sending, child: Scaffold(appBar: AppBar(title: const Text('Report a problem')),
      body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(IdSpace.s5), children: [
        Text(order.value!.orderNumber, style: t.orderId),
        const SizedBox(height: IdSpace.s3),
        Text('Tell us what happened', style: t.titleLg),
        const SizedBox(height: IdSpace.s3),
        DropdownButtonFormField<IssueCategory>(key: ValueKey(category), initialValue: category, isExpanded: true, itemHeight: null, decoration: const InputDecoration(labelText: 'Problem type'),
          items: issueCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: sending || submitted != null ? null : (v) { setState(() => category = v); persist(); }, validator: (v) => v == null ? 'Choose a problem type.' : null),
        const SizedBox(height: IdSpace.s4),
        TextFormField(controller: description, enabled: !sending && submitted == null, minLines: 4, maxLines: 8, maxLength: 2000,
          decoration: const InputDecoration(labelText: 'What happened?', helperText: 'Include the garment and any details that help us check.'),
          onChanged: (_) => persist(), validator: (v) => v == null || v.trim().isEmpty ? 'Describe the problem.' : null),
        const SizedBox(height: IdSpace.s3),
        Text('Photos (optional, up to 5)', style: t.title),
        for (final url in urls) ListTile(leading: SizedBox(width: 48, height: 48, child: Image.network(url, fit: BoxFit.cover, semanticLabel: 'Selected garment photo', errorBuilder: (_, _, _) => const Icon(LucideIcons.image))), title: Text( 'Uploaded photo ${urls.indexOf(url) + 1}'),
          trailing: IconButton(tooltip: 'Remove uploaded photo ${urls.indexOf(url) + 1}', onPressed: sending || uploading || submitted != null ? null : () { setState(() => urls.remove(url)); persist(); }, icon: const Icon(LucideIcons.x))),
        for (final file in [...pending]) ListTile(leading: const Icon(LucideIcons.image), title: Text( 'Pending photo: ${file.name}'),
          trailing: IconButton(tooltip: 'Remove pending photo', onPressed: sending || uploading ? null : () { setState(() => pending.remove(file)); persist(); }, icon: const Icon(LucideIcons.x))),
        if (urls.length + pending.length < 5 && submitted == null) IdButton.outline(label: 'Add photos', onPressed: sending || uploading ? null : choosePhotos),
        if (uploading) ...[Text(progress.isEmpty ? 'Uploading photo…' : progress, style: t.body), IdButton.text(label: 'Stop upload', onPressed: () => upload?.cancel())],
        if (!uploading && pending.isNotEmpty) IdButton.outline(label: 'Retry photo upload', onPressed: uploadPending),
        if (error != null) Text(error!, style: t.body.copyWith(color: context.colors.danger)),
        const SizedBox(height: IdSpace.s4),
        Text('Your report will appear in Your reports. You can see replies and its status there.', style: t.body),
        if (pending.isNotEmpty) Text('Upload or remove pending photos to send.', style: t.body),
        const SizedBox(height: IdSpace.s4),
        IdButton(label: submitted == null ? 'Send report' : 'Retry same report', loading: sending, onPressed: uploading || pending.isNotEmpty ? null : send, expand: true),
      ])),
    ));
  }
}

class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key, this.orderId});
  final String? orderId;
  @override
  ConsumerState<IssuesScreen> createState() => _IssuesState();
}
class _IssuesState extends ConsumerState<IssuesScreen> {
  int page = 1;
  @override
  Widget build(BuildContext context) {
    final query = (orderId: widget.orderId, page: page);
    final async = ref.watch(issuesProvider(query));
    return Scaffold(appBar: AppBar(title: const Text('Your reports')), body: async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => StateView(icon: LucideIcons.circleAlert, title: "Couldn't load reports", body: 'Check your connection and try again.', primary: IdButton(label: 'Try again', onPressed: () => ref.invalidate(issuesProvider(query)))),
      data: (data) => data.items.isEmpty ? const StateView(icon: LucideIcons.messageSquare, title: 'No reports yet', body: 'Open an order and choose Report a problem if you need help with it.')
        : RefreshIndicator(onRefresh: () async { ref.invalidate(issuesProvider(query)); await ref.read(issuesProvider(query).future); }, child: ListView(padding: const EdgeInsets.all(IdSpace.s5), children: [
          for (final issue in data.items) IdListRow(icon: LucideIcons.messageSquare, label: '${issue.orderNumber} · ${issueCategories[issue.category] ?? 'Report'}',
            value: issueStatusLabel(issue.status), onTap: () => context.push(Routes.issue(issue.id))),
          Wrap(spacing: IdSpace.s3, children: [TextButton(onPressed: page > 1 ? () => setState(() => page--) : null, child: const Text('Previous')),
            TextButton(onPressed: page * data.pageSize < data.total ? () => setState(() => page++) : null, child: const Text('Next'))]),
        ])),
    ));
  }
}

class IssueDetailScreen extends ConsumerStatefulWidget {
  const IssueDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailState();
}
class _IssueDetailState extends ConsumerState<IssueDetailScreen> {
  final reply = TextEditingController();
  bool sending = false;
  String? error;
  @override
  void dispose() { reply.dispose(); super.dispose(); }
  Future<void> send() async {
    if (sending || reply.text.trim().isEmpty) return;
    setState(() { sending = true; error = null; });
    try { await ref.read(issueRepositoryProvider).reply(widget.id, reply.text.trim()); reply.clear(); ref.invalidate(issueProvider(widget.id)); }
    catch (_) { if (mounted) setState(() => error = 'Could not send your reply. Your text is kept. Try again.'); }
    finally { if (mounted) setState(() => sending = false); }
  }
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(issueProvider(widget.id));
    final t = context.text;
    return Scaffold(appBar: AppBar(title: const Text('Report details')), body: async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => StateView(icon: LucideIcons.circleAlert, title: "Couldn't load this report", body: 'It may be unavailable or your connection may be offline.', primary: IdButton(label: 'Try again', onPressed: () => ref.invalidate(issueProvider(widget.id)))),
      data: (issue) => ListView(padding: const EdgeInsets.all(IdSpace.s5), children: [
        SelectableText('Report ${issue.id}', style: t.caption),
        Text(issueStatusLabel(issue.status), style: t.titleLg),
        TextButton(onPressed: () => context.push(Routes.order(issue.orderId)), child: Text(issue.orderNumber)),
        Text(issueCategories[issue.category] ?? 'Report', style: t.title),
        Text(issue.description, style: t.bodyLg),
        if (issue.firstResponseDueAt != null && issue.acknowledgedAt == null) Text('First response target: ${istDateTimeLabel(issue.firstResponseDueAt!)}', style: t.body),
        for (final url in issue.photoUrls) Padding(padding: const EdgeInsets.symmetric(vertical: IdSpace.s2), child: Image.network(url, semanticLabel: 'Garment evidence photo', height: 180, fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text('Photo could not load. Pull to refresh or try again later.'))),
        const SizedBox(height: IdSpace.s4),
        if (issue.messages.isEmpty) Text('No replies yet. Your report is saved.', style: t.body),
        for (final message in issue.messages) Padding(padding: const EdgeInsets.only(bottom: IdSpace.s3), child: IdCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(message.fromStaff ? 'IronDost team' : 'You', style: t.title), Text(message.body, style: t.body), Text(istDateTimeLabel(message.createdAt), style: t.caption),
        ]))),
        if (issue.resolutionNote != null) IdCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Resolution: ${issue.resolutionNote}', style: t.bodyLg),
          if ((issue.compensationPaise ?? 0) > 0) Text('Agreed remedy: ${rupees(issue.compensationPaise!)}. Any refund shows under Refunds on the order.', style: t.body),
        ])),
        if (issue.status == IssueStatus.open || issue.status == IssueStatus.acknowledged) ...[
          TextField(controller: reply, enabled: !sending, minLines: 2, maxLines: 6, maxLength: 2000, decoration: const InputDecoration(labelText: 'Reply to the team')),
          if (error != null) Text(error!, style: t.body.copyWith(color: context.colors.danger)),
          IdButton(label: 'Send reply', loading: sending, onPressed: send, expand: true),
        ],
        TextButton(onPressed: () => ref.invalidate(issueProvider(widget.id)), child: const Text('Refresh report')),
      ]),
    ));
  }
}
