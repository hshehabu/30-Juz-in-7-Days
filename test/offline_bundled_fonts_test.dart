import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thirty_juz_in_7_days/core/theme/app_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bundled fonts load without network request when runtime fetching is disabled',
      (tester) async {
    // Enforce strictly offline behavior
    GoogleFonts.config.allowRuntimeFetching = false;

    final textTheme = AppTypography.textTheme(ThemeData.light().textTheme);
    final scholarly = AppTypography.scholarlyQuote();
    final appBar = AppTypography.appBarTitle();
    final arabicTitle = AppTypography.arabicSurahTitle();

    // Build a widget rendering these styles
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(textTheme: textTheme),
        home: Scaffold(
          appBar: AppBar(title: Text('Title', style: appBar)),
          body: Column(
            children: [
              Text('Display', style: textTheme.displayLarge),
              Text('Quote', style: scholarly),
              Text('Arabic Title', style: arabicTitle),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Quote'), findsOneWidget);
    expect(find.text('Arabic Title'), findsOneWidget);
  });
}
