import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/app/foodie_startup.dart';
import 'package:food_ordering_app/app/splash/foodie_splash.dart';
import 'package:food_ordering_app/core/di/app_dependencies.dart';

void main() {
  testWidgets('waits for initialization and then opens the login screen', (
    tester,
  ) async {
    final ready = Completer<void>();
    await tester.pumpWidget(
      FoodieStartup(
        dependencies: AppDependencies.create(serverClientId: ''),
        initialize: () => ready.future,
      ),
    );
    expect(find.text('Foodie'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(FoodieSplash), findsOneWidget);
    ready.complete();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(FoodieSplash), findsNothing);
  });

  testWidgets('startup error offers retry and recovers', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      FoodieStartup(
        dependencies: AppDependencies.create(serverClientId: ''),
        minimumDisplay: Duration.zero,
        initialize: () async {
          if (++calls == 1) throw StateError('test');
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('splash fits $size dark=$dark with reduced motion', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
        addTearDown(tester.view.reset);
        // Optional review artifacts, using a local font only in the test runner.
        final previewDir = Platform.environment['FOODIE_SPLASH_PREVIEW'];
        final fontPath = Platform.environment['FOODIE_PREVIEW_FONT'];
        if (previewDir != null && fontPath != null) {
          final loader = FontLoader('Roboto')
            ..addFont(
              Future.value(
                ByteData.sublistView(File(fontPath).readAsBytesSync()),
              ),
            );
          await tester.runAsync(loader.load);
        }
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(1.4),
                ),
                child: child!,
              ),
              home: const FoodieSplash(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Foodie'), findsOneWidget);
        expect(find.text(FoodieSplash.developerCredit), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Image && widget.semanticLabel == 'Sri Lanka',
          ),
          findsOneWidget,
        );
        expect(
          FoodieSplash.developerCredit,
          'Developed by Soft. Dev | G 04 for Young Prot\u00e9g\u00e9 2026.',
        );
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          const Color(0xFF101D16),
        );
        final credit = tester.getRect(
          find.byKey(const Key('splash-developer-credit')),
        );
        expect(credit.bottom, lessThanOrEqualTo(size.height - 34));
        expect(credit.left, greaterThanOrEqualTo(0));
        expect(credit.right, lessThanOrEqualTo(size.width));
        expect(tester.takeException(), isNull);
        expect(tester.binding.hasScheduledFrame, isFalse);
        if (previewDir != null) {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(previewDir).create(recursive: true);
            await File(
              '$previewDir/splash-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}
