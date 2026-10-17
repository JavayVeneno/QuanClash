import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试:窗口标题栏不能吞掉下方内容的点击。
///
/// 曾经的结构是 `Material > Align > Container(height: kHeaderHeight)`。
/// `Align` 在 `Stack` 的松散约束下会撑满整个窗口,导致其中的 Material
/// (PhysicalModel)一并覆盖全屏,吞掉标题栏以外的所有指针事件 ——
/// 表现就是「鼠标点不动,只有 Tab 能切换焦点」。
void main() {
  testWidgets('window header must not swallow taps below it', (tester) async {
    const headerHeight = 34.0;
    var backgroundTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => backgroundTaps++,
                child: const ColoredBox(color: Colors.white),
              ),
            ),
            // 与 WindowHeader 现行结构一致:SizedBox 限定高度。
            SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: Material(
                color: const Color(0xFFFFFFFF),
                child: const DecoratedBox(
                  decoration: BoxDecoration(),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // 标题栏内:应命中标题栏(不落到背景)
    await tester.tapAt(const Offset(200, 10));
    await tester.pump();
    expect(backgroundTaps, 0, reason: '标题栏范围内的点击不应穿透到背景');

    // 标题栏以外:必须能命中下方内容
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();
    expect(backgroundTaps, 1, reason: '标题栏范围外的点击必须能到下方内容');
  });
}
