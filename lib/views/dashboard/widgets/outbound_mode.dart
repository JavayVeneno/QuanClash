import 'dart:math';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'dashboard_style.dart';

class OutboundMode extends StatelessWidget {
  const OutboundMode({super.key});

  void _handleChangeMode(Mode mode) {
    globalState.container.read(setupActionProvider.notifier).changeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final height = getWidgetHeight(2);
    return SizedBox(
      height: height,
      child: Consumer(
        builder: (_, ref, _) {
          final mode = ref.watch(
            patchClashConfigProvider.select((state) => state.mode),
          );
          return Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: CommonCard(
              onPressed: () {},
              info: Info(
                label: appLocalizations.outboundMode,
                iconData: QuanXIcons.split,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: RadioGroup<Mode>(
                  groupValue: mode,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    _handleChangeMode(value);
                  },
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final maxHeight = constraints.maxHeight;
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          for (final item in Mode.values)
                            ListItem.radio(
                              horizontalTitleGap: 8,
                              tileTitleAlignment: ListTileTitleAlignment.center,
                              minTileHeight: min(
                                maxHeight / 3,
                                globalState.measure.bodyMediumHeight + 16,
                              ),
                              minVerticalPadding: 0,
                              padding: EdgeInsets.only(
                                left: 12.ap,
                                right: 16.ap,
                              ),
                              delegate: RadioDelegate(
                                onTab: () {
                                  _handleChangeMode(item);
                                },
                                value: item,
                              ),
                              title: Text(
                                Intl.message(item.name),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.toSoftBold,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OutboundModeV2 extends StatelessWidget {
  const OutboundModeV2({super.key});

  void _handleChangeMode(Mode mode) {
    globalState.container.read(setupActionProvider.notifier).changeMode(mode);
  }

  Color _getTextColor() => DashboardPalette.primary;

  @override
  Widget build(BuildContext context) {
    final height = getWidgetHeight(1) + 16.ap;
    return SizedBox(
      height: height,
      child: DashboardCard(
        padding: EdgeInsets.zero,
        child: Consumer(
          builder: (_, ref, _) {
            final mode = ref.watch(
              patchClashConfigProvider.select((state) => state.mode),
            );
            final thumbColor = DashboardPalette.surface(context);
            return LayoutBuilder(
              builder: (_, constraints) {
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints.expand(),
                        child: CommonTabBar<Mode>(
                          children: Map.fromEntries(
                            Mode.values.map(
                              (item) => MapEntry(
                                item,
                                Container(
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(),
                                  height: height - 8.ap - 26,
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    Intl.message(item.name),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.adjustSize(1)
                                        .copyWith(
                                          color: item == mode
                                              ? _getTextColor()
                                              : null,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          groupValue: mode,
                          onValueChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            _handleChangeMode(value);
                          },
                          thumbColor: thumbColor,
                          backgroundColor:
                              Theme.brightnessOf(context) == Brightness.dark
                              ? const Color(0xFF2A2A30)
                              : const Color(0xFFF2F2F7),
                        ),
                      ),
                    ),
                    Container(
                      color: DashboardPalette.primary.withValues(alpha: 0.15),
                      height: 8.ap,
                      width: constraints.maxWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      // child: Row(
                      //   children: [
                      //     Container(
                      //       width: (constraints.maxWidth - 32) / 3,
                      //       height: 3,
                      //       decoration: BoxDecoration(
                      //         color: _getTextColor(context, mode),
                      //         borderRadius: BorderRadius.circular(2),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
