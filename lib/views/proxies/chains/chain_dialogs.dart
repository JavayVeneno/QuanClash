import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quanclash/common/common.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/widgets/widgets.dart';

Future<void> showChainYamlDialog(BuildContext context, ProxyChain chain) {
  final l10n = context.appLocalizations;
  final quanX = context.quanX;
  final yamlText = generateChainYamlPreview(chain);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return QuanXDialog(
        icon: Icons.code_rounded,
        color: quanX.accent,
        title: l10n.proxyChainYamlPreview,
        subtitle: chain.groupName,
        maxWidth: 520,
        maxHeight: 460,
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: yamlText));
              globalState.showNotifier(l10n.copySuccess);
            },
            child: Text(l10n.copy),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.confirm),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: quanX.surfaceSunken,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: quanX.separator),
            ),
            child: SelectableText(
              yamlText,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: quanX.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<ChainFailurePolicy?> showChainFailurePolicyDialog(
  BuildContext context,
  ChainFailurePolicy current,
) {
  final l10n = context.appLocalizations;
  final quanX = context.quanX;
  var selected = current;
  var acknowledged = current == ChainFailurePolicy.directFallback;

  return showDialog<ChainFailurePolicy>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDirect = selected == ChainFailurePolicy.directFallback;
          final canConfirm = !isDirect || acknowledged;
          return QuanXDialog(
            icon: QuanXIcons.shield,
            color: isDirect ? quanX.danger : quanX.accent,
            title: l10n.proxyChainFailurePolicy,
            maxWidth: 440,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: isDirect
                    ? FilledButton.styleFrom(backgroundColor: quanX.danger)
                    : null,
                onPressed: canConfirm
                    ? () => Navigator.of(dialogContext).pop(selected)
                    : null,
                child: Text(l10n.confirm),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PolicyOptionTile(
                    selected: !isDirect,
                    title: l10n.proxyChainFailureBlock,
                    description: l10n.proxyChainFailureBlockDesc,
                    accentColor: quanX.accent,
                    onTap: () {
                      setState(() {
                        selected = ChainFailurePolicy.block;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _PolicyOptionTile(
                    selected: isDirect,
                    title: l10n.proxyChainFailureDirect,
                    description: l10n.proxyChainFailureDirectDesc,
                    accentColor: quanX.danger,
                    isDanger: true,
                    onTap: () {
                      setState(() {
                        selected = ChainFailurePolicy.directFallback;
                      });
                    },
                  ),
                  if (isDirect) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          acknowledged = !acknowledged;
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: acknowledged,
                            activeColor: quanX.danger,
                            onChanged: (value) {
                              setState(() {
                                acknowledged = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              l10n.proxyChainFailureDirectAck,
                              style: TextStyle(
                                fontSize: 12,
                                color: quanX.danger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _PolicyOptionTile extends StatelessWidget {
  const _PolicyOptionTile({
    required this.selected,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
    this.isDanger = false,
  });

  final bool selected;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: quanX.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accentColor : quanX.separator,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? accentColor : quanX.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? quanX.danger : quanX.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: quanX.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<(int, int)?> showChainUrlTestParamsDialog(
  BuildContext context,
  ChainHop hop,
) {
  final l10n = context.appLocalizations;
  final quanX = context.quanX;
  final tolCtrl = TextEditingController(text: hop.tolerance.toString());
  final intCtrl = TextEditingController(text: hop.interval.toString());

  return showDialog<(int, int)>(
    context: context,
    builder: (dialogContext) {
      return QuanXDialog(
        icon: QuanXIcons.slidersHorizontal,
        color: quanX.accent,
        title: l10n.proxyChainUrlTestParams,
        maxWidth: 380,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final tol = int.tryParse(tolCtrl.text.trim()) ?? hop.tolerance;
              final interval =
                  int.tryParse(intCtrl.text.trim()) ?? hop.interval;
              Navigator.of(dialogContext).pop((
                tol.clamp(0, 5000),
                interval.clamp(10, 86400),
              ));
            },
            child: Text(l10n.confirm),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tolCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.proxyChainTolerance,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: intCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.proxyChainInterval,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> showChainRenameDialog(
  BuildContext context,
  String currentName,
) {
  final l10n = context.appLocalizations;
  final quanX = context.quanX;
  final ctrl = TextEditingController(text: currentName);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return CommonDialog(
        title: l10n.proxyChainRename,
        backgroundColor: quanX.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final trimmed = ctrl.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(dialogContext).pop(trimmed);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(dialogContext).pop(trimmed);
              }
            },
          ),
        ),
      );
    },
  );
}

Future<String?> showChainUnsavedDialog(
  BuildContext context,
  String chainName,
) {
  final l10n = context.appLocalizations;
  final quanX = context.quanX;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return CommonDialog(
        title: l10n.proxyChainUnsavedTitle(chainName),
        backgroundColor: quanX.surface,
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: quanX.danger),
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: Text(l10n.proxyChainDiscard),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('apply'),
            child: Text(l10n.proxyChainApplyAndLeave),
          ),
        ],
        child: Text(l10n.proxyChainUnsavedDesc),
      );
    },
  );
}

Future<bool> showChainDeleteConfirmDialog(
  BuildContext context,
  String chainName,
  int ruleRefCount,
) async {
  final l10n = context.appLocalizations;
  final quanX = context.quanX;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return CommonDialog(
        title: l10n.proxyChainDeleteConfirm(chainName),
        backgroundColor: quanX.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: quanX.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
        child: ruleRefCount > 0
            ? Text(
                l10n.proxyChainRuleRefWarning(ruleRefCount),
                style: TextStyle(color: quanX.danger),
              )
            : null,
      );
    },
  );
  return result ?? false;
}
