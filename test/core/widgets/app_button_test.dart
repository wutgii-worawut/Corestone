import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int> tapCount(WidgetTester tester, {required bool isLoading}) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Center(
          child: AppButton(
            label: 'Go',
            isLoading: isLoading,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    return taps;
  }

  testWidgets('an enabled button calls onPressed', (tester) async {
    expect(await tapCount(tester, isLoading: false), 1);
  });

  testWidgets('a loading button ignores taps', (tester) async {
    expect(await tapCount(tester, isLoading: true), 0);
  });
}
