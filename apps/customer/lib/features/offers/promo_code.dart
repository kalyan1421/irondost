import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/theme.dart';

/// Copies [code] and says where to use it.
void copyPromoCode(BuildContext context, String code) {
  Clipboard.setData(ClipboardData(text: code));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Code $code copied. Apply it in your basket.')));
}

/// The code in a bordered chip. With [onTap] it is a button that copies the code (and shows the copy icon).
class PromoCodeChip extends StatelessWidget {
  const PromoCodeChip(this.code, {super.key, this.onTap});

  final String code;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(IdRadius.sm), border: Border.all(color: c.text, width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(code, style: t.orderId),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(LucideIcons.copy, size: IdSize.iconSm, color: c.text),
          ],
        ],
      ),
    );
    if (onTap == null) return Semantics(label: 'Code $code', excludeSemantics: true, child: chip);
    return Semantics(
      button: true,
      label: 'Copy code $code',
      excludeSemantics: true,
      child: InkWell(borderRadius: BorderRadius.circular(IdRadius.sm), onTap: onTap, child: chip),
    );
  }
}
