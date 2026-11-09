import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/widgets/pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'chip.dart';
import 'inherited.dart';

typedef OnKeywordsUpdateCallback = void Function(List<String> keywords);

typedef AppBarSearchStateBuilder =
    AppBarSearchState? Function(AppBarSearchState? state);

class CommonScaffold extends StatefulWidget {
  final AppBar? appBar;
  final Widget body;
  final Color? backgroundColor;
  final String? title;
  final bool isLoading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Widget? floatingActionButton;
  final AppBarEditState? editState;
  final AppBarSearchState? searchState;
  final OnKeywordsUpdateCallback? onKeywordsUpdate;
  final bool? resizeToAvoidBottomInset;
  final bool hideTitle;

  /// 不渲染顶部 AppBar，由页面自己绘制工具栏。
  final bool hideAppBar;

  /// 标题栏左侧的操作按钮（桌面端标题被隐藏时，作为页面工具条使用）。
  final List<Widget>? leadingActions;

  /// 覆盖标题栏背景色，让页面底色（如浅灰）延伸到标题栏。
  final Color? appBarBackgroundColor;

  /// 是否绘制标题栏底部分隔线。
  final bool showAppBarDivider;

  const CommonScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.title,
    this.actions,
    this.centerTitle,
    this.editState,
    this.isLoading = false,
    this.searchState,
    this.floatingActionButton,
    this.onKeywordsUpdate,
    this.resizeToAvoidBottomInset,
    this.hideTitle = false,
    this.hideAppBar = false,
    this.leadingActions,
    this.appBarBackgroundColor,
    this.showAppBarDivider = true,
  });

  @override
  State<CommonScaffold> createState() => CommonScaffoldState();
}

class CommonScaffoldState extends State<CommonScaffold> {
  late final ValueNotifier<AppBarState> _appBarState;
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isFabExtendedNotifier = ValueNotifier(true);
  final ValueNotifier<List<String>> _keywordsNotifier = ValueNotifier([]);
  final _textController = TextEditingController();

  bool get _isSearch {
    return _appBarState.value.searchState?.query != null;
  }

  bool get _isEdit {
    final editState = _appBarState.value.editState;
    if (editState == null) {
      return false;
    }
    return editState.editCount > 0;
  }

  @override
  void initState() {
    super.initState();
    _appBarState = ValueNotifier(
      AppBarState(editState: widget.editState, searchState: widget.searchState),
    );
    _loadingNotifier.value = widget.isLoading;
  }

  Future<void> _updateSearchState(AppBarSearchStateBuilder builder) async {
    _appBarState.value = _appBarState.value.copyWith(
      searchState: builder(_appBarState.value.searchState),
    );
  }

  void handleToSearch() {
    _updateSearchState((state) => state?.copyWith(query: ''));
  }

  Widget _buildSearchingAppBarTheme(Widget child) {
    final ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: Colors.transparent,
          iconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
          titleTextStyle: theme.textTheme.titleLarge,
          toolbarTextStyle: theme.textTheme.bodyMedium,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: theme.inputDecorationTheme.hintStyle,
          border: InputBorder.none,
        ),
      ),
      child: child,
    );
  }

  @override
  void didUpdateWidget(CommonScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editState != widget.editState) {
      _appBarState.value = _appBarState.value.copyWith(
        editState: widget.editState,
      );
    }
    if (oldWidget.searchState != widget.searchState) {
      _appBarState.value = _appBarState.value.copyWith(
        searchState: widget.searchState,
      );
    }
    if (oldWidget.isLoading != widget.isLoading) {
      _loadingNotifier.value = widget.isLoading;
    }
  }

  void _handleClearInput() {
    _textController.text = '';
    if (_appBarState.value.searchState != null) {
      _appBarState.value.searchState!.onSearch('');
    }
  }

  void _handleClear() {
    if (_textController.text.isNotEmpty) {
      _handleClearInput();
      return;
    }
    _updateSearchState((state) => state?.copyWith(query: null));
  }

  void handleExitSearching() {
    if (!_isSearch) {
      return;
    }
    _handleClearInput();
    _updateSearchState((state) => state?.copyWith(query: null));
  }

  @override
  void dispose() {
    _appBarState.dispose();
    _textController.dispose();
    _isFabExtendedNotifier.dispose();
    _loadingNotifier.dispose();
    super.dispose();
  }

  void addKeyword(String keyword) {
    final isContains = _keywordsNotifier.value.contains(keyword);
    if (isContains) return;
    final keywords = List<String>.from(_keywordsNotifier.value)..add(keyword);
    _keywordsNotifier.value = keywords;
  }

  void _deleteKeyword(String keyword) {
    final isContains = _keywordsNotifier.value.contains(keyword);
    if (!isContains) return;
    final keywords = List<String>.from(_keywordsNotifier.value)
      ..remove(keyword);
    _keywordsNotifier.value = keywords;
  }

  Widget? _buildLeading(VoidCallback? backAction) {
    if (_isEdit) {
      return IconButton(
        onPressed: _appBarState.value.editState?.onExit,
        icon: const Icon(QuanXIcons.x),
      );
    }
    if (_isSearch) {
      return IconButton(
        onPressed: handleExitSearching,
        icon: const Icon(QuanXIcons.arrowLeft),
      );
    }
    return backAction != null
        ? BackButton(
            onPressed: () {
              if (!mounted) {
                return;
              }
              backAction();
            },
          )
        : null;
  }

  Widget _buildTitle(AppBarSearchState? startState) {
    final appLocalizations = context.appLocalizations;
    final hideTitle = widget.hideTitle && !_isSearch && !_isEdit && system.isDesktop;
    final title = _isSearch
        ? TextField(
            autofocus: true,
            controller: _textController,
            inputFormatters: TextInputLimits.limit(TextInputLimits.search),
            style: context.textTheme.titleLarge,
            onChanged: (value) {
              if (startState != null) {
                startState.onSearch(value);
              }
            },
            decoration: InputDecoration(hintText: appLocalizations.search),
          )
        : Text(
            !_isEdit
                ? widget.title!
                : appLocalizations.selectedCountTitle(
                    '${_appBarState.value.editState?.editCount ?? 0}',
                  ),
          );
    final leadingActions = widget.leadingActions;
    if (!_isSearch &&
        !_isEdit &&
        leadingActions != null &&
        leadingActions.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          ...leadingActions,
          if (!hideTitle) Expanded(child: title),
        ],
      );
    }
    if (hideTitle) {
      return const SizedBox.shrink();
    }
    return title;
  }

  List<Widget> _buildActions(bool hasSearch, List<Widget> actions) {
    if (_isSearch) {
      return genActions([
        IconButton(onPressed: _handleClear, icon: const Icon(QuanXIcons.x)),
      ]);
    }
    return genActions([
      if (hasSearch && widget.searchState?.autoAddSearch == true)
        IconButton(
          onPressed: () {
            _updateSearchState((state) => state?.copyWith(query: ''));
          },
          icon: const Icon(QuanXIcons.search),
        ),
      ...actions,
    ]);
  }

  Widget _buildAppBarWrap(Widget child) {
    final appBar = _isSearch ? _buildSearchingAppBarTheme(child) : child;
    if (_isEdit || _isSearch) {
      return SystemBackBlock(
        child: CommonPopScope(
          onPop: (context) {
            if (_isEdit || _isSearch) {
              handleExitSearching();
              _appBarState.value.editState?.onExit();
              return false;
            }
            return true;
          },
          child: appBar,
        ),
      );
    }
    return appBar;
  }

  PreferredSizeWidget _buildAppBar(VoidCallback? backAction) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          widget.appBar ??
              ValueListenableBuilder<AppBarState>(
                valueListenable: _appBarState,
                builder: (_, state, _) {
                  return _buildAppBarWrap(
                    AppBar(
                      automaticallyImplyLeading: backAction != null
                          ? false
                          : true,
                      animateColor: true,
                      backgroundColor: widget.appBarBackgroundColor,
                      centerTitle: widget.centerTitle ?? false,
                      leading: _buildLeading(backAction),
                      title: _buildTitle(state.searchState),
                      actions: _buildActions(
                        state.searchState != null,
                        state.actions.isNotEmpty
                            ? state.actions
                            : widget.actions ?? [],
                      ),
                    ),
                  );
                },
              ),
          ValueListenableBuilder(
            valueListenable: _loadingNotifier,
            builder: (_, value, _) {
              return value == true
                  ? const LinearProgressIndicator()
                  : Container();
            },
          ),
          if (widget.showAppBarDivider)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.quanX.separator,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.appBar != null || widget.title != null);
    final backActionProvider = CommonScaffoldBackActionProvider.of(context);
    final body = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder(
            valueListenable: _keywordsNotifier,
            builder: (_, keywords, _) {
              if (widget.onKeywordsUpdate != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onKeywordsUpdate!(keywords);
                });
              }
              if (keywords.isEmpty) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Wrap(
                  runSpacing: 8,
                  spacing: 8,
                  children: [
                    for (final keyword in keywords)
                      CommonChip(
                        label: keyword,
                        type: ChipType.delete,
                        onPressed: () {
                          _deleteKeyword(keyword);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : _buildAppBar(backActionProvider?.backAction),
      body: NotificationListener<UserScrollNotification>(
        child: body,
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            _isFabExtendedNotifier.value = false;
          } else if (notification.direction == ScrollDirection.forward) {
            _isFabExtendedNotifier.value = true;
          }
          return true;
        },
      ),
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      backgroundColor: widget.backgroundColor,
      floatingActionButton: widget.floatingActionButton != null
          ? ValueListenableBuilder<bool>(
              valueListenable: _isFabExtendedNotifier,
              builder: (_, isExtended, child) {
                return CommonScaffoldFabExtendedProvider(
                  isExtended: isExtended,
                  child: child!,
                );
              },
              child: widget.floatingActionButton,
            )
          : null,
    );
  }
}

List<Widget> genActions(List<Widget> actions, {double? space}) {
  return <Widget>[
    ...actions.separated(SizedBox(width: space ?? 4)),
    const SizedBox(width: 8),
  ];
}

class BaseScaffold extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;

  const BaseScaffold({
    super.key,
    required this.title,
    this.actions = const [],
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(body: body, title: title, actions: actions);
  }
}
