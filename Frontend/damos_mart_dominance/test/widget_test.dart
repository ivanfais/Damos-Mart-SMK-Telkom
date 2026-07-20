import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:damos_mart_dominance/screens/auth/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen shows email reset form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Lupa Password'), findsOneWidget);
    expect(find.text('Kirim Link Reset'), findsOneWidget);
    expect(
      find.text(
        'Masukkan email terdaftar Anda. Kami akan mengirim link reset password ke Gmail Anda.',
      ),
      findsOneWidget,
    );
  });
}
