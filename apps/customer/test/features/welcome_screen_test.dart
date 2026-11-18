import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/features/auth/welcome_screen.dart';
import '../helpers.dart';

void main() {
  // cacheHeight wraps the asset in a ResizeImage; look through it.
  Finder asset(String name) => find.byWidgetPredicate((w) {
    if (w is! Image) return false;
    final image = w.image is ResizeImage ? (w.image as ResizeImage).imageProvider : w.image;
    return image is AssetImage && image.assetName == name;
  });

  testWidgets('the first screen shows the same service artwork as home, and still the way in', (tester) async {
    await tester.pumpWidget(themed(const WelcomeScreen()));
    expect(asset('assets/services/ironing-3d.png'), findsOneWidget);
    expect(asset('assets/services/wash-and-iron-3d.png'), findsOneWidget);
    expect(find.text('Fresh clothes, back at your door.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('it scrolls instead of overflowing on a small phone at 200% text', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(themed(const WelcomeScreen(), textScale: 2));
    expect(tester.takeException(), isNull);
    expect(find.text('Get started'), findsOneWidget, reason: 'the button stays pinned below the scrolling content');
  });
}
