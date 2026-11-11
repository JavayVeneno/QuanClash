// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ja';

  static String m0(count) => "${count}日前";

  static String m1(label) => "選択された${label}を削除してもよろしいですか？";

  static String m2(label) => "現在の${label}を削除してもよろしいですか？";

  static String m3(label) => "${label}詳細";

  static String m4(time) => "読み取り時刻：${time}";

  static String m5(target) => "設定された接続先：${target}";

  static String m6(codes) => "DNS 安全チェックに失敗しました：${codes}";

  static String m7(label) => "${label}は空欄にできません";

  static String m8(count) => "${count} エントリ";

  static String m9(label) => "現在の${label}は既に存在しています";

  static String m10(name) => "${name} スキップ済み";

  static String m11(name) => "${name} 更新済み";

  static String m12(name) => "${name}を更新中...";

  static String m13(count) => "${count}時間前";

  static String m14(count) => "${count} 時間";

  static String m15(target) => "${target} は無効なポリシーです";

  static String m16(proxyName) => "${proxyName} は無効なプロキシです";

  static String m17(providerName) => "${providerName} は無効なプロキシプロバイダーです";

  static String m18(subRule) => "${subRule} は無効なSUB_RULEです";

  static String m19(appName) =>
      "1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check ${appName} in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.";

  static String m20(count) => "${count}分前";

  static String m21(count) => "${count}ヶ月前";

  static String m22(seconds) => "先ほど検査しました。${seconds} 秒後に再試行できます。";

  static String m23(time) => "検査時刻：${time}";

  static String m24(label) => "まだ${label}はありません";

  static String m25(label) => "${label}は数字でなければなりません";

  static String m26(label) => "${label} は 1024 から 49151 の間でなければなりません";

  static String m27(days) => "${days} 日";

  static String m28(days) => "残り ${days} 日";

  static String m29(days) => "残り ${days} 日";

  static String m30(hours) => "${hours} 時間ごと";

  static String m31(minutes) => "${minutes} 分ごと";

  static String m32(count) => "${count} ノード";

  static String m33(percent) => "使用済み ${percent}%";

  static String m34(count) => "${count} 秒";

  static String m35(count) => "${count} 項目が選択されています";

  static String m36(label) => "${label}はURLである必要があります";

  static String m37(count) => "${count}年前";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("について"),
    "accessControl": MessageLookupByLibrary.simpleMessage("アクセス制御"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリのみVPNを許可",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "アプリケーションのプロキシアクセスを設定",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリをVPNから除外",
    ),
    "accessControlSettings": MessageLookupByLibrary.simpleMessage("アクセス制御設定"),
    "account": MessageLookupByLibrary.simpleMessage("アカウント"),
    "action": MessageLookupByLibrary.simpleMessage("アクション"),
    "action_mode": MessageLookupByLibrary.simpleMessage("モード切替"),
    "action_proxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "action_start": MessageLookupByLibrary.simpleMessage("開始/停止"),
    "action_tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "action_view": MessageLookupByLibrary.simpleMessage("表示/非表示"),
    "add": MessageLookupByLibrary.simpleMessage("追加"),
    "addProfile": MessageLookupByLibrary.simpleMessage("プロファイルを追加"),
    "addProxies": MessageLookupByLibrary.simpleMessage("プロキシを追加"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを追加"),
    "addProxyProviders": MessageLookupByLibrary.simpleMessage("プロキシプロバイダーを追加"),
    "addRule": MessageLookupByLibrary.simpleMessage("ルールを追加"),
    "addSsid": MessageLookupByLibrary.simpleMessage("SSIDを追加"),
    "addedRules": MessageLookupByLibrary.simpleMessage("追加ルール"),
    "additionalParameters": MessageLookupByLibrary.simpleMessage("追加パラメータ"),
    "address": MessageLookupByLibrary.simpleMessage("アドレス"),
    "addressHelp": MessageLookupByLibrary.simpleMessage("WebDAVサーバーアドレス"),
    "addressTip": MessageLookupByLibrary.simpleMessage("有効なWebDAVアドレスを入力"),
    "advanced": MessageLookupByLibrary.simpleMessage("詳細"),
    "advancedConfig": MessageLookupByLibrary.simpleMessage("高度な設定"),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage("多様な設定を提供"),
    "agree": MessageLookupByLibrary.simpleMessage("同意"),
    "allowBypass": MessageLookupByLibrary.simpleMessage("アプリがVPNをバイパスすることを許可"),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "有効化すると一部アプリがVPNをバイパス",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("LANを許可"),
    "allowLanDesc": MessageLookupByLibrary.simpleMessage("LAN経由でのプロキシアクセスを許可"),
    "app": MessageLookupByLibrary.simpleMessage("アプリ"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage("アプリアクセス制御"),
    "appearance": MessageLookupByLibrary.simpleMessage("外観"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage("システムDNSを追加"),
    "appendSystemDnsTip": MessageLookupByLibrary.simpleMessage(
      "設定にシステムDNSを強制的に追加します",
    ),
    "application": MessageLookupByLibrary.simpleMessage("アプリケーション"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage("アプリ関連設定を変更"),
    "authorized": MessageLookupByLibrary.simpleMessage("許可済み"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage("自動更新チェック"),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "起動時に更新を自動チェック",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage("接続を自動閉じる"),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "ノード変更後に接続を自動閉じる",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("自動起動"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage("システムの自動起動に従う"),
    "autoRun": MessageLookupByLibrary.simpleMessage("自動実行"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage("アプリ起動時に自動実行"),
    "autoScroll": MessageLookupByLibrary.simpleMessage("自動スクロール"),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage("オートセットシステムDNS"),
    "autoSetSystemDnsDesc": MessageLookupByLibrary.simpleMessage(
      "DNS クエリを現在のノードに固定し、ローカル ISP への漏洩を防ぎます。静的に検証できない場合は互換モードに戻ります。",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔（分）"),
    "backup": MessageLookupByLibrary.simpleMessage("バックアップ"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("バックアップと復元"),
    "backupAndRestoreDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAVまたはファイルを介してデータを同期する",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("バックアップ成功"),
    "basicConfig": MessageLookupByLibrary.simpleMessage("基本設定"),
    "basicConfigDesc": MessageLookupByLibrary.simpleMessage("基本設定をグローバルに変更"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("基本情報"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("基本戦略"),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "To ensure background operation, please disable battery optimization for this app. Tap to go to settings.",
    ),
    "batteryOptimizationStatusTip": MessageLookupByLibrary.simpleMessage(
      "システムの影響により、この状態は必ずしも正確とは限りません。",
    ),
    "behavior": MessageLookupByLibrary.simpleMessage("動作"),
    "bind": MessageLookupByLibrary.simpleMessage("バインド"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("ブラックリストモード"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("バイパスドメイン"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage("システムプロキシ有効時のみ適用"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "キャッシュが破損しています。クリアしますか？",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("全選択解除"),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("更新を確認"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage("アプリは最新版です"),
    "clearData": MessageLookupByLibrary.simpleMessage("データを消去"),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("クリップボードにエクスポート"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("クリップボードからインポート"),
    "closeAllConnections": MessageLookupByLibrary.simpleMessage("すべての接続を閉じる"),
    "color": MessageLookupByLibrary.simpleMessage("カラー"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("カラースキーム"),
    "columns": MessageLookupByLibrary.simpleMessage("列"),
    "compatible": MessageLookupByLibrary.simpleMessage("互換モード"),
    "configDataDetected": MessageLookupByLibrary.simpleMessage(
      "設定内にデータが検出されました",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "すべてのデータをクリアしてもよろしいですか？",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループを削除してもよろしいですか？",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "現在のウィンドウを閉じてもよろしいですか？",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "コアを強制的にクラッシュさせてもよろしいですか？",
    ),
    "confirmOverwriteTip": MessageLookupByLibrary.simpleMessage(
      "確認後、既存のデータは上書きされます",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("接続済み"),
    "connecting": MessageLookupByLibrary.simpleMessage("接続中..."),
    "connection": MessageLookupByLibrary.simpleMessage("接続"),
    "connections": MessageLookupByLibrary.simpleMessage("接続"),
    "connectionsDesc": MessageLookupByLibrary.simpleMessage("現在の接続データを表示"),
    "connectivity": MessageLookupByLibrary.simpleMessage("接続性："),
    "content": MessageLookupByLibrary.simpleMessage("内容"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage("内容は空にできません"),
    "contentScheme": MessageLookupByLibrary.simpleMessage("コンテンツテーマ"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "グローバル追加ルールを制御",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("コピー"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage("環境変数をコピー"),
    "copyInfo": MessageLookupByLibrary.simpleMessage("情報をコピー"),
    "copyLink": MessageLookupByLibrary.simpleMessage("リンクをコピー"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("コピー成功"),
    "core": MessageLookupByLibrary.simpleMessage("コア"),
    "coreStatus": MessageLookupByLibrary.simpleMessage("コアステータス"),
    "country": MessageLookupByLibrary.simpleMessage("国"),
    "crashTest": MessageLookupByLibrary.simpleMessage("クラッシュテスト"),
    "crashlytics": MessageLookupByLibrary.simpleMessage("クラッシュ分析"),
    "crashlyticsTip": MessageLookupByLibrary.simpleMessage(
      "有効にすると、アプリがクラッシュした際に機密情報を含まないクラッシュログを自動的にアップロードします",
    ),
    "create": MessageLookupByLibrary.simpleMessage("作成"),
    "createProfile": MessageLookupByLibrary.simpleMessage("Create Profile"),
    "creationTime": MessageLookupByLibrary.simpleMessage("作成時間"),
    "custom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "cut": MessageLookupByLibrary.simpleMessage("切り取り"),
    "dark": MessageLookupByLibrary.simpleMessage("ダーク"),
    "dashboard": MessageLookupByLibrary.simpleMessage("ダッシュボード"),
    "dashboardAvailableNodes": MessageLookupByLibrary.simpleMessage("利用可能なノード"),
    "dashboardCoverage": MessageLookupByLibrary.simpleMessage("カバレッジ"),
    "dashboardNodeUpdate": MessageLookupByLibrary.simpleMessage("ノード更新"),
    "dashboardUptime": MessageLookupByLibrary.simpleMessage("稼働時間"),
    "data": MessageLookupByLibrary.simpleMessage("データ"),
    "dataChangedSave": MessageLookupByLibrary.simpleMessage(
      "データの変更が検出されました。保存しますか？",
    ),
    "dataCollectionContent": MessageLookupByLibrary.simpleMessage(
      "本アプリはFirebase Crashlyticsを使用してクラッシュ情報を収集し、アプリの安定性を向上させます。\n収集されるデータにはデバイス情報とクラッシュ詳細が含まれますが、個人の機密データは含まれません。\n設定でこの機能を無効にすることができます。",
    ),
    "dataCollectionTip": MessageLookupByLibrary.simpleMessage("データ収集説明"),
    "daysAgo": m0,
    "defaultNameserver": MessageLookupByLibrary.simpleMessage("デフォルトネームサーバー"),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "DNSサーバーの解決用",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("デフォルト"),
    "delay": MessageLookupByLibrary.simpleMessage("遅延"),
    "delayTest": MessageLookupByLibrary.simpleMessage("遅延テスト"),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "deleteMultipTip": m1,
    "deleteTip": m2,
    "desc": MessageLookupByLibrary.simpleMessage(
      "ClashMetaベースのマルチプラットフォームプロキシクライアント。シンプルで使いやすく、オープンソースで広告なし。",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("宛先"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage("宛先地理情報"),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("宛先IP ASN"),
    "details": m3,
    "detectionTip": MessageLookupByLibrary.simpleMessage("サードパーティAPIに依存（参考値）"),
    "developerMode": MessageLookupByLibrary.simpleMessage("デベロッパーモード"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "デベロッパーモードが有効になりました。",
    ),
    "diagnostics": MessageLookupByLibrary.simpleMessage("診断"),
    "direct": MessageLookupByLibrary.simpleMessage("ダイレクト"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("UDPを無効化"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("免責事項"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは学習交流や科学研究などの非営利目的でのみ使用されます。商用利用は厳禁です。いかなる商用活動も本ソフトウェアとは無関係です。",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("切断済み"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage("新バージョンを発見"),
    "dnsAutoLeakProtectionActive": MessageLookupByLibrary.simpleMessage(
      "自動漏洩防止が有効です。DNS クエリは現在のノードに固定されます。",
    ),
    "dnsDesc": MessageLookupByLibrary.simpleMessage("DNS関連設定の更新"),
    "dnsDiagnosticBootstrap": MessageLookupByLibrary.simpleMessage(
      "ブートストラップ：リゾルバー / プロキシのホスト名",
    ),
    "dnsDiagnosticDedicated": MessageLookupByLibrary.simpleMessage("専用リゾルバー"),
    "dnsDiagnosticDescription": MessageLookupByLibrary.simpleMessage(
      "コアの現在の設定を参照します。DNS プローブは送信しません",
    ),
    "dnsDiagnosticDirect": MessageLookupByLibrary.simpleMessage("直接通信の問い合わせ"),
    "dnsDiagnosticDisabled": MessageLookupByLibrary.simpleMessage(
      "コアの DNS は無効です",
    ),
    "dnsDiagnosticInactive": MessageLookupByLibrary.simpleMessage(
      "コアの準備ができていません",
    ),
    "dnsDiagnosticInactiveHint": MessageLookupByLibrary.simpleMessage(
      "DNS 設定を読む前にコアを接続し、初期化してください。",
    ),
    "dnsDiagnosticInheritance": MessageLookupByLibrary.simpleMessage(
      "リゾルバーの継承",
    ),
    "dnsDiagnosticInheritsMain": MessageLookupByLibrary.simpleMessage(
      "通常リゾルバーを継承",
    ),
    "dnsDiagnosticLimitations": MessageLookupByLibrary.simpleMessage(
      "未適用の設定ではなく、コアで有効な設定を表示します。経路は設定値であり、パケットの実測ではありません。グループは DIRECT を選択する場合があります。アプリ独自の DoH/DoT や TUN 外の通信は別途検証が必要です。DNS のプライバシーと IP 評判は別の指標です。",
    ),
    "dnsDiagnosticNoEndpoint": MessageLookupByLibrary.simpleMessage(
      "ネットワーク端点なし",
    ),
    "dnsDiagnosticNoWarnings": MessageLookupByLibrary.simpleMessage(
      "警告コードはありませんが、漏洩がないことの証明ではありません。",
    ),
    "dnsDiagnosticNotConfigured": MessageLookupByLibrary.simpleMessage(
      "有効な DNS 設定がありません",
    ),
    "dnsDiagnosticOrdinary": MessageLookupByLibrary.simpleMessage(
      "通常の問い合わせ：メイン / fallback / ポリシー",
    ),
    "dnsDiagnosticPathBlocked": MessageLookupByLibrary.simpleMessage(
      "設定された接続先でブロック",
    ),
    "dnsDiagnosticPathDhcp": MessageLookupByLibrary.simpleMessage(
      "DHCP で取得したリゾルバー",
    ),
    "dnsDiagnosticPathDirect": MessageLookupByLibrary.simpleMessage("直接経路"),
    "dnsDiagnosticPathInterface": MessageLookupByLibrary.simpleMessage(
      "インターフェース指定の直接経路",
    ),
    "dnsDiagnosticPathOverlay": MessageLookupByLibrary.simpleMessage(
      "オーバーレイ DNS：プロキシ専用か未検証",
    ),
    "dnsDiagnosticPathProxy": MessageLookupByLibrary.simpleMessage(
      "設定上はプロキシ経由：実測未検証",
    ),
    "dnsDiagnosticPathRules": MessageLookupByLibrary.simpleMessage(
      "ルール経由：DIRECT を選ぶ場合があります",
    ),
    "dnsDiagnosticPathSynthetic": MessageLookupByLibrary.simpleMessage(
      "合成 DNS 応答",
    ),
    "dnsDiagnosticPathSystem": MessageLookupByLibrary.simpleMessage(
      "システムのリゾルバー",
    ),
    "dnsDiagnosticReadAt": m4,
    "dnsDiagnosticReady": MessageLookupByLibrary.simpleMessage("有効な設定を読み取りました"),
    "dnsDiagnosticRefresh": MessageLookupByLibrary.simpleMessage("スナップショットを更新"),
    "dnsDiagnosticRetryHint": MessageLookupByLibrary.simpleMessage(
      "現在の結果がありません。更新して再試行してください。古いコアは未対応の場合があります。",
    ),
    "dnsDiagnosticScope": MessageLookupByLibrary.simpleMessage(
      "設定のスナップショットであり、DNS 漏洩の判定ではありません",
    ),
    "dnsDiagnosticTarget": m5,
    "dnsDiagnosticTitle": MessageLookupByLibrary.simpleMessage("有効な DNS 経路"),
    "dnsDiagnosticUnavailable": MessageLookupByLibrary.simpleMessage(
      "DNS 診断を利用できません",
    ),
    "dnsDiagnosticWarningBootstrap": MessageLookupByLibrary.simpleMessage(
      "ブートストラップ DNS は直接問い合わせる場合があります。端点を確認してください。",
    ),
    "dnsDiagnosticWarningDirect": MessageLookupByLibrary.simpleMessage(
      "通常通信または直接通信のリゾルバーは直接問い合わせる場合があります。",
    ),
    "dnsDiagnosticWarningHost": MessageLookupByLibrary.simpleMessage(
      "システムまたは DHCP リゾルバー経路があります。",
    ),
    "dnsDiagnosticWarningProxy": MessageLookupByLibrary.simpleMessage(
      "プロキシまたはオーバーレイが設定されていますが、実際の出口は未検証です。",
    ),
    "dnsDiagnosticWarningRules": MessageLookupByLibrary.simpleMessage(
      "DNS ルールは DIRECT を選ぶ場合があります。ルール遵守はプロキシ専用ではありません。",
    ),
    "dnsDiagnosticWarningUnknown": MessageLookupByLibrary.simpleMessage(
      "不明または未検証の経路には追加の確認が必要です。",
    ),
    "dnsDiagnosticWarnings": MessageLookupByLibrary.simpleMessage("経路の警告と制限"),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNSハイジャッキング"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNSモード"),
    "dnsProxyTarget": MessageLookupByLibrary.simpleMessage("DNS プロキシ先"),
    "dnsProxyTargetDesc": MessageLookupByLibrary.simpleMessage(
      "既存の静的プロキシまたはグループを指定します。DIRECT、プロバイダーの自動追加、フィルターは使用できません。通常通信と直接通信の DNS に適用します。",
    ),
    "dnsSafetyInvalidConfig": m6,
    "dnsSafetyMode": MessageLookupByLibrary.simpleMessage("DNS 安全モード"),
    "dnsSafetyModeCompatible": MessageLookupByLibrary.simpleMessage("互換"),
    "dnsSafetyModeCustom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "dnsSafetyModeDesc": MessageLookupByLibrary.simpleMessage(
      "プロキシのみモードには静的なプロキシ専用経路と IP アドレスの明示的なブートストラップ DNS が必要です。ブートストラップは直接接続で、DNS 漏洩の実測ではありません。",
    ),
    "dnsSafetyModeProxyOnly": MessageLookupByLibrary.simpleMessage("プロキシのみ"),
    "doYouWantToPass": MessageLookupByLibrary.simpleMessage("通過させますか？"),
    "domain": MessageLookupByLibrary.simpleMessage("ドメイン"),
    "download": MessageLookupByLibrary.simpleMessage("ダウンロード"),
    "downloadSpeed": MessageLookupByLibrary.simpleMessage("ダウンロード速度"),
    "edit": MessageLookupByLibrary.simpleMessage("編集"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage("グローバルルールを編集"),
    "editProxy": MessageLookupByLibrary.simpleMessage("プロキシを編集"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを編集"),
    "editRule": MessageLookupByLibrary.simpleMessage("ルールを編集"),
    "editSsid": MessageLookupByLibrary.simpleMessage("SSIDを編集"),
    "emptyTip": m7,
    "en": MessageLookupByLibrary.simpleMessage("英語"),
    "entries": MessageLookupByLibrary.simpleMessage(" エントリ"),
    "entriesCount": m8,
    "exclude": MessageLookupByLibrary.simpleMessage("最近のタスクから非表示"),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "アプリがバックグラウンド時に最近のタスクから非表示",
    ),
    "excludeProxyFilter": MessageLookupByLibrary.simpleMessage("除外プロキシフィルター"),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Exclude SSIDs"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.",
    ),
    "excludeType": MessageLookupByLibrary.simpleMessage("除外タイプ"),
    "existsTip": m9,
    "exit": MessageLookupByLibrary.simpleMessage("終了"),
    "expand": MessageLookupByLibrary.simpleMessage("標準"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("期待されるステータス"),
    "exportFile": MessageLookupByLibrary.simpleMessage("ファイルをエクスポート"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("ログをエクスポート"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("エクスポート成功"),
    "expressiveScheme": MessageLookupByLibrary.simpleMessage("エクスプレッシブ"),
    "externalController": MessageLookupByLibrary.simpleMessage("外部コントローラー"),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとClashコアをポート9090で制御可能",
    ),
    "externalFetch": MessageLookupByLibrary.simpleMessage("外部取得"),
    "externalLink": MessageLookupByLibrary.simpleMessage("外部リンク"),
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fakeipフィルター"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fakeip範囲"),
    "fallback": MessageLookupByLibrary.simpleMessage("フォールバック"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage("通常はオフショアDNSを使用"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("フォールバックフィルター"),
    "feedback": MessageLookupByLibrary.simpleMessage("フィードバック"),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("ハイファイデリティー"),
    "file": MessageLookupByLibrary.simpleMessage("ファイル"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("プロファイルを直接アップロード"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "ファイルが変更されました。保存しますか？",
    ),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("プロセス検出"),
    "findProcessModeDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとパフォーマンスが若干低下します",
    ),
    "fontFamily": MessageLookupByLibrary.simpleMessage("フォントファミリー"),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "コアを強制再起動してもよろしいですか？",
    ),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("フルーツサラダ"),
    "general": MessageLookupByLibrary.simpleMessage("一般"),
    "geoAutoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "geoAutoUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔"),
    "geoAutoUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "自動更新間隔は0より大きくなければなりません",
    ),
    "geoOptions": MessageLookupByLibrary.simpleMessage("Geoオプション"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geoリソース"),
    "geoSkipped": m10,
    "geoUpdated": m11,
    "geoUpdating": m12,
    "geodataLoader": MessageLookupByLibrary.simpleMessage("Geo低メモリモード"),
    "geodataLoaderDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとGeo低メモリローダーを使用",
    ),
    "geoipCode": MessageLookupByLibrary.simpleMessage("GeoIPコード"),
    "global": MessageLookupByLibrary.simpleMessage("グローバル"),
    "go": MessageLookupByLibrary.simpleMessage("移動"),
    "goDownload": MessageLookupByLibrary.simpleMessage("ダウンロードへ"),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage("スクリプト設定に移動"),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage("変更をキャッシュしますか？"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("リストから隠す"),
    "host": MessageLookupByLibrary.simpleMessage("ホスト"),
    "hostsDesc": MessageLookupByLibrary.simpleMessage("ホストを追加"),
    "hotkeyConflict": MessageLookupByLibrary.simpleMessage("ホットキー競合"),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage("ホットキー管理"),
    "hotkeyManagementDesc": MessageLookupByLibrary.simpleMessage(
      "キーボードでアプリを制御",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("時間"),
    "hoursAgo": m13,
    "hoursCount": m14,
    "icon": MessageLookupByLibrary.simpleMessage("アイコン"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("アイコン履歴"),
    "iconStyle": MessageLookupByLibrary.simpleMessage("アイコンスタイル"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("アイコンURL"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignore Battery Optimization",
    ),
    "import": MessageLookupByLibrary.simpleMessage("インポート"),
    "importFile": MessageLookupByLibrary.simpleMessage("ファイルからインポート"),
    "importFromURL": MessageLookupByLibrary.simpleMessage("URLからインポート"),
    "importUrl": MessageLookupByLibrary.simpleMessage("URLからインポート"),
    "includeAllProxies": MessageLookupByLibrary.simpleMessage("すべてのプロキシを含める"),
    "includeAllProxiesTip": MessageLookupByLibrary.simpleMessage(
      "プロキシグループに含まれないすべてのプロキシをインポートします。下でさらにプロキシグループを追加できます",
    ),
    "includeAllProxyProviders": MessageLookupByLibrary.simpleMessage(
      "すべてのプロキシプロバイダーを含める",
    ),
    "includeAllProxyProvidersTip": MessageLookupByLibrary.simpleMessage(
      "有効にすると、インポートされたプロキシプロバイダーを上書きします",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("長期有効"),
    "init": MessageLookupByLibrary.simpleMessage("初期化"),
    "inputCorrectHotkey": MessageLookupByLibrary.simpleMessage("正しいホットキーを入力"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage("プロキシグループ名を入力"),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage("ルール内容を入力"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("インテリジェント選択"),
    "internet": MessageLookupByLibrary.simpleMessage("インターネット"),
    "interval": MessageLookupByLibrary.simpleMessage("インターバル"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("イントラネットIP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage("無効なバックアップファイル"),
    "invalidPolicy": m15,
    "invalidProxy": m16,
    "invalidProxyProvider": m17,
    "invalidSubRule": m18,
    "ipcidr": MessageLookupByLibrary.simpleMessage("IPCIDR"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage("有効化するとIPv6トラフィックを受信可能"),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage("IPv6インバウンドを許可"),
    "ja": MessageLookupByLibrary.simpleMessage("日本語"),
    "justNow": MessageLookupByLibrary.simpleMessage("たった今"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCPキープアライブ間隔",
    ),
    "key": MessageLookupByLibrary.simpleMessage("キー"),
    "language": MessageLookupByLibrary.simpleMessage("言語"),
    "layout": MessageLookupByLibrary.simpleMessage("レイアウト"),
    "licenses": MessageLookupByLibrary.simpleMessage("ライセンス"),
    "light": MessageLookupByLibrary.simpleMessage("ライト"),
    "links": MessageLookupByLibrary.simpleMessage("リンク"),
    "list": MessageLookupByLibrary.simpleMessage("リスト"),
    "listen": MessageLookupByLibrary.simpleMessage("リスン"),
    "loadTest": MessageLookupByLibrary.simpleMessage("読み込みテスト"),
    "loading": MessageLookupByLibrary.simpleMessage("読み込み中..."),
    "local": MessageLookupByLibrary.simpleMessage("ローカル"),
    "localBackupDesc": MessageLookupByLibrary.simpleMessage("ローカルにデータをバックアップ"),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Location Permission",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "位置情報の権限が拒否されたため、現在の Wi-Fi 名を取得できません。システム設定で位置情報の権限を手動で有効にしてください。",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.",
    ),
    "locationPermissionGuide": m19,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Location Permission Required",
    ),
    "log": MessageLookupByLibrary.simpleMessage("ログ"),
    "logLevel": MessageLookupByLibrary.simpleMessage("ログレベル"),
    "logcat": MessageLookupByLibrary.simpleMessage("ログキャット"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage("無効化するとログエントリを非表示"),
    "logs": MessageLookupByLibrary.simpleMessage("ログ"),
    "logsDesc": MessageLookupByLibrary.simpleMessage("ログキャプチャ記録"),
    "logsTest": MessageLookupByLibrary.simpleMessage("ログテスト"),
    "loopback": MessageLookupByLibrary.simpleMessage("ループバック解除ツール"),
    "loopbackDesc": MessageLookupByLibrary.simpleMessage("UWPループバック解除用"),
    "loose": MessageLookupByLibrary.simpleMessage("疎"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("送信元IPをマッチング"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("最大失敗回数"),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("メモリ情報"),
    "messageTest": MessageLookupByLibrary.simpleMessage("メッセージテスト"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("これはメッセージです。"),
    "min": MessageLookupByLibrary.simpleMessage("最小化"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("終了時に最小化"),
    "minimizeOnExitDesc": MessageLookupByLibrary.simpleMessage(
      "システムの終了イベントを変更",
    ),
    "minutesAgo": m20,
    "mixedPort": MessageLookupByLibrary.simpleMessage("混合ポート"),
    "mode": MessageLookupByLibrary.simpleMessage("モード"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("モノクローム"),
    "monthsAgo": m21,
    "more": MessageLookupByLibrary.simpleMessage("詳細"),
    "name": MessageLookupByLibrary.simpleMessage("名前"),
    "nameserver": MessageLookupByLibrary.simpleMessage("ネームサーバー"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage("ドメイン解決用"),
    "nameserverPolicy": MessageLookupByLibrary.simpleMessage("ネームサーバーポリシー"),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "対応するネームサーバーポリシーを指定",
    ),
    "network": MessageLookupByLibrary.simpleMessage("ネットワーク"),
    "networkDesc": MessageLookupByLibrary.simpleMessage("ネットワーク関連設定の変更"),
    "networkDetection": MessageLookupByLibrary.simpleMessage("ネットワーク検出"),
    "networkException": MessageLookupByLibrary.simpleMessage(
      "ネットワーク例外、接続を確認してもう一度お試しください",
    ),
    "networkSpeed": MessageLookupByLibrary.simpleMessage("ネットワーク速度"),
    "networkType": MessageLookupByLibrary.simpleMessage("ネットワーク種別"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("ニュートラル"),
    "noData": MessageLookupByLibrary.simpleMessage("データなし"),
    "noHotKey": MessageLookupByLibrary.simpleMessage("ホットキーなし"),
    "noInfo": MessageLookupByLibrary.simpleMessage("情報なし"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage("今後表示しない"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("ネットワークなし"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("ネットワークなしアプリ"),
    "noRecords": MessageLookupByLibrary.simpleMessage("履歴なし"),
    "noResolve": MessageLookupByLibrary.simpleMessage("IPを解決しない"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage("ホスト名を解決しない"),
    "nodeQualityBusy": MessageLookupByLibrary.simpleMessage(
      "他の検査が実行中です。しばらくして再試行してください。",
    ),
    "nodeQualityCloudflareScore": MessageLookupByLibrary.simpleMessage(
      "Cloudflare リクエストスコア",
    ),
    "nodeQualityCloudflareScoreUnavailable":
        MessageLookupByLibrary.simpleMessage(
          "利用不可：/cdn-cgi/trace は Bot Score を返しません。本アプリは推測値や偽のスコアを表示しません。",
        ),
    "nodeQualityConcreteOnly": MessageLookupByLibrary.simpleMessage(
      "具体的なノードを選択してください。動的・負荷分散グループは未対応です。",
    ),
    "nodeQualityCooldown": m22,
    "nodeQualityEdge": MessageLookupByLibrary.simpleMessage("エッジ／国・地域"),
    "nodeQualityEgressIp": MessageLookupByLibrary.simpleMessage("出口 IP"),
    "nodeQualityFailed": MessageLookupByLibrary.simpleMessage(
      "不明：検査が利用できないか失敗しました。手動で再試行してください。旧コアは未対応の場合があります。",
    ),
    "nodeQualityInactive": MessageLookupByLibrary.simpleMessage(
      "コアを起動・初期化してから検査してください。",
    ),
    "nodeQualityIpType": MessageLookupByLibrary.simpleMessage("IP 種別"),
    "nodeQualityMismatch": MessageLookupByLibrary.simpleMessage(
      "両サービスの出口 IP が異なります。リスクスコアを Cloudflare の IP に帰属させないでください。",
    ),
    "nodeQualityNonResidential": MessageLookupByLibrary.simpleMessage(
      "非住宅 IP（データセンターとは限りません）",
    ),
    "nodeQualityNotRequested": MessageLookupByLibrary.simpleMessage("未リクエスト"),
    "nodeQualityOk": MessageLookupByLibrary.simpleMessage("検査成功"),
    "nodeQualityOptIn": MessageLookupByLibrary.simpleMessage(
      "IPPure リスク検査を含める",
    ),
    "nodeQualityPickNode": MessageLookupByLibrary.simpleMessage(
      "先にプロキシページで具体的なノードを選択してください。",
    ),
    "nodeQualityPrivacy": MessageLookupByLibrary.simpleMessage(
      "この画面でのみ有効：IPPure に出口 IP とリクエスト情報が送信されます。QuanClash はアカウントやプロキシ認証情報を送信しません。Cloudflare にも独自の検査が送信されます。自動検査はありません。",
    ),
    "nodeQualityProbeFootprint": MessageLookupByLibrary.simpleMessage(
      "手動検査ごとに、選択したサービスへ HTTPS リクエストを 1 回ずつ送信します。自動再試行、Cookie の再利用、ブラウザ指紋の偽装は行いません。第三者による記録は残り得るため、影響ゼロは保証できません。",
    ),
    "nodeQualityResidential": MessageLookupByLibrary.simpleMessage("住宅 IP"),
    "nodeQualityRiskScore": MessageLookupByLibrary.simpleMessage(
      "IP リスクスコア（IPPure）",
    ),
    "nodeQualityRun": MessageLookupByLibrary.simpleMessage("今すぐ検査"),
    "nodeQualitySampledAt": m23,
    "nodeQualityScope": MessageLookupByLibrary.simpleMessage(
      "このノード経由の手動 HTTPS 検査です。Cloudflare は到達性、出口 IP、エッジの TTFB を測定し、IP の純度は判定しません。DNS／ブートストラップは直接接続の場合があります。DIRECT は直接接続を検査します。",
    ),
    "nodeQualityScoreScope": MessageLookupByLibrary.simpleMessage(
      "IPPure Beta の情報は参考値で、純度の百分率、Cloudflare のスコア、安全性の保証ではありません。欠落した値と未検証の IPv6 スコアは不明と表示します。",
    ),
    "nodeQualityStatusFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "nodeQualityStatusOk": MessageLookupByLibrary.simpleMessage("成功"),
    "nodeQualityStatusTimeout": MessageLookupByLibrary.simpleMessage("タイムアウト"),
    "nodeQualityStatusUnavailable": MessageLookupByLibrary.simpleMessage(
      "利用不可",
    ),
    "nodeQualityTimeout": MessageLookupByLibrary.simpleMessage(
      "不明：検査がタイムアウトしました",
    ),
    "nodeQualityTitle": MessageLookupByLibrary.simpleMessage("ノード品質"),
    "none": MessageLookupByLibrary.simpleMessage("なし"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループは選択できません",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルがありません。追加してください",
    ),
    "nullTip": m24,
    "numberTip": m25,
    "onDemand": MessageLookupByLibrary.simpleMessage("On Demand"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "Configure the program running state for specific scenarios",
    ),
    "onlyIcon": MessageLookupByLibrary.simpleMessage("アイコンのみ"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage("プロキシのみ統計"),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとプロキシトラフィックのみ統計",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("オプション"),
    "options": MessageLookupByLibrary.simpleMessage("オプション"),
    "other": MessageLookupByLibrary.simpleMessage("その他"),
    "otherContributors": MessageLookupByLibrary.simpleMessage("その他の貢献者"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("アウトバウンドモード"),
    "override": MessageLookupByLibrary.simpleMessage("上書き"),
    "overrideDns": MessageLookupByLibrary.simpleMessage("DNS上書き"),
    "overrideDnsDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとプロファイルのDNS設定を上書き",
    ),
    "overrideMode": MessageLookupByLibrary.simpleMessage("上書きモード"),
    "overrideScript": MessageLookupByLibrary.simpleMessage("上書きスクリプト"),
    "overviewPhraseAfternoon": MessageLookupByLibrary.simpleMessage(
      "好調です。接続を維持しています。",
    ),
    "overviewPhraseEvening": MessageLookupByLibrary.simpleMessage(
      "夜もやる気十分でサポートします。",
    ),
    "overviewPhraseMorning": MessageLookupByLibrary.simpleMessage(
      "元気いっぱい、一日中安定した保護を。",
    ),
    "overviewPhraseNight": MessageLookupByLibrary.simpleMessage("深夜も堅牢に見守ります。"),
    "overviewTitle": MessageLookupByLibrary.simpleMessage("概要"),
    "overwriteTypeCustom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "overwriteTypeCustomDesc": MessageLookupByLibrary.simpleMessage(
      "カスタムモード、プロキシグループとルールを完全にカスタマイズ可能",
    ),
    "palette": MessageLookupByLibrary.simpleMessage("パレット"),
    "password": MessageLookupByLibrary.simpleMessage("パスワード"),
    "paste": MessageLookupByLibrary.simpleMessage("貼り付け"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage(
      "WebDAVをバインドしてください",
    ),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "スクリプト名を入力してください",
    ),
    "pleaseInputAdminPassword": MessageLookupByLibrary.simpleMessage(
      "管理者パスワードを入力",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "有効なQRコードをアップロードしてください",
    ),
    "port": MessageLookupByLibrary.simpleMessage("ポート"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage("別のポートを入力してください"),
    "portTip": m26,
    "preferH3Desc": MessageLookupByLibrary.simpleMessage("DOHのHTTP/3を優先使用"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Prerequisites"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("キーボードを押してください"),
    "preview": MessageLookupByLibrary.simpleMessage("プレビュー"),
    "process": MessageLookupByLibrary.simpleMessage("プロセス"),
    "profile": MessageLookupByLibrary.simpleMessage("プロファイル"),
    "profileActive": MessageLookupByLibrary.simpleMessage("使用中"),
    "profileAutoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("有効な間隔形式を入力してください"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage("自動更新間隔を入力してください"),
    "profileCarouselHint": MessageLookupByLibrary.simpleMessage(
      "カードをタップで詳細、ドラッグまたは矢印キーで切替",
    ),
    "profileCollapse": MessageLookupByLibrary.simpleMessage("閉じる"),
    "profileCurrentConfig": MessageLookupByLibrary.simpleMessage("現在の設定"),
    "profileCurrentNode": MessageLookupByLibrary.simpleMessage("現在のノード"),
    "profileDaysCount": m27,
    "profileDaysLeft": m28,
    "profileDaysLeftShort": m29,
    "profileDraftHint": MessageLookupByLibrary.simpleMessage(
      "名前と購読 URL を入力すると、保存時に設定を取得します",
    ),
    "profileEditTitle": MessageLookupByLibrary.simpleMessage("設定を編集"),
    "profileEveryHours": m30,
    "profileEveryMinutes": m31,
    "profileExpire": MessageLookupByLibrary.simpleMessage("有効期限"),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "プロファイルが変更されました。自動更新を無効化しますか？",
    ),
    "profileHideLink": MessageLookupByLibrary.simpleMessage("リンクを隠す"),
    "profileImportFile": MessageLookupByLibrary.simpleMessage("ファイルから読み込む"),
    "profileInactive": MessageLookupByLibrary.simpleMessage("未使用"),
    "profileLastUpdate": MessageLookupByLibrary.simpleMessage("最終更新"),
    "profileLocalFile": MessageLookupByLibrary.simpleMessage("ローカルファイル"),
    "profileLocalYaml": MessageLookupByLibrary.simpleMessage("ローカル YAML"),
    "profileManualUpdate": MessageLookupByLibrary.simpleMessage("手動"),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイル名を入力してください",
    ),
    "profileNew": MessageLookupByLibrary.simpleMessage("新しい設定"),
    "profileNoTrafficInfo": MessageLookupByLibrary.simpleMessage("通信量情報なし"),
    "profileNodeCount": MessageLookupByLibrary.simpleMessage("ノード数"),
    "profileNodeCountValue": m32,
    "profileNotLoaded": MessageLookupByLibrary.simpleMessage("切り替え後に表示"),
    "profileOff": MessageLookupByLibrary.simpleMessage("オフ"),
    "profileOpenEditor": MessageLookupByLibrary.simpleMessage("エディタを開く"),
    "profileRemainingDays": MessageLookupByLibrary.simpleMessage("残り日数"),
    "profileRemainingTraffic": MessageLookupByLibrary.simpleMessage("残り通信量"),
    "profileRemote": MessageLookupByLibrary.simpleMessage("リモート購読"),
    "profileReplaceFile": MessageLookupByLibrary.simpleMessage("ファイルを置換"),
    "profileSaveChanges": MessageLookupByLibrary.simpleMessage("変更を保存"),
    "profileSetCurrent": MessageLookupByLibrary.simpleMessage("現在に設定"),
    "profileShowLink": MessageLookupByLibrary.simpleMessage("リンクを表示"),
    "profileStrategyGroup": MessageLookupByLibrary.simpleMessage("グループ"),
    "profileSubscription": MessageLookupByLibrary.simpleMessage("購読"),
    "profileSubscriptionUrl": MessageLookupByLibrary.simpleMessage("購読 URL"),
    "profileTapToExpand": MessageLookupByLibrary.simpleMessage("タップで詳細"),
    "profileUpdateInterval": MessageLookupByLibrary.simpleMessage("更新間隔"),
    "profileUpdateNow": MessageLookupByLibrary.simpleMessage("今すぐ更新"),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "有効なプロファイルURLを入力してください",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルURLを入力してください",
    ),
    "profileUrlRequired": MessageLookupByLibrary.simpleMessage(
      "購読 URL を入力してください",
    ),
    "profileUsed": MessageLookupByLibrary.simpleMessage("使用済み"),
    "profileUsedPercent": m33,
    "profiles": MessageLookupByLibrary.simpleMessage("プロファイル一覧"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("プロファイルの並び替え"),
    "project": MessageLookupByLibrary.simpleMessage("プロジェクト"),
    "providers": MessageLookupByLibrary.simpleMessage("プロバイダー"),
    "proxies": MessageLookupByLibrary.simpleMessage("プロキシ"),
    "proxiesEmpty": MessageLookupByLibrary.simpleMessage("プロキシが空です"),
    "proxiesFrequent": MessageLookupByLibrary.simpleMessage("よく使うノード"),
    "proxiesLocateSelected": MessageLookupByLibrary.simpleMessage("現在のノードへ移動"),
    "proxiesOtherRegion": MessageLookupByLibrary.simpleMessage("その他の地域"),
    "proxiesProviderInfo": MessageLookupByLibrary.simpleMessage("プロバイダー情報"),
    "proxiesRecent": MessageLookupByLibrary.simpleMessage("最近使用"),
    "proxiesViewAll": MessageLookupByLibrary.simpleMessage("すべてのノード"),
    "proxiesViewMode": MessageLookupByLibrary.simpleMessage("表示"),
    "proxiesViewRegion": MessageLookupByLibrary.simpleMessage("地域別にグループ化"),
    "proxyChains": MessageLookupByLibrary.simpleMessage("プロキシチェーン"),
    "proxyDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "選択されたプロキシに異常があることを検出しました",
    ),
    "proxyFilter": MessageLookupByLibrary.simpleMessage("プロキシフィルター"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループ"),
    "proxyGroupDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループが異常であることを検出しました",
    ),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage("プロキシグループが空です"),
    "proxyGroupNameDuplicate": MessageLookupByLibrary.simpleMessage(
      "プロキシグループ名が重複しています",
    ),
    "proxyGroupNameEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシグループ名は空にできません",
    ),
    "proxyNameserver": MessageLookupByLibrary.simpleMessage("プロキシネームサーバー"),
    "proxyNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "プロキシノード解決用ドメイン",
    ),
    "proxyPort": MessageLookupByLibrary.simpleMessage("プロキシポート"),
    "proxyProviderDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "選択されたプロキシプロバイダーに異常があることを検出しました",
    ),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("プロキシプロバイダー"),
    "proxyProvidersEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーが空です",
    ),
    "proxyProvidersNotEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーは空にできません",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("プロキシタイプ"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("キャッシュの削除"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("純黒モード"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QRコード"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage("QRコードをスキャンしてプロファイルを取得"),
    "quickFill": MessageLookupByLibrary.simpleMessage("クイック入力"),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("レインボー"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redirポート"),
    "redo": MessageLookupByLibrary.simpleMessage("やり直す"),
    "remote": MessageLookupByLibrary.simpleMessage("リモート"),
    "remoteBackupDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAVにデータをバックアップ",
    ),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("リモート宛先"),
    "remove": MessageLookupByLibrary.simpleMessage("削除"),
    "rename": MessageLookupByLibrary.simpleMessage("リネーム"),
    "request": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requests": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requestsDesc": MessageLookupByLibrary.simpleMessage("最近のリクエスト記録を表示"),
    "reset": MessageLookupByLibrary.simpleMessage("リセット"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "現在のページに変更があります。リセットしてもよろしいですか？",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("リセットを確定"),
    "resources": MessageLookupByLibrary.simpleMessage("リソース"),
    "resourcesDesc": MessageLookupByLibrary.simpleMessage("外部リソース関連情報"),
    "respectRules": MessageLookupByLibrary.simpleMessage("ルール尊重"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "DNS接続がルールに従う（proxy-server-nameserverの設定が必要）",
    ),
    "restart": MessageLookupByLibrary.simpleMessage("再起動"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage("コアを再起動してもよろしいですか？"),
    "restore": MessageLookupByLibrary.simpleMessage("復元"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("すべてのデータを復元する"),
    "restoreException": MessageLookupByLibrary.simpleMessage("復元例外"),
    "restoreFromFileDesc": MessageLookupByLibrary.simpleMessage(
      "ファイルを介してデータを復元する",
    ),
    "restoreFromWebDAVDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAVを介してデータを復元する",
    ),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage("設定ファイルのみを復元する"),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("復元ストラテジー"),
    "restoreStrategyDesc": MessageLookupByLibrary.simpleMessage(
      "復元時に既存データをどう扱うか",
    ),
    "restoreStrategy_compatible": MessageLookupByLibrary.simpleMessage("互換"),
    "restoreStrategy_override": MessageLookupByLibrary.simpleMessage("上書き"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("復元に成功しました"),
    "riskIndex": MessageLookupByLibrary.simpleMessage("リスク指数"),
    "riskIndexHigh": MessageLookupByLibrary.simpleMessage("高リスク"),
    "riskIndexLow": MessageLookupByLibrary.simpleMessage("低リスク"),
    "riskIndexMedium": MessageLookupByLibrary.simpleMessage("中リスク"),
    "riskIndexNoScore": MessageLookupByLibrary.simpleMessage("スコアなし"),
    "riskIndexNotChecked": MessageLookupByLibrary.simpleMessage("未検査"),
    "riskIndexTapToCheck": MessageLookupByLibrary.simpleMessage(
      "タップしてリスク指数を検査",
    ),
    "routeAddress": MessageLookupByLibrary.simpleMessage("ルートアドレス"),
    "routeAddressDesc": MessageLookupByLibrary.simpleMessage("ルートアドレスを設定"),
    "routeMode": MessageLookupByLibrary.simpleMessage("ルートモード"),
    "routeMode_bypassPrivate": MessageLookupByLibrary.simpleMessage(
      "プライベートルートをバイパス",
    ),
    "routeMode_config": MessageLookupByLibrary.simpleMessage("設定を使用"),
    "ru": MessageLookupByLibrary.simpleMessage("ロシア語"),
    "rule": MessageLookupByLibrary.simpleMessage("ルール"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage("論理ルール AND"),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "完全なドメインをマッチング",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインキーワードをマッチング",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "ワイルドカードマッチング（*と?のみサポート）",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "ドメイン接尾辞をマッチング",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "DSCPマークをマッチング (tproxy udp inboundのみ)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "宛先ポート範囲をマッチング",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "IPの国コードをマッチング",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Match domains within Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンド名をマッチング",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドポートをマッチング",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドタイプをマッチング",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドユーザー名をマッチング（/で複数指定可）",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage("IPのASNをマッチング"),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲をマッチング（IP-CIDR6はエイリアスです）",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲をマッチング",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "IP接尾辞範囲をマッチング",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "すべてのリクエストにマッチ（条件なし）",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "TCPまたはUDPをマッチング",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage("論理ルール NOT"),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("論理ルール OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名でマッチング（Androidではパッケージ名）",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名正規表現でマッチング（Androidではパッケージ名）",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "フルプロセスパスでマッチング",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスパス正規表現でマッチング",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "ルールセットを参照。rule-providersの設定が必要",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPの国コードをマッチング",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPのASNをマッチング",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPアドレス範囲をマッチング",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IP接尾辞範囲をマッチング",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "送信元ポート範囲をマッチング",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "サブルールにマッチング。括弧の使用に注意",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Linux USER IDをマッチング",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("ルールが空です"),
    "ruleName": MessageLookupByLibrary.simpleMessage("ルール名"),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("ルールプロバイダー"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("ルールセット"),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("ルール対象"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("変更を保存しますか？"),
    "script": MessageLookupByLibrary.simpleMessage("スクリプト"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "スクリプトモード、外部拡張スクリプトを使用し、ワンクリックで設定を上書きする機能を提供",
    ),
    "search": MessageLookupByLibrary.simpleMessage("検索"),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "secondsCount": m34,
    "sectionMain": MessageLookupByLibrary.simpleMessage("メイン"),
    "sectionMonitor": MessageLookupByLibrary.simpleMessage("監視"),
    "sectionSystem": MessageLookupByLibrary.simpleMessage("システム"),
    "selectAll": MessageLookupByLibrary.simpleMessage("すべて選択"),
    "selectProxies": MessageLookupByLibrary.simpleMessage("プロキシを選択"),
    "selectProxyProviders": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーを選択",
    ),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage("ルールセットを選択してください"),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "分流戦略を選択してください",
    ),
    "selectSubRule": MessageLookupByLibrary.simpleMessage("サブルールを選択してください"),
    "selected": MessageLookupByLibrary.simpleMessage("選択済み"),
    "selectedCountTitle": m35,
    "serviceRunning": MessageLookupByLibrary.simpleMessage("サービス正常稼働中"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "settingsAboutApp": MessageLookupByLibrary.simpleMessage("QuanClash について"),
    "settingsAccessMode": MessageLookupByLibrary.simpleMessage("アクセスモード"),
    "settingsAccessSource": MessageLookupByLibrary.simpleMessage("アプリの絞り込み"),
    "settingsBackupLocal": MessageLookupByLibrary.simpleMessage("ローカル"),
    "settingsBackupNow": MessageLookupByLibrary.simpleMessage("今すぐバックアップ"),
    "settingsBackupRemote": MessageLookupByLibrary.simpleMessage("WebDAV"),
    "settingsBindDav": MessageLookupByLibrary.simpleMessage("連携"),
    "settingsCurrentCore": MessageLookupByLibrary.simpleMessage("現在のコア"),
    "settingsDesc": MessageLookupByLibrary.simpleMessage("外観・ネットワーク・コア・データ"),
    "settingsDns": MessageLookupByLibrary.simpleMessage("DNS 設定"),
    "settingsEditDav": MessageLookupByLibrary.simpleMessage("編集"),
    "settingsEnterAccess": MessageLookupByLibrary.simpleMessage(
      "アプリごとのアクセスを設定",
    ),
    "settingsEnterAdvanced": MessageLookupByLibrary.simpleMessage(
      "ネットワーク、DNS、ルール、スクリプト",
    ),
    "settingsEnterBasic": MessageLookupByLibrary.simpleMessage("基本設定を編集"),
    "settingsEnterResources": MessageLookupByLibrary.simpleMessage(
      "GeoIP / GeoSite リソース",
    ),
    "settingsGeneral": MessageLookupByLibrary.simpleMessage("一般"),
    "settingsImportFile": MessageLookupByLibrary.simpleMessage("ファイルから復元"),
    "settingsLogLevel": MessageLookupByLibrary.simpleMessage("ログレベル"),
    "settingsNetworkOptions": MessageLookupByLibrary.simpleMessage("ネットワーク設定"),
    "settingsNoDav": MessageLookupByLibrary.simpleMessage("WebDAV 未連携"),
    "settingsOpenLogs": MessageLookupByLibrary.simpleMessage("ログを開く"),
    "settingsResetDns": MessageLookupByLibrary.simpleMessage("DNS をリセット"),
    "settingsResetHotkeys": MessageLookupByLibrary.simpleMessage(
      "すべてのショートカットをリセット",
    ),
    "settingsResourceActions": MessageLookupByLibrary.simpleMessage("リソース操作"),
    "settingsRestoreDav": MessageLookupByLibrary.simpleMessage("リモートから復元"),
    "settingsSaveAccess": MessageLookupByLibrary.simpleMessage("アクセス制御を保存"),
    "settingsSyncDav": MessageLookupByLibrary.simpleMessage("リモートへ同期"),
    "settingsTextScale": MessageLookupByLibrary.simpleMessage("文字サイズ"),
    "settingsThemeColor": MessageLookupByLibrary.simpleMessage("ブランドカラー"),
    "show": MessageLookupByLibrary.simpleMessage("表示"),
    "shrink": MessageLookupByLibrary.simpleMessage("縮小"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("バックグラウンド起動"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage("バックグラウンドで起動"),
    "size": MessageLookupByLibrary.simpleMessage("サイズ"),
    "socksPort": MessageLookupByLibrary.simpleMessage("Socksポート"),
    "sort": MessageLookupByLibrary.simpleMessage("並び替え"),
    "source": MessageLookupByLibrary.simpleMessage("ソース"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("送信元IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("特殊プロキシ"),
    "specialRules": MessageLookupByLibrary.simpleMessage("特殊ルール"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("速度統計"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("分流戦略"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "分流戦略は空にできません",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDs is empty"),
    "stackMode": MessageLookupByLibrary.simpleMessage("スタックモード"),
    "standard": MessageLookupByLibrary.simpleMessage("標準"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "標準モード、基本設定を上書きし、シンプルなルール追加機能を提供",
    ),
    "start": MessageLookupByLibrary.simpleMessage("開始"),
    "startVpn": MessageLookupByLibrary.simpleMessage("VPNを開始中..."),
    "startup": MessageLookupByLibrary.simpleMessage("起動"),
    "status": MessageLookupByLibrary.simpleMessage("ステータス"),
    "statusDesc": MessageLookupByLibrary.simpleMessage("無効時はシステムDNSを使用"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("VPNを停止中..."),
    "style": MessageLookupByLibrary.simpleMessage("スタイル"),
    "subRule": MessageLookupByLibrary.simpleMessage("サブルール"),
    "subRuleEmpty": MessageLookupByLibrary.simpleMessage("サブルールが空です"),
    "subRuleNotEmpty": MessageLookupByLibrary.simpleMessage("サブルールは空にできません"),
    "submit": MessageLookupByLibrary.simpleMessage("送信"),
    "suspended": MessageLookupByLibrary.simpleMessage("一時停止中..."),
    "sync": MessageLookupByLibrary.simpleMessage("同期"),
    "system": MessageLookupByLibrary.simpleMessage("システム"),
    "systemApp": MessageLookupByLibrary.simpleMessage("システムアプリ"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "systemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "HTTPプロキシをVpnServiceに接続",
    ),
    "tab": MessageLookupByLibrary.simpleMessage("タブ"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("タブアニメーション"),
    "tabAnimationDesc": MessageLookupByLibrary.simpleMessage("モバイル表示でのみ有効"),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("タップして許可"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP並列処理"),
    "tcpConcurrentDesc": MessageLookupByLibrary.simpleMessage("TCP並列処理を許可"),
    "testInterval": MessageLookupByLibrary.simpleMessage("テスト間隔"),
    "testUrl": MessageLookupByLibrary.simpleMessage("URLテスト"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("使用時にテスト"),
    "textScale": MessageLookupByLibrary.simpleMessage("テキストスケーリング"),
    "theme": MessageLookupByLibrary.simpleMessage("テーマ"),
    "themeColor": MessageLookupByLibrary.simpleMessage("テーマカラー"),
    "themeDesc": MessageLookupByLibrary.simpleMessage("ダークモードの設定、色の調整"),
    "themeMode": MessageLookupByLibrary.simpleMessage("テーマモード"),
    "tight": MessageLookupByLibrary.simpleMessage("密"),
    "time": MessageLookupByLibrary.simpleMessage("時間"),
    "timeout": MessageLookupByLibrary.simpleMessage("タイムアウト"),
    "tip": MessageLookupByLibrary.simpleMessage("ヒント"),
    "toggle": MessageLookupByLibrary.simpleMessage("トグル"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("トーンスポット"),
    "tools": MessageLookupByLibrary.simpleMessage("ツール"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Tproxyポート"),
    "traffic": MessageLookupByLibrary.simpleMessage("通信量"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("トラフィック使用量"),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunDesc": MessageLookupByLibrary.simpleMessage("管理者モードでのみ有効"),
    "turnOff": MessageLookupByLibrary.simpleMessage("オフ"),
    "turnOn": MessageLookupByLibrary.simpleMessage("オン"),
    "undo": MessageLookupByLibrary.simpleMessage("元に戻す"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("統一遅延"),
    "unifiedDelayDesc": MessageLookupByLibrary.simpleMessage(
      "ハンドシェイクなどの余分な遅延を削除",
    ),
    "unknown": MessageLookupByLibrary.simpleMessage("不明"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage("不明なネットワークエラー"),
    "unnamed": MessageLookupByLibrary.simpleMessage("無題"),
    "update": MessageLookupByLibrary.simpleMessage("更新"),
    "upload": MessageLookupByLibrary.simpleMessage("アップロード"),
    "uploadSpeed": MessageLookupByLibrary.simpleMessage("アップロード速度"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlDesc": MessageLookupByLibrary.simpleMessage("URL経由でプロファイルを取得"),
    "urlTip": m36,
    "useHosts": MessageLookupByLibrary.simpleMessage("ホストを使用"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("システムホストを使用"),
    "userAgent": MessageLookupByLibrary.simpleMessage("ユーザーエージェント"),
    "value": MessageLookupByLibrary.simpleMessage("値"),
    "version": MessageLookupByLibrary.simpleMessage("バージョン"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("ビブラント"),
    "view": MessageLookupByLibrary.simpleMessage("表示"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN設定の変更が検出されました",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "VpnService経由で全システムトラフィックをルーティング",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage("変更はVPN再起動後に有効"),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage("WebDAV設定"),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("ホワイトリストモード"),
    "yearsAgo": m37,
    "zh_CN": MessageLookupByLibrary.simpleMessage("簡体字中国語"),
  };
}
