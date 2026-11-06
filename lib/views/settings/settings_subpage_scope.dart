import 'package:flutter/material.dart';

/// 让旧的 `ListItem.open` / `CommonPopScope` 内容可以在设置卡片内部翻页。
///
/// 旧页面本应通过 Navigator.pop 关闭，但嵌入居中卡片后没有对应的路由；
/// 这个 InheritedWidget 提供 `pop`，由设置页的返回栈承接。
class SettingsSubpageScope extends InheritedWidget {
  final VoidCallback pop;

  const SettingsSubpageScope({
    super.key,
    required this.pop,
    required super.child,
  });

  static SettingsSubpageScope? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SettingsSubpageScope>();
  }

  @override
  bool updateShouldNotify(SettingsSubpageScope oldWidget) =>
      pop != oldWidget.pop;
}
