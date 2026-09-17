import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/app/app.dart';
import 'package:food_ordering_app/core/di/app_dependencies.dart';

void main() {
  for (final bottomInset in [0.0, 24.0, 48.0]) {
    testWidgets('pushed screens avoid a $bottomInset navigation inset once', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 900);
      tester.view.padding = FakeViewPadding(bottom: bottomInset);
      tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        FoodOrderingApp(dependencies: AppDependencies.create(serverClientId: '')),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Detail')),
            body: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  key: const Key('bottom-action'),
                  height: 48,
                  child: FilledButton(onPressed: () {}, child: const Text('Go')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byKey(const Key('bottom-action'))).dy,
        900 - bottomInset,
      );
      // When the keyboard consumes the system inset, Scaffold handles its height.
      tester.view.padding = FakeViewPadding.zero;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byKey(const Key('bottom-action'))).dy,
        600,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
