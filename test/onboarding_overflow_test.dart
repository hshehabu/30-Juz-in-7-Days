import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/features/onboarding/presentation/pages/onboarding_flow_page.dart';

void main() {
  testWidgets(
      'Onboarding summary page renders without RenderFlex overflow on narrow screen',
      (tester) async {
    FlutterError.onError = (details) {
      // ignore: avoid_print
      print('FLUTTER ERROR: ${details.exceptionAsString()}');
      for (final d in details.informationCollector?.call() ?? []) {
        // ignore: avoid_print
        print('INFO: $d');
      }
    };

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OnboardingFlowPage(
              onCompleted: () {},
            ),
          ),
        ),
      ),
    );

    // Page 0: Welcome -> Tap "Start My 7-Day Khatmah"
    expect(find.text('Start My 7-Day Khatmah'), findsOneWidget);
    await tester.ensureVisible(find.text('Start My 7-Day Khatmah'));
    await tester.tap(find.text('Start My 7-Day Khatmah'));
    await tester.pumpAndSettle();

    // Page 1: Start Date -> Tap "Continue"
    expect(find.text('Continue'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Page 2: Reminder Time -> Tap "Review Plan"
    expect(find.text('Review Plan'), findsOneWidget);
    await tester.ensureVisible(find.text('Review Plan'));
    await tester.tap(find.text('Review Plan'));
    await tester.pumpAndSettle();

    // Page 3: Summary screen
    final err = tester.takeException();
    if (err is FlutterError) {
      for (final d in err.diagnostics) {
        // ignore: avoid_print
        print('${d.name} -> $d');
      }
    }
    expect(err, isNull);
    expect(find.text('Day 1 Portion'), findsOneWidget);
    expect(find.text('Al-Baqarah → An-Nisa (3 surahs)'), findsOneWidget);
    expect(find.text('Start Khatmah'), findsOneWidget);
  });
}
