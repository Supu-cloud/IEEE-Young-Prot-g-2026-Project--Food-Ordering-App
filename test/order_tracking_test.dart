import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/features/customer/data/customer_repository.dart';
import 'package:food_ordering_app/features/customer/presentation/order_tracking_screen.dart';

class TrackingRepository extends CustomerRepository {
  TrackingRepository() : super(Dio());
  int calls = 0;
  @override
  Future<Map<String, dynamic>> getTracking(String id) async {
    calls++;
    if (calls > 1) throw Exception('Network unavailable');
    return {
      '_id': id,
      'status': 'preparing',
      'createdAt': '2026-09-09T08:00:00Z',
      'deliveryAddress': 'Test address',
      'totalAmount': 1000,
    };
  }
}

void main() {
  testWidgets('shows backend status and retains it when polling fails', (tester) async {
    final repository = TrackingRepository();
    await tester.pumpWidget(MaterialApp(home: OrderTrackingScreen(repository: repository, orderId: 'order-123')));
    await tester.pumpAndSettle();
    expect(find.text('PREPARING'), findsOneWidget);
    expect(find.text('Preparing — Current'), findsOneWidget);
    expect(find.text('Timestamp unavailable'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('PREPARING'), findsOneWidget);
    expect(find.textContaining('Showing last loaded status.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 8));
    expect(repository.calls, 2);
  });
}
