import 'package:quanclash/common/window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1920x1080 @125% 缩放时的逻辑工作区。
  const workArea = Rect.fromLTWH(0, 0, 1536, 824);

  test('panel sits at the bottom-right corner of the work area', () {
    final bounds = panelBoundsFor(workArea, panelWindowSize);
    expect(bounds, const Rect.fromLTWH(1164, 382, 360, 430));
    expect(bounds.right, lessThanOrEqualTo(workArea.right));
    expect(bounds.bottom, lessThanOrEqualTo(workArea.bottom));
  });

  test('a window clamped to the old minimum size still fits', () {
    // 回归:主窗口最小尺寸 380x400 曾把 340x332 的面板撑大,底栏被推出
    // 工作区,「打开 QuanClash」点不到。按真实尺寸定位后必须仍然完整可见。
    final bounds = panelBoundsFor(workArea, const Size(380, 400));
    expect(bounds.right, workArea.right - 12);
    expect(bounds.bottom, workArea.bottom - 12);
    expect(bounds.right, lessThanOrEqualTo(workArea.right));
    expect(bounds.bottom, lessThanOrEqualTo(workArea.bottom));
  });

  test('secondary displays keep their offset', () {
    const display = Rect.fromLTWH(1920, 0, 1920, 1040);
    final bounds = panelBoundsFor(display, panelWindowSize);
    expect(bounds.topLeft, const Offset(3468, 598));
  });

  test(
    'a panel larger than the work area is pinned to the top-left margin',
    () {
      final bounds = panelBoundsFor(workArea, const Size(2000, 1200));
      expect(bounds.topLeft, const Offset(12, 12));
    },
  );
}
