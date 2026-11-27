import 'package:quanclash/common/proxy_chain.dart';
import 'package:quanclash/l10n/l10n.dart';

String formatChainIssue(AppLocalizations l10n, ChainIssue issue) {
  return switch (issue.code) {
    ChainIssueCode.emptyName => l10n.proxyChainErrEmptyName,
    ChainIssueCode.entryEmpty => l10n.proxyChainErrEntryEmpty,
    ChainIssueCode.exitEmpty => l10n.proxyChainErrExitEmpty,
    ChainIssueCode.builtinMember => l10n.proxyChainErrBuiltin(
      issue.nodeName ?? '',
    ),
    ChainIssueCode.nodeBothSides => l10n.proxyChainErrBothSides(
      issue.nodeName ?? '',
    ),
    ChainIssueCode.exitHasDialer => l10n.proxyChainErrExitDialer(
      issue.nodeName ?? '',
      issue.detail ?? '',
    ),
    ChainIssueCode.cycle => l10n.proxyChainErrCycle,
    ChainIssueCode.providerNodeStrict => l10n.proxyChainErrProviderStrict,
    ChainIssueCode.missingNode => l10n.proxyChainErrMissingNode(
      issue.nodeName ?? '',
    ),
    ChainIssueCode.nameConflict => l10n.proxyChainErrNameConflict(
      issue.nodeName ?? '',
    ),
    ChainIssueCode.invalidExitType => l10n.proxyChainErrInvalidExitType,
    ChainIssueCode.udpQuicMismatch => l10n.proxyChainWarnUdpQuic(
      issue.detail ?? '',
      issue.nodeName ?? '',
    ),
  };
}
