import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../design/theme.dart';
import 'legal_content.dart';

/// A policy as plain readable text: numbered headings, paragraphs and bullet lists.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final page = doc.page;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.account)),
        title: Text(page.title, style: t.titleLg),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(LegalContent.byline, style: t.caption.copyWith(color: c.textMuted)),
          for (final section in page.sections) ...[
            const SizedBox(height: 20),
            Semantics(header: true, child: Text(section.heading, style: t.titleLg)),
            const SizedBox(height: IdSpace.s2),
            for (final p in section.paragraphs) Padding(padding: const EdgeInsets.only(bottom: IdSpace.s2), child: Text(p, style: t.bodyLg)),
            for (final b in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: Padding(padding: const EdgeInsets.only(left: 4, right: 10), child: Text('•', style: t.bodyLg))),
                    Expanded(child: Text(b, style: t.bodyLg)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: IdSpace.s6),
        ],
      ),
    );
  }
}
