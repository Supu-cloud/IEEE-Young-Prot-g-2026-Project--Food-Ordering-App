import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/core/theme/app_theme.dart';
import 'package:food_ordering_app/features/operations/data/operations_repository.dart';
import 'package:food_ordering_app/features/owner/presentation/owner_connected_screens.dart';
import 'api_client_test.dart' show FakeServer, jsonResponse;

Map<String, dynamic> fixture(String status, [String id = 'one']) => {
  '_id': id,
  'status': status,
  'customer': {'name': 'Customer'},
  'restaurant': 'r',
  'items': [
    {'name': 'Rice', 'quantity': 1},
  ],
  'totalAmount': 850,
  'paymentStatus': 'paid',
};

class Orders extends OperationsRepository {
  Orders() : super(Dio());
  List<Map<String, dynamic>> saved = [
    fixture('placed'),
    fixture('delivered', 'two'),
    fixture('delivery_failed', 'three'),
  ];
  Completer<Map<String, dynamic>>? pending;
  Completer<List<Map<String, dynamic>>>? poll;
  bool failRefresh = false;
  int updates = 0;
  @override
  Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (poll != null) {
      final request = poll!;
      poll = null;
      return request.future;
    }
    if (failRefresh) throw Exception('Refresh offline');
    return saved.map((order) => Map<String, dynamic>.from(order)).toList();
  }

  @override
  Future<Map<String, dynamic>> orderStatus(String id, String status) async {
    updates++;
    final result = await pending!.future;
    saved = saved.map((item) => item['_id'] == id ? result : item).toList();
    return result;
  }
}

Future<void> show(WidgetTester tester, Orders repo, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: OwnerOrdersConnected(repository: repo)),
    ),
  );
  await tester.pumpAndSettle();
}

void expectCard(
  WidgetTester tester,
  String status,
  Color color, {
  bool dark = false,
}) {
  final card = tester.widget<Container>(
    find.byKey(ValueKey('order-one-$status')),
  );
  final decoration = card.decoration! as BoxDecoration;
  expect((decoration.border! as Border).left.color, color);
  expect(decoration.color, isNot(color));
  expect(
    decoration.color!.computeLuminance(),
    dark ? lessThan(.1) : greaterThan(.7),
  );
}

void main() {
  test('order API sends the existing status and notifies metrics only after success', () async {
    final dio = Dio();
    var succeeded = false;
    var notifications = 0;
    dio.httpClientAdapter = FakeServer((request) async {
      expect(request.path, '/orders/one/status');
      expect(request.method, 'PATCH');
      expect(request.data, {'status': 'confirmed'});
      return succeeded
          ? jsonResponse(200, {'data': fixture('confirmed')})
          : jsonResponse(409, {'message': 'Order changed. Refresh and try again.'});
    });
    final repo = OperationsRepository(dio, onOrderChanged: () => notifications++);
    await expectLater(repo.orderStatus('one', 'confirmed'), throwsException);
    expect(notifications, 0);
    succeeded = true;
    expect((await repo.orderStatus('one', 'confirmed'))['status'], 'confirmed');
    expect(notifications, 1);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'backend-confirmed flow, multiple statuses and refreshed colors (dark=$dark)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = Orders();
        await show(tester, repo, dark ? AppTheme.dark : AppTheme.light);
        const steps = [
          (
            'placed',
            Color(0xFFF59E0B),
            'Accept order',
            'confirmed',
            Color(0xFF3B82F6),
          ),
          (
            'confirmed',
            Color(0xFF3B82F6),
            'Start preparing',
            'preparing',
            Color(0xFFF97316),
          ),
          (
            'preparing',
            Color(0xFFF97316),
            'Ready for pickup',
            'ready_for_pickup',
            Color(0xFF22C55E),
          ),
        ];
        for (final step in steps) {
          repo.pending = Completer();
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, step.$3),
          );
          await tester.tap(find.widgetWithText(FilledButton, step.$3));
          await tester.pump();
          expectCard(tester, step.$1, step.$2, dark: dark);
          expect(
            tester
                .widgetList<FilledButton>(find.byType(FilledButton))
                .every((button) => button.onPressed == null),
            isTrue,
          );
          expect(find.text('Saving…'), findsOneWidget);
          repo.pending!.complete(fixture(step.$4));
          await tester.pumpAndSettle();
          expectCard(tester, step.$4, step.$5, dark: dark);
        }
        expect(repo.updates, 3);
        expect(find.text('3 orders'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('order-two-delivered')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('order-three-delivery_failed')),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        await show(tester, repo, dark ? AppTheme.dark : AppTheme.light);
        expectCard(
          tester,
          'ready_for_pickup',
          const Color(0xFF22C55E),
          dark: dark,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final step in [
    ('placed', 'Accept order', const Color(0xFFF59E0B)),
    ('confirmed', 'Start preparing', const Color(0xFF3B82F6)),
    ('preparing', 'Ready for pickup', const Color(0xFFF97316)),
  ]) {
    testWidgets('failure preserves ${step.$1} and allows retry', (
      tester,
    ) async {
      final repo = Orders()..saved = [fixture(step.$1)];
      await show(tester, repo, AppTheme.light);
      repo.pending = Completer();
      await tester.tap(find.widgetWithText(FilledButton, step.$2));
      await tester.pump();
      repo.pending!.completeError(Exception('Backend rejected the update'));
      await tester.pumpAndSettle();
      expectCard(tester, step.$1, step.$3);
      expect(
        find.textContaining('Backend rejected the update'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, step.$2))
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('successful mutation survives a failing refetch', (tester) async {
    final repo = Orders()..saved = [fixture('placed')];
    await show(tester, repo, AppTheme.light);
    repo.pending = Completer();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept order'));
    await tester.pump();
    repo.failRefresh = true;
    repo.pending!.complete(fixture('confirmed'));
    await tester.pumpAndSettle();
    expectCard(tester, 'confirmed', const Color(0xFF3B82F6));
    expect(find.textContaining('Refresh offline'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('an older poll cannot undo a confirmed action', (tester) async {
    final repo = Orders()..saved = [fixture('placed')];
    await show(tester, repo, AppTheme.light);
    final oldPoll = Completer<List<Map<String, dynamic>>>();
    repo.poll = oldPoll;
    await tester.pump(const Duration(seconds: 7));
    repo.pending = Completer();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept order'));
    await tester.pump();
    repo.pending!.complete(fixture('confirmed'));
    await tester.pumpAndSettle();
    oldPoll.complete([fixture('placed')]);
    await tester.pumpAndSettle();
    expectCard(tester, 'confirmed', const Color(0xFF3B82F6));
    await tester.pumpWidget(const SizedBox());
  });
}
