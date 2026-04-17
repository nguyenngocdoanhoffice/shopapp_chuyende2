import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopapp/main.dart';

void main() {
  testWidgets('missing config screen renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MissingConfigScreen()),
    );
    expect(find.textContaining('Supabase config is missing'), findsOneWidget);
  });
}
