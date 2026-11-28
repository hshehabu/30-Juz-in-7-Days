import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/features/navigation/floating_nav_bar.dart';

const _items = [
  FloatingNavItem(icon: Icons.menu_book_rounded, label: 'Today'),
  FloatingNavItem(icon: Icons.timeline_rounded, label: 'Journey'),
  FloatingNavItem(icon: Icons.tune_rounded, label: 'Settings'),
];

Widget _host({
  required int index,
  required ValueChanged<int> onTap,
  TextDirection direction = TextDirection.ltr,
  List<FloatingNavItem> items = _items,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: FloatingNavBar(
          items: items,
          currentIndex: index,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tapping an item reports its index and marks it selected',
      (tester) async {
    var index = 0;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) => _host(
        index: index,
        onTap: (i) => setState(() => index = i),
      ),
    ));

    await tester.tap(find.byIcon(Icons.timeline_rounded));
    await tester.pumpAndSettle();
    expect(index, 1);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Journey')),
      isSemantics(label: 'Journey', isButton: true, isSelected: true),
    );
  });

  testWidgets('long labels fit on a narrow phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      index: 2,
      onTap: (_) {},
      items: const [
        FloatingNavItem(icon: Icons.menu_book_rounded, label: 'ورد اليوم'),
        FloatingNavItem(icon: Icons.timeline_rounded, label: 'المسار الطويل'),
        FloatingNavItem(icon: Icons.tune_rounded, label: 'الإعدادات'),
      ],
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('order mirrors in right-to-left layouts', (tester) async {
    await tester.pumpWidget(_host(
      index: 0,
      onTap: (_) {},
      direction: TextDirection.rtl,
    ));
    await tester.pumpAndSettle();

    final first = tester.getCenter(find.byIcon(Icons.menu_book_rounded));
    final last = tester.getCenter(find.byIcon(Icons.tune_rounded));
    expect(first.dx, greaterThan(last.dx));
  });
}
