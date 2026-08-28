import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  testWidgets('AppEmptyState matches golden', (tester) async {
    await tester.pumpWidget(
      wrap(const AppEmptyState(message: 'Nothing here yet')),
    );
    await expectLater(
      find.byType(AppEmptyState),
      matchesGoldenFile('goldens/app_empty_state.png'),
    );
  });

  testWidgets('AppErrorView matches golden', (tester) async {
    await tester.pumpWidget(
      wrap(const AppErrorView(message: 'Something went wrong')),
    );
    await expectLater(
      find.byType(AppErrorView),
      matchesGoldenFile('goldens/app_error_view.png'),
    );
  });
}
