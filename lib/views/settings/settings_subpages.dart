import 'dart:io';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/common/dav_client.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/backup_and_restore.dart';
import 'package:quanclash/views/hotkey.dart';
import 'package:quanclash/views/settings/settings_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 基本配置：应用行为与启动选项。
class ApplicationSettingsPage extends ConsumerWidget {
  const ApplicationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final setting = ref.watch(appSettingProvider);
    void update(AppSettingProps Function(AppSettingProps) builder) {
      ref.read(appSettingProvider.notifier).update(builder);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.behavior),
        SettingsRow(
          icon: QuanXIcons.circlePlay,
          title: l10n.minimizeOnExit,
          subtitle: l10n.minimizeOnExitDesc,
          trailing: SettingsSwitch(
            value: setting.minimizeOnExit,
            onChanged: (value) {
              update((state) => state.copyWith(minimizeOnExit: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.refreshCw,
          title: l10n.autoCloseConnections,
          subtitle: l10n.autoCloseConnectionsDesc,
          trailing: SettingsSwitch(
            value: setting.closeConnections,
            onChanged: (value) {
              update((state) => state.copyWith(closeConnections: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.shield,
          title: l10n.onlyStatisticsProxy,
          subtitle: l10n.onlyStatisticsProxyDesc,
          trailing: SettingsSwitch(
            value: setting.onlyStatisticsProxy,
            onChanged: (value) {
              update((state) => state.copyWith(onlyStatisticsProxy: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.activity,
          title: l10n.tabAnimation,
          subtitle: l10n.tabAnimationDesc,
          trailing: SettingsSwitch(
            value: setting.isAnimateToPage,
            onChanged: (value) {
              update((state) => state.copyWith(isAnimateToPage: value));
            },
          ),
        ),
        SettingsSectionLabel(label: l10n.startup),
        if (system.isDesktop) ...[
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
            icon: QuanXIcons.minimize2,
            title: l10n.silentLaunch,
            subtitle: l10n.silentLaunchDesc,
            trailing: SettingsSwitch(
              value: setting.silentLaunch,
              onChanged: (value) {
                update((state) => state.copyWith(silentLaunch: value));
              },
            ),
          ),
        ],
        SettingsRow(
          icon: QuanXIcons.play,
          title: l10n.autoRun,
          subtitle: l10n.autoRunDesc,
          trailing: SettingsSwitch(
            value: setting.autoRun,
            onChanged: (value) {
              update((state) => state.copyWith(autoRun: value));
            },
          ),
        ),
        SettingsSectionLabel(label: l10n.other),
        SettingsRow(
          icon: QuanXIcons.fileText,
          title: l10n.logcat,
          subtitle: l10n.logcatDesc,
          trailing: SettingsSwitch(
            value: setting.openLogs,
            onChanged: (value) {
              update((state) => state.copyWith(openLogs: value));
            },
          ),
        ),
        if (system.isAndroid)
          SettingsRow(
            icon: QuanXIcons.siren,
            title: l10n.crashlytics,
            subtitle: l10n.crashlyticsTip,
            trailing: SettingsSwitch(
              value: setting.crashlytics,
              onChanged: (value) {
                update((state) => state.copyWith(crashlytics: value));
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

/// 快捷键管理：点击行录制新的组合键。
class HotkeySettingsPage extends ConsumerWidget {
  const HotkeySettingsPage({super.key});

  String _subtitle(BuildContext context, HotKeyAction hotKeyAction) {
    final l10n = context.appLocalizations;
    final key = hotKeyAction.key;
    if (key == null) {
      return l10n.noHotKey;
    }
    final modifiers = hotKeyAction.modifiers
        .map((item) => item.physicalKeys.first.label)
        .join(' + ');
    final keyLabel = PhysicalKeyboardKey(key).label;
    return modifiers.isEmpty ? keyLabel : '$modifiers + $keyLabel';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.hotkeyManagement),
        for (final action in HotAction.values)
          Consumer(
            builder: (context, ref, _) {
              final hotKeyAction = ref.watch(
                getHotKeyActionProvider(action),
              );
              final hasKey = hotKeyAction.key != null;
              return SettingsRow(
                icon: QuanXIcons.keyboard,
                title: Intl.message('action_${action.name}'),
                subtitle: hasKey
                    ? _subtitle(context, hotKeyAction)
                    : l10n.noHotKey,
                onTap: () {
                  globalState.showCommonDialog(
                    child: HotKeyRecorder(hotKeyAction: hotKeyAction),
                  );
                },
                trailing: SettingsGhostButton(
                  label: l10n.edit,
                  icon: QuanXIcons.pencil,
                  onPressed: () {
                    globalState.showCommonDialog(
                      child: HotKeyRecorder(hotKeyAction: hotKeyAction),
                    );
                  },
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SettingsGhostButton(
              label: l10n.settingsResetHotkeys,
              icon: QuanXIcons.rotateCcw,
              onPressed: () {
                ref.read(hotKeyActionsProvider.notifier).value = [];
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 备份与恢复：本地文件、WebDAV 与恢复策略。
class BackupSettingsPage extends ConsumerStatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  ConsumerState<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends ConsumerState<BackupSettingsPage> {
  final _isCompleter = ValueNotifier<bool?>(null);
  DAVProps? _lastProps;
  DAVClient? _client;

  Future<void> _updateDAVClient(DAVProps? props) async {
    _client = props == null ? null : DAVClient(props);
    final rawProps = props?.copyWith(fileName: '');
    final rawLastProps = _lastProps?.copyWith(fileName: '');
    _lastProps = props;
    if (rawProps == rawLastProps) {
      return;
    }
    final res = await _client?.ping() ?? false;
    if (mounted) {
      _isCompleter.value = res;
    }
  }

  @override
  void dispose() {
    _isCompleter.dispose();
    super.dispose();
  }

  Future<void> _backupOnLocal() async {
    final l10n = context.appLocalizations;
    final res = await globalState.loadingRun<bool>(() async {
      final path = await ref.read(backupActionProvider.notifier).backup();
      if (path.isEmpty) {
        return false;
      }
      final value = await picker.saveFileWithPath(
        utils.getBackupFileName(),
        path,
      );
      return value != null;
    }, title: l10n.backup, tag: LoadingTag.backup_restore);
    if (res != true) return;
    globalState.showMessage(
      title: l10n.backup,
      message: TextSpan(text: l10n.backupSuccess),
    );
  }

  Future<void> _restoreOnLocal() async {
    final l10n = context.appLocalizations;
    final option = await globalState.showCommonDialog<RestoreOption>(
      child: const RestoreOptionsDialog(),
    );
    if (option == null || !mounted) return;
    final file = await picker.pickerFile();
    final path = file?.path;
    if (path == null) return;
    await File(path).safeCopy(await appPath.backupFilePath);
    final res = await globalState.loadingRun<bool>(() async {
      await ref.read(backupActionProvider.notifier).restore(option);
      return true;
    }, title: l10n.restore, tag: LoadingTag.backup_restore);
    if (res != true) return;
    globalState.showMessage(
      title: l10n.restore,
      message: TextSpan(text: l10n.restoreSuccess),
    );
  }

  Future<void> _backupOnWebDAV() async {
    final l10n = context.appLocalizations;
    if (_client == null) return;
    final res = await globalState.loadingRun<bool>(() async {
      final path = await ref.read(backupActionProvider.notifier).backup();
      if (path.isEmpty) {
        return false;
      }
      return _client!.backup(path);
    }, tag: LoadingTag.backup_restore, title: l10n.backup);
    if (res != true) return;
    globalState.showMessage(
      title: l10n.backup,
      message: TextSpan(text: l10n.backupSuccess),
    );
  }

  Future<void> _restoreOnWebDAV() async {
    final l10n = context.appLocalizations;
    if (_client == null) return;
    final option = await globalState.showCommonDialog<RestoreOption>(
      child: const RestoreOptionsDialog(),
    );
    if (option == null || !mounted) return;
    final res = await globalState.loadingRun<bool>(() async {
      await _client?.restore();
      await ref.read(backupActionProvider.notifier).restore(option);
      return true;
    }, tag: LoadingTag.backup_restore, title: l10n.restore);
    if (res != true) return;
    globalState.showMessage(
      title: l10n.restore,
      message: TextSpan(text: l10n.restoreSuccess),
    );
  }

  Future<void> _showDavForm(DAVProps? dav) async {
    await globalState.showCommonDialog<String>(
      child: WebDAVFormDialog(dav: dav?.copyWith()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final dav = ref.watch(davSettingProvider);
    final isLoading = ref.watch(loadingProvider(LoadingTag.backup_restore));
    final restoreStrategy = ref.watch(
      appSettingProvider.select((state) => state.restoreStrategy),
    );
    _updateDAVClient(dav);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.settingsBackupLocal),
        SettingsRow(
          icon: QuanXIcons.database,
          title: l10n.settingsBackupNow,
          subtitle: l10n.backupAndRestoreDesc,
          trailing: SettingsGhostButton(
            label: l10n.backup,
            icon: QuanXIcons.save,
            onPressed: isLoading ? null : _backupOnLocal,
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.fileText,
          title: l10n.settingsImportFile,
          subtitle: l10n.restoreStrategy,
          trailing: SettingsGhostButton(
            label: l10n.restore,
            icon: QuanXIcons.rotateCcw,
            onPressed: isLoading ? null : _restoreOnLocal,
          ),
        ),
        SettingsSectionLabel(label: l10n.settingsBackupRemote),
        SettingsRow(
          icon: QuanXIcons.cloudSync,
          title: dav?.user ?? l10n.settingsNoDav,
          subtitle: dav == null
              ? l10n.pleaseBindWebDAV
              : l10n.settingsBackupRemote,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dav != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ValueListenableBuilder<bool?>(
                    valueListenable: _isCompleter,
                    builder: (_, value, _) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: value == null
                              ? SettingsPalette.text4(context)
                              : value
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                        ),
                      );
                    },
                  ),
                ),
              SettingsGhostButton(
                label: dav == null ? l10n.settingsBindDav : l10n.settingsEditDav,
                onPressed: () => _showDavForm(dav),
              ),
            ],
          ),
        ),
        if (dav != null) ...[
          SettingsRow(
            icon: QuanXIcons.upload,
            title: l10n.settingsSyncDav,
            subtitle: l10n.backup,
            trailing: SettingsGhostButton(
              label: l10n.sync,
              icon: QuanXIcons.cloudSync,
              onPressed: isLoading ? null : _backupOnWebDAV,
            ),
          ),
          SettingsRow(
            icon: QuanXIcons.cloudDownload,
            title: l10n.settingsRestoreDav,
            subtitle: l10n.restore,
            trailing: SettingsGhostButton(
              label: l10n.restore,
              icon: QuanXIcons.rotateCcw,
              onPressed: isLoading ? null : _restoreOnWebDAV,
            ),
          ),
        ],
        SettingsSectionLabel(label: l10n.restoreStrategy),
        SettingsRow(
          icon: QuanXIcons.slidersHorizontal,
          title: l10n.restoreStrategy,
          subtitle: l10n.restoreStrategyDesc,
          trailing: SettingsSelect<RestoreStrategy>(
            value: restoreStrategy,
            options: [
              for (final strategy in RestoreStrategy.values)
                SettingsSelectOption(
                  strategy,
                  Intl.message('restoreStrategy_${strategy.name}'),
                ),
            ],
            onChanged: (value) {
              ref
                  .read(appSettingProvider.notifier)
                  .update((state) => state.copyWith(restoreStrategy: value));
            },
          ),
        ),
      ],
    );
  }
}
