import 'package:flutter/widgets.dart';

/// 推入设置卡片内嵌子页。返回子页关闭时 `Navigator.pop` 带回的结果。
typedef SubpagePush =
    Future<Object?> Function(String title, String? subtitle, Widget child);

/// 子页把 `CommonScaffold.actions` 交给外层的设置卡片标题栏。
typedef SubpageActionsSetter = void Function(List<Widget> actions);

/// 让按“整页路由”编写的旧页面（`CommonScaffold`、`ListItem.open`、
/// `CommonPopScope`）可以运行在设置卡片的内嵌 Navigator 里。
///
/// - [push] 由设置卡片实现，压入下一层子页；
/// - [setActions] 由当前子页的标题栏实现，用于显示旧页面的操作按钮。
class SubpageScope extends InheritedWidget {
  final SubpagePush push;
  final SubpageActionsSetter setActions;

  const SubpageScope({
    super.key,
    required this.push,
    required this.setActions,
    required super.child,
  });

  static SubpageScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SubpageScope>();
  }

  @override
  bool updateShouldNotify(SubpageScope oldWidget) =>
      push != oldWidget.push || setActions != oldWidget.setActions;
}

/// 从 `ListItem` 的标题/副标题控件中取出纯文本，用作子页标题。
String? subpageTextOf(Widget? widget) {
  if (widget is Text) {
    return widget.data;
  }
  return null;
}
