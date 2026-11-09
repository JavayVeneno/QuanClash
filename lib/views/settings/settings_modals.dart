import 'package:quanclash/common/common.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'settings_style.dart';

Future<void> showLanguageSettingsModal(BuildContext context) {
  final l10n = context.appLocalizations;
  return showSettingsModal(
    context,
    title: l10n.language,
    subtitle: l10n.language,
    width: 420,
    child: const _LanguageSettingsBody(),
  );
}

class _LanguageSettingsBody extends ConsumerWidget {
  const _LanguageSettingsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final current = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final locales = <Locale?>[
      null,
      ...AppLocalizations.delegate.supportedLocales,
    ];
    return Column(
      children: [
        for (final locale in locales)
          SettingsOptionRow(
            icon: QuanXIcons.globe,
            title: locale == null
                ? l10n.defaultText
                : Intl.message(locale.toString()),
            subtitle: locale == null ? l10n.auto : locale.toLanguageTag(),
            selected: current == locale?.toString(),
            onTap: () {
              ref
                  .read(appSettingProvider.notifier)
                  .update(
                    (state) => state.copyWith(locale: locale?.toString()),
                  );
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}

Future<void> showThemeSettingsModal(BuildContext context) {
  final l10n = context.appLocalizations;
  return showSettingsModal(
    context,
    title: l10n.theme,
    subtitle: l10n.settingsDesc,
    width: 460,
    child: const _ThemeSettingsBody(),
  );
}

class _ThemeSettingsBody extends ConsumerWidget {
  const _ThemeSettingsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final themeProps = ref.watch(themeSettingProvider);
    final textScale = themeProps.textScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModalLabel(label: l10n.themeMode),
        const SizedBox(height: 8),
        _ThemeModeSegmented(
          value: themeProps.themeMode,
          onChanged: (mode) {
            ref
                .read(themeSettingProvider.notifier)
                .update((state) => state.copyWith(themeMode: mode));
          },
        ),
        const SizedBox(height: 18),
        _ModalLabel(label: l10n.colorSchemes),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in themeProps.primaryColors)
              _ColorSwatch(
                color: Color(color),
                selected: themeProps.primaryColor == color,
                onTap: () {
                  ref
                      .read(themeSettingProvider.notifier)
                      .update((state) => state.copyWith(primaryColor: color));
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        _ModalSwitchRow(
          title: l10n.pureBlackMode,
          
          value: themeProps.pureBlack,
          onChanged: (value) {
            ref
                .read(themeSettingProvider.notifier)
                .update((state) => state.copyWith(pureBlack: value));
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _ModalLabel(label: l10n.settingsTextScale)),
            Text(
              '${(textScale.scale * 100).round()}%',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SettingsPalette.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SettingsSlider(
          value: textScale.scale,
          onChanged: (value) {
            ref
                .read(themeSettingProvider.notifier)
                .update(
                  (state) => state.copyWith(
                    textScale: TextScale(enable: true, scale: value),
                  ),
                );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '小',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  color: SettingsPalette.textQuaternary,
                ),
              ),
              Text(
                '大',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  color: SettingsPalette.textQuaternary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeSegmented extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSegmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final items = [
      (ThemeMode.system, l10n.auto),
      (ThemeMode.light, l10n.light),
      (ThemeMode.dark, l10n.dark),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SettingsPalette.isDark(context)
            ? const Color(0xFF26262E)
            : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final (mode, label) in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == mode
                        ? SettingsPalette.soft(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: value == mode
                          ? SettingsPalette.primary
                          : SettingsPalette.text3(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: SettingsPalette.surface(context),
                  width: 2,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: SettingsPalette.primary.withValues(alpha: 0.5),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(QuanXIcons.check, size: 13, color: Colors.white)
            : null,
      ),
    );
  }
}

class _ModalLabel extends StatelessWidget {
  final String label;

  const _ModalLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: SettingsPalette.text2(context),
      ),
    );
  }
}

class _ModalSwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ModalSwitchRow({
    required this.title,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: SettingsPalette.text1(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SettingsSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
