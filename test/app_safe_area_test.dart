import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final bottomInset in [0.0, 24.0, 48.0]) {
    testWidgets(
      'pushed screens avoid a $bottomInset navigation inset once',
      (tester) async {
        // Simulate a phone screen.
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(800, 900);

        // Simulate Android system navigation bar inset.
        tester.view.padding = FakeViewPadding(
          bottom: bottomInset,
        );

        tester.view.viewPadding = FakeViewPadding(
          bottom: bottomInset,
        );

        addTearDown(tester.view.reset);

        // We only need a MaterialApp + Navigator for this SafeArea test.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Home'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // MaterialApp creates the Navigator.
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator),
        );

        // Push a detail screen.
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Detail'),
              ),
              body: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    key: const Key('bottom-action'),
                    height: 48,
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('Go'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Make sure the button exists.
        expect(
          find.byKey(const Key('bottom-action')),
          findsOneWidget,
        );

        // SafeArea should keep the button above the system navigation inset.
        expect(
          tester
              .getBottomLeft(
                find.byKey(const Key('bottom-action')),
              )
              .dy,
          900 - bottomInset,
        );

        // Simulate the keyboard opening.
        tester.view.padding = FakeViewPadding.zero;

        tester.view.viewInsets = const FakeViewPadding(
          bottom: 300,
        );

        await tester.pumpAndSettle();

        // Scaffold should resize above the keyboard.
        expect(
          tester
              .getBottomLeft(
                find.byKey(const Key('bottom-action')),
              )
              .dy,
          600,
        );

        // No Flutter exception should occur.
        expect(
          tester.takeException(),
          isNull,
        );
      },
    );
  }
}