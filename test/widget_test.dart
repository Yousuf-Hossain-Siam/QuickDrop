import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/app/app.dart';

void main() {
  testWidgets('shows the QuickDrop splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuickDrop()));
    expect(find.text('QUICKDROP'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
