import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpCodeField extends StatefulWidget {
  final int length;
  final void Function(String code)? onCompleted;

  const OtpCodeField({super.key, this.length = 6, this.onCompleted});

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes =
      List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.unfocus();
      n.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _onChanged(int i, String v) {
    if (v.length == 1 && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    }
    if (_value.length == widget.length) {
      widget.onCompleted?.call(_value);
    }
    setState(() {});
  }

  void _onBackspace(int i, KeyEvent ev) {
    if (ev is KeyDownEvent &&
        ev.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _nodes[i - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 44,
          child: Focus(
            onKeyEvent: (node, ev) {
              _onBackspace(i, ev);
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              onChanged: (v) => _onChanged(i, v),
              textAlign: TextAlign.center,
              maxLength: 1,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.primary, width: 1.6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
