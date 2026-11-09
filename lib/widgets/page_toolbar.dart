import 'package:quanclash/common/common.dart';
import 'package:quanclash/views/dashboard/widgets/dashboard_style.dart';
import 'package:flutter/material.dart';

/// 页面顶部工具栏：搜索框 + 操作按钮，紧贴页面顶端。
class PageSearchToolbar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<Widget> actions;

  const PageSearchToolbar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    this.actions = const [],
  });

  @override
  State<PageSearchToolbar> createState() => _PageSearchToolbarState();
}

class _PageSearchToolbarState extends State<PageSearchToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant PageSearchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query &&
        widget.query != _searchController.text) {
      _searchController.text = widget.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleClear() {
    _searchController.clear();
    widget.onQueryChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ...widget.actions,
            if (widget.actions.isNotEmpty) const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  widget.onQueryChanged(value);
                  setState(() {});
                },
                style: context.textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.appLocalizations.search,
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: quanX.textTertiary,
                  ),
                  prefixIcon: Icon(
                    QuanXIcons.search,
                    size: 18,
                    color: quanX.textTertiary,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42),
                  suffixIcon: IconButton(
                    onPressed: _searchController.text.isEmpty
                        ? null
                        : _handleClear,
                    icon: const Icon(QuanXIcons.x, size: 16),
                    color: quanX.textTertiary,
                    disabledColor: quanX.textTertiary.withValues(alpha: 0.25),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(minWidth: 42),
                  filled: true,
                  fillColor: quanX.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: DashboardPalette.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

