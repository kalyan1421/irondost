import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Six boxes for the SMS code, driven by one hidden field so paste and SMS autofill work
/// (`AutofillHints.oneTimeCode` on iOS). Calls [onCompleted] on the last digit.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(OtpInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final code = widget.controller.text;
    final active = _focus.hasFocus
        ? code.length.clamp(0, widget.length - 1)
        : -1;

    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      value: code.isEmpty ? null : code.split('').join(' '),
      textField: true,
      child: Stack(
        children: [
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < widget.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < widget.length - 1 ? IdSpace.s1 : 0,
                      ),
                      child: Container(
                        height:
                            56 +
                            (MediaQuery.textScalerOf(context).scale(1) - 1)
                                    .clamp(0, 2) *
                                32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(IdRadius.md),
                          border: Border.all(
                            color: widget.hasError
                                ? c.danger
                                : i == active
                                ? c.primary
                                : c.borderStrong,
                            width: widget.hasError || i == active ? 2 : 1,
                          ),
                        ),
                        child: i < code.length
                            ? Text(code[i], style: t.headline)
                            : i == active
                            ? Container(width: 2, height: 24, color: c.primary)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) {
                  if (v.length == widget.length) widget.onCompleted(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
