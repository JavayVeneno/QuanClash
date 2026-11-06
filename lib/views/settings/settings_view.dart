import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/access.dart';
import 'package:fl_clash/views/config/advanced.dart';
import 'package:fl_clash/views/config/config.dart';
import 'package:fl_clash/views/resources.dart';
import 'package:fl_clash/views/settings/settings_modals.dart';
import 'package:fl_clash/views/settings/settings_style.dart';
import 'package:fl_clash/views/settings/settings_subpages.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show dirname, join;

typedef SettingsSubpageOpener =
    void Function(String title, String? subtitle, Widget child);

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Widget? _subpage;
  String _subpageTitle = '';
  String? _subpageSubtitle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSubpage(String title, String? subtitle, Widget child) {
    setState(() {
      _subpageTitle = title;
      _subpageSubtitle = subtitle;
      _subpage = child;
    });
  }

  void _closeSubpage() {
    setState(() {
      _subpage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    return CommonScaffold(
      hideAppBar: true,
      title: l10n.settings,
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SettingsPalette.pageGradientTop(context),
              SettingsPalette.pageBackground(context),
            ],
            stops: const [0, 0.45],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = min(
              680.0,
              max(0.0, constraints.maxHeight - 120),
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsPageHeader(
                        eyebrow: 'QuanClash / Preferences',
                        title: l10n.settings,
                        subtitle: l10n.settingsDesc,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: cardHeight,
                        child: _buildCard(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = SettingsPalette.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: SettingsPalette.surface(context),
        borderRadius: BorderRadius.circular(SettingsPalette.radiusCard),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.045),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _subpage == null
            ? KeyedSubtree(
                key: const ValueKey('settings-main'),
                child: _buildMain(context),
              )
            : KeyedSubtree(
                key: const ValueKey('settings-sub'),
                child: _buildSubpage(context),
              ),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    final l10n = context.appLocalizations;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SettingsPalette.isDark(context)
                  ? const Color(0xFF26262E)
                  : const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: SettingsPalette.soft(context),
                borderRadius: BorderRadius.circular(9),
              ),
              indicatorPadding: EdgeInsets.zero,
              labelColor: SettingsPalette.primary,
              unselectedLabelColor: SettingsPalette.text3(context),
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              labelPadding: EdgeInsets.zero,
              tabs: [
                Tab(height: 34, child: Text(l10n.settingsGeneral)),
                Tab(height: 34, child: Text(l10n.network)),
                Tab(height: 34, child: Text(l10n.core)),
                Tab(height: 34, child: Text(l10n.about)),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GeneralSettingsTab(onOpenSubpage: _openSubpage),
              const _NetworkSettingsTab(),
              const _CoreSettingsTab(),
              const _AboutSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubpage(BuildContext context) {
    return Column(
      children: [
        SettingsSubpageHeader(
          title: _subpageTitle,
          subtitle: _subpageSubtitle,
          onBack: _closeSubpage,
        ),
        Expanded(child: _subpage!),
      ],
    );
  }
}

class _GeneralSettingsTab extends ConsumerWidget {
  final SettingsSubpageOpener onOpenSubpage;

  const _GeneralSettingsTab({required this.onOpenSubpage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final locale = ref.watch(appSettingProvider.select((state) => state.locale));
    final setting = ref.watch(appSettingProvider);
    final themeLabel = switch (themeMode) {
      ThemeMode.system => l10n.auto,
      ThemeMode.light => l10n.light,
      ThemeMode.dark => l10n.dark,
    };
    final languageLabel = locale == null
        ? l10n.defaultText
        : Intl.message(locale);
    void update(AppSettingProps Function(AppSettingProps) builder) {
      ref.read(appSettingProvider.notifier).update(builder);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.appearance),
        SettingsRow(
          icon: QuanXIcons.palette,
          title: l10n.theme,
          subtitle: l10n.themeDesc,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsValue(value: themeLabel),
              const SizedBox(width: 6),
              const SettingsChevron(),
            ],
          ),
          onTap: () => showThemeSettingsModal(context),
        ),
        SettingsRow(
          icon: QuanXIcons.languages,
          title: l10n.language,
          subtitle: l10n.language,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsValue(value: languageLabel),
              const SizedBox(width: 6),
              const SettingsChevron(),
            ],
          ),
          onTap: () => showLanguageSettingsModal(context),
        ),
        SettingsSectionLabel(label: l10n.application),
        SettingsRow(
          icon: QuanXIcons.slidersHorizontal,
          title: l10n.application,
          subtitle: l10n.applicationDesc,
          trailing: const SettingsChevron(),
          onTap: () => onOpenSubpage(
            l10n.application,
            l10n.applicationDesc,
            const ApplicationSettingsPage(),
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.cloudSync,
          title: l10n.backupAndRestore,
          subtitle: l10n.backupAndRestoreDesc,
          trailing: const SettingsChevron(),
          onTap: () => onOpenSubpage(
            l10n.backupAndRestore,
            l10n.backupAndRestoreDesc,
            const BackupSettingsPage(),
          ),
        ),
        if (system.isDesktop)
          SettingsRow(
            icon: QuanXIcons.keyboard,
            title: l10n.hotkeyManagement,
            subtitle: l10n.hotkeyManagementDesc,
            trailing: const SettingsChevron(),
            onTap: () => onOpenSubpage(
              l10n.hotkeyManagement,
              l10n.hotkeyManagementDesc,
              const HotkeySettingsPage(),
            ),
          ),
        SettingsSectionLabel(label: l10n.startup),
        SettingsRow(
          icon: QuanXIcons.circlePlay,
          title: l10n.autoLaunch,
          subtitle: l10n.autoLaunchDesc,
          trailing: SettingsSwitch(
            value: setting.autoLaunch,
            onChanged: (value) {
              update((state) => state.copyWith(autoLaunch: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.cloudDownload,
          title: l10n.autoCheckUpdate,
          subtitle: l10n.autoCheckUpdateDesc,
          trailing: SettingsSwitch(
            value: setting.autoCheckUpdate,
            onChanged: (value) {
              update((state) => state.copyWith(autoCheckUpdate: value));
            },
          ),
        ),
      ],
    );
  }
}

class _NetworkSettingsTab extends ConsumerWidget {
  const _NetworkSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final patch = ref.watch(patchClashConfigProvider);
    final port = patch.mixedPort;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.network),
        SettingsRow(
          icon: QuanXIcons.shuffle,
          title: l10n.systemProxy,
          subtitle: '${l10n.port} $port',
          trailing: SettingsSwitch(
            value: systemProxy,
            onChanged: (value) {
              ref
                  .read(networkSettingProvider.notifier)
                  .update((state) => state.copyWith(systemProxy: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.cable,
          title: l10n.tun,
          subtitle: patch.tun.stack.name,
          trailing: SettingsSwitch(
            value: patch.tun.enable,
            onChanged: (value) {
              ref
                  .read(patchClashConfigProvider.notifier)
                  .update((state) => state.copyWith.tun(enable: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.arrowRightLeft,
          title: l10n.outboundMode,
          subtitle: l10n.mode,
          trailing: SettingsSelect<Mode>(
            value: patch.mode,
            options: [
              for (final mode in Mode.values)
                SettingsSelectOption(mode, Intl.message(mode.name)),
            ],
            onChanged: (value) {
              ref
                  .read(patchClashConfigProvider.notifier)
                  .update((state) => state.copyWith(mode: value));
            },
          ),
        ),
        SettingsSectionLabel(label: l10n.advanced),
        SettingsRow(
          icon: QuanXIcons.slidersHorizontal,
          title: l10n.basicConfig,
          subtitle: l10n.basicConfigDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            BaseNavigator.push(context, const ConfigView());
          },
        ),
        SettingsRow(
          icon: QuanXIcons.wrench,
          title: l10n.advancedConfig,
          subtitle: l10n.advancedConfigDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            BaseNavigator.push(context, const AdvancedConfigView());
          },
        ),
        if (system.isWindows)
          SettingsRow(
            icon: QuanXIcons.lock,
            title: l10n.loopback,
            subtitle: l10n.loopbackDesc,
            trailing: const SettingsChevron(),
            onTap: () {
              windows?.runas(
                '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
                '',
              );
            },
          ),
        if (system.isAndroid)
          SettingsRow(
            icon: QuanXIcons.list,
            title: l10n.accessControl,
            subtitle: l10n.accessControlDesc,
            trailing: const SettingsChevron(),
            onTap: () {
              BaseNavigator.push(context, const AccessView());
            },
          ),
      ],
    );
  }
}

class _CoreSettingsTab extends ConsumerWidget {
  const _CoreSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final coreStatus = ref.watch(coreStatusProvider);
    final developerMode = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    final statusLabel = switch (coreStatus) {
      CoreStatus.connected => l10n.connected,
      CoreStatus.connecting => l10n.connecting,
      _ => l10n.disconnected,
    };
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.core),
        SettingsRow(
          icon: QuanXIcons.cpu,
          title: l10n.settingsCurrentCore,
          subtitle: statusLabel,
          trailing: SettingsValue(value: globalState.packageInfo.version),
        ),
        SettingsRow(
          icon: QuanXIcons.database,
          title: l10n.resources,
          subtitle: l10n.resourcesDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            BaseNavigator.push(context, const ResourcesView());
          },
        ),
        SettingsRow(
          icon: QuanXIcons.scrollText,
          title: l10n.settingsOpenLogs,
          subtitle: l10n.logsDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.logs);
          },
        ),
        SettingsSectionLabel(label: l10n.diagnostics),
        SettingsRow(
          icon: QuanXIcons.cpu,
          title: l10n.developerMode,
          subtitle: l10n.settingsDesc,
          trailing: SettingsSwitch(
            value: developerMode,
            onChanged: (value) {
              ref
                  .read(appSettingProvider.notifier)
                  .update((state) => state.copyWith(developerMode: value));
            },
          ),
        ),
      ],
    );
  }
}

class _AboutSettingsTab extends ConsumerWidget {
  const _AboutSettingsTab();

  Future<void> _checkUpdate(BuildContext context) async {
    final data = await globalState.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: context.appLocalizations.checkUpdate,
    );
    globalState.container
        .read(commonActionProvider.notifier)
        .checkUpdateResultHandle(data: data, isUser: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final version = globalState.packageInfo.version;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.version),
        SettingsRow(
          icon: QuanXIcons.info,
          title: appName,
          subtitle: version,
          trailing: SettingsGhostButton(
            label: l10n.checkUpdate,
            onPressed: () => _checkUpdate(context),
          ),
        ),
        SettingsSectionLabel(label: l10n.links),
        SettingsRow(
          icon: QuanXIcons.externalLink,
          title: l10n.project,
          subtitle: 'github.com/$repository',
          trailing: const SettingsChevron(),
          onTap: () {
            globalState.openUrl('https://github.com/$repository');
          },
        ),
        SettingsRow(
          icon: QuanXIcons.library,
          title: l10n.licenses,
          subtitle: l10n.settingsAboutApp,
          trailing: const SettingsChevron(),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: appName,
              applicationVersion: version,
            );
          },
        ),
        SettingsRow(
          icon: QuanXIcons.scale,
          title: l10n.disclaimer,
          subtitle: l10n.settingsAboutApp,
          trailing: const SettingsChevron(),
          onTap: () async {
            final accepted = await globalState.showDisclaimer();
            if (!accepted) {
              await ref
                  .read(systemActionProvider.notifier)
                  .handleExit();
            }
          },
        ),
      ],
    );
  }
}
