import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:falcon/widgets/connection_status_indicator.dart';

void main() {
  group('ConnectionStatusIndicator', () {
    testWidgets('should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectionStatusIndicator(
            child: Text('Test Child'),
          ),
        ),
      );

      // The widget should build without throwing exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
