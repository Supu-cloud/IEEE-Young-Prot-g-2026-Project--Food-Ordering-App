import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/app/app.dart';
import 'package:food_ordering_app/core/di/app_dependencies.dart';

void main() {
  testWidgets('shows the shared login screen', (tester) async {
    await tester.pumpWidget(
      FoodOrderingApp(dependencies: AppDependencies.create(serverClientId: '')),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
  });
}
