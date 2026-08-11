import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/widgets/candy_bounce.dart';

void main() {
  testWidgets('should scale down and restore on a normal press', (
    tester,
  ) async {
    var presses = 0;
    final robot = CandyBounceRobot(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CandyBounce(
            onPressed: () => presses++,
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    robot.expectScale(1);
    await robot.pressDown();
    robot.expectScale(0.96);
    await robot.release();
    robot.expectScale(1);
    expect(presses, 1);
  });

  testWidgets('should skip press motion when animations are disabled', (
    tester,
  ) async {
    var presses = 0;
    final robot = CandyBounceRobot(tester);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: CandyBounce(
            onPressed: () => presses++,
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    await robot.pressDown();
    robot.expectScale(1);
    await robot.release();
    robot.expectScale(1);
    expect(presses, 1);
  });

  testWidgets('should expose an accessible tap action when enabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final robot = CandyBounceRobot(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CandyBounce(
            onPressed: _noop,
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    robot.expectTapAction();
    semantics.dispose();
  });
}

void _noop() {}

final class CandyBounceRobot {
  CandyBounceRobot(this.tester);

  final WidgetTester tester;
  TestGesture? _gesture;

  Finder get _bounce => find.byType(CandyBounce);

  Future<void> pressDown() async {
    _gesture = await tester.startGesture(tester.getCenter(_bounce));
    await tester.pump();
  }

  Future<void> release() async {
    await _gesture?.up();
    _gesture = null;
    await tester.pump();
  }

  void expectScale(double scale) {
    final animatedScale = tester.widget<AnimatedScale>(
      find.descendant(of: _bounce, matching: find.byType(AnimatedScale)),
    );
    expect(animatedScale.scale, scale);
  }

  void expectTapAction() {
    final semantics = tester.getSemantics(_bounce);
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  }
}
