import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/theme.dart';
import 'location_service.dart';
import 'map_pin_controller.dart';
import 'place.dart';

/// Type an area, street or building; pick a result. Pops with the chosen [Place].
class PlaceSearchScreen extends ConsumerStatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

enum _Phase { idle, searching, done, failed }

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  var _phase = _Phase.idle;
  var _results = const <Place>[];
  var _run = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() => _phase = _Phase.idle);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), _search);
  }

  Future<void> _search() async {
    final run = ++_run;
    setState(() => _phase = _Phase.searching);
    try {
      final places = await ref.read(locationServiceProvider).search(_query.text);
      if (!mounted || run != _run) return;
      setState(() {
        _results = places;
        _phase = _Phase.done;
      });
    } catch (_) {
      if (!mounted || run != _run) return;
      setState(() => _phase = _Phase.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final blocked = ref.watch(mapPinProvider.select((s) => s.locationBlocked));
    final access = ref.watch(mapPinProvider.select((s) => s.access));

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(IdSpace.s2, IdSpace.s1, IdSpace.s4, IdSpace.s3),
              child: Row(
                children: [
                  IconButton(icon: const Icon(LucideIcons.arrowLeft), tooltip: 'Back', onPressed: context.pop),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      style: t.bodyLg,
                      onChanged: _changed,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'Search area, street or building',
                        prefixIcon: Icon(LucideIcons.search, size: IdSize.iconMd, color: c.textMuted),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(LucideIcons.x, size: IdSize.iconMd),
                                tooltip: 'Clear',
                                onPressed: () {
                                  _query.clear();
                                  _changed('');
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (blocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s3),
                child: _Notice(
                  text: 'Location is off, so search for your address instead.',
                  action: 'Turn on',
                  onAction: () => ref.read(locationServiceProvider).openSettings(access),
                ),
              ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget message(String text) => Padding(
          padding: const EdgeInsets.all(IdSpace.s6),
          child: Text(text, style: t.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
        );

    return switch (_phase) {
      _Phase.idle => message('Type at least 3 letters of your area, street or building.'),
      _Phase.searching => const Center(child: CircularProgressIndicator()),
      _Phase.failed => message("Couldn't search. Check your connection and try again."),
      _Phase.done when _results.isEmpty => message('No matches. Try the nearest street or landmark, then move the pin.'),
      _Phase.done => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4),
          itemCount: _results.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (_, i) {
            final p = _results[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: IdSpace.s3,
              leading: Icon(LucideIcons.mapPin, color: c.textMuted),
              title: Text(p.title, style: t.title),
              subtitle: p.subtitle.isEmpty ? null : Text(p.subtitle, style: t.caption.copyWith(color: c.textMuted)),
              onTap: () => context.pop(p),
            );
          },
        ),
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(IdRadius.md)),
      child: Row(
        children: [
          Icon(LucideIcons.mapPinOff, size: IdSize.iconMd, color: c.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.text.body)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
