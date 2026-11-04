import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A title, six dots and a number pad. Digit keys on a hardware keyboard
/// work too. Calls [onCompleted] on the sixth digit and clears the dots
/// once it returns.
class PinPad extends StatefulWidget {
  const PinPad({
    required this.title,
    required this.onCompleted,
    this.message,
    this.isError = false,
    this.enabled = true,
    this.shortcut,
    this.footer,
    super.key,
  });

  final String title;
  final String? message;
  final bool isError;
  final bool enabled;
  final Future<void> Function(String pin) onCompleted;

  /// The key left of 0, for an unlock shortcut such as biometrics.
  final Widget? shortcut;
  final Widget? footer;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;

  bool get _acceptsInput => widget.enabled && !_busy;

  Future<void> _add(String digit) async {
    if (!_acceptsInput || _pin.length == pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length < pinLength) return;
    setState(() => _busy = true);
    try {
      await widget.onCompleted(_pin);
    } finally {
      if (mounted) {
        setState(() {
          _pin = '';
          _busy = false;
        });
      }
    }
  }

  void _delete() {
    if (!_acceptsInput || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final character = event.character;
    if (character != null && RegExp(r'^\d$').hasMatch(character)) {
      _add(character).ignore();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _delete();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      widget.message ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isError ? colors.error : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: l10n.pinDigitsEntered(_pin.length, pinLength),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < pinLength; i++)
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < _pin.length ? colors.primary : null,
                                border: Border.all(color: colors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      for (final digit in '123456789'.split(''))
                        _Key(
                          onPressed: _acceptsInput ? () => _add(digit) : null,
                          child: Text(digit),
                        ),
                      widget.shortcut ?? const SizedBox.shrink(),
                      _Key(
                        onPressed: _acceptsInput ? () => _add('0') : null,
                        child: const Text('0'),
                      ),
                      _Key(
                        onPressed: _acceptsInput ? _delete : null,
                        child: Icon(
                          Icons.backspace_outlined,
                          semanticLabel: l10n.pinDelete,
                        ),
                      ),
                    ],
                  ),
                  if (widget.footer != null) ...[
                    const SizedBox(height: 16),
                    widget.footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.child, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      shape: const StadiumBorder(),
      textStyle: Theme.of(context).textTheme.headlineSmall,
    ),
    child: child,
  );
}
