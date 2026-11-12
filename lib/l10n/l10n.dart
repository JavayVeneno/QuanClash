// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class AppLocalizations {
  AppLocalizations();

  static AppLocalizations? _current;

  static AppLocalizations get current {
    assert(
      _current != null,
      'No instance of AppLocalizations was loaded. Try to initialize the AppLocalizations delegate before accessing AppLocalizations.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<AppLocalizations> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = AppLocalizations();
      AppLocalizations._current = instance;

      return instance;
    });
  }

  static AppLocalizations of(BuildContext context) {
    final instance = AppLocalizations.maybeOf(context);
    assert(
      instance != null,
      'No instance of AppLocalizations present in the widget tree. Did you add AppLocalizations.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// `Rule`
  String get rule {
    return Intl.message('Rule', name: 'rule', desc: '', args: []);
  }

  /// `Global`
  String get global {
    return Intl.message('Global', name: 'global', desc: '', args: []);
  }

  /// `Direct`
  String get direct {
    return Intl.message('Direct', name: 'direct', desc: '', args: []);
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message('Dashboard', name: 'dashboard', desc: '', args: []);
  }

  /// `Proxies`
  String get proxies {
    return Intl.message('Proxies', name: 'proxies', desc: '', args: []);
  }

  /// `Profile`
  String get profile {
    return Intl.message('Profile', name: 'profile', desc: '', args: []);
  }

  /// `Profiles`
  String get profiles {
    return Intl.message('Profiles', name: 'profiles', desc: '', args: []);
  }

  /// `Tools`
  String get tools {
    return Intl.message('Tools', name: 'tools', desc: '', args: []);
  }

  /// `Logs`
  String get logs {
    return Intl.message('Logs', name: 'logs', desc: '', args: []);
  }

  /// `Log capture records`
  String get logsDesc {
    return Intl.message(
      'Log capture records',
      name: 'logsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Resources`
  String get resources {
    return Intl.message('Resources', name: 'resources', desc: '', args: []);
  }

  /// `External resource related info`
  String get resourcesDesc {
    return Intl.message(
      'External resource related info',
      name: 'resourcesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Traffic usage`
  String get trafficUsage {
    return Intl.message(
      'Traffic usage',
      name: 'trafficUsage',
      desc: '',
      args: [],
    );
  }

  /// `Network speed`
  String get networkSpeed {
    return Intl.message(
      'Network speed',
      name: 'networkSpeed',
      desc: '',
      args: [],
    );
  }

  /// `Outbound mode`
  String get outboundMode {
    return Intl.message(
      'Outbound mode',
      name: 'outboundMode',
      desc: '',
      args: [],
    );
  }

  /// `Network detection`
  String get networkDetection {
    return Intl.message(
      'Network detection',
      name: 'networkDetection',
      desc: '',
      args: [],
    );
  }

  /// `Upload`
  String get upload {
    return Intl.message('Upload', name: 'upload', desc: '', args: []);
  }

  /// `Download`
  String get download {
    return Intl.message('Download', name: 'download', desc: '', args: []);
  }

  /// `No profile, Please add a profile`
  String get nullProfileDesc {
    return Intl.message(
      'No profile, Please add a profile',
      name: 'nullProfileDesc',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Default`
  String get defaultText {
    return Intl.message('Default', name: 'defaultText', desc: '', args: []);
  }

  /// `More`
  String get more {
    return Intl.message('More', name: 'more', desc: '', args: []);
  }

  /// `Other`
  String get other {
    return Intl.message('Other', name: 'other', desc: '', args: []);
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }

  /// `English`
  String get en {
    return Intl.message('English', name: 'en', desc: '', args: []);
  }

  /// `Japanese`
  String get ja {
    return Intl.message('Japanese', name: 'ja', desc: '', args: []);
  }

  /// `Russian`
  String get ru {
    return Intl.message('Russian', name: 'ru', desc: '', args: []);
  }

  /// `Simplified Chinese`
  String get zh_CN {
    return Intl.message(
      'Simplified Chinese',
      name: 'zh_CN',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message('Theme', name: 'theme', desc: '', args: []);
  }

  /// `Set dark mode,adjust the color`
  String get themeDesc {
    return Intl.message(
      'Set dark mode,adjust the color',
      name: 'themeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Override`
  String get override {
    return Intl.message('Override', name: 'override', desc: '', args: []);
  }

  /// `AllowLan`
  String get allowLan {
    return Intl.message('AllowLan', name: 'allowLan', desc: '', args: []);
  }

  /// `Allow access proxy through the LAN`
  String get allowLanDesc {
    return Intl.message(
      'Allow access proxy through the LAN',
      name: 'allowLanDesc',
      desc: '',
      args: [],
    );
  }

  /// `TUN`
  String get tun {
    return Intl.message('TUN', name: 'tun', desc: '', args: []);
  }

  /// `only effective in administrator mode`
  String get tunDesc {
    return Intl.message(
      'only effective in administrator mode',
      name: 'tunDesc',
      desc: '',
      args: [],
    );
  }

  /// `Minimize on exit`
  String get minimizeOnExit {
    return Intl.message(
      'Minimize on exit',
      name: 'minimizeOnExit',
      desc: '',
      args: [],
    );
  }

  /// `Modify the default system exit event`
  String get minimizeOnExitDesc {
    return Intl.message(
      'Modify the default system exit event',
      name: 'minimizeOnExitDesc',
      desc: '',
      args: [],
    );
  }

  /// `Auto launch`
  String get autoLaunch {
    return Intl.message('Auto launch', name: 'autoLaunch', desc: '', args: []);
  }

  /// `Follow the system self startup`
  String get autoLaunchDesc {
    return Intl.message(
      'Follow the system self startup',
      name: 'autoLaunchDesc',
      desc: '',
      args: [],
    );
  }

  /// `SilentLaunch`
  String get silentLaunch {
    return Intl.message(
      'SilentLaunch',
      name: 'silentLaunch',
      desc: '',
      args: [],
    );
  }

  /// `Start in the background`
  String get silentLaunchDesc {
    return Intl.message(
      'Start in the background',
      name: 'silentLaunchDesc',
      desc: '',
      args: [],
    );
  }

  /// `AutoRun`
  String get autoRun {
    return Intl.message('AutoRun', name: 'autoRun', desc: '', args: []);
  }

  /// `Auto run when the application is opened`
  String get autoRunDesc {
    return Intl.message(
      'Auto run when the application is opened',
      name: 'autoRunDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logcat`
  String get logcat {
    return Intl.message('Logcat', name: 'logcat', desc: '', args: []);
  }

  /// `Disabling will hide the log entry`
  String get logcatDesc {
    return Intl.message(
      'Disabling will hide the log entry',
      name: 'logcatDesc',
      desc: '',
      args: [],
    );
  }

  /// `Auto check updates`
  String get autoCheckUpdate {
    return Intl.message(
      'Auto check updates',
      name: 'autoCheckUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Auto check for updates when the app starts`
  String get autoCheckUpdateDesc {
    return Intl.message(
      'Auto check for updates when the app starts',
      name: 'autoCheckUpdateDesc',
      desc: '',
      args: [],
    );
  }

  /// `AccessControl`
  String get accessControl {
    return Intl.message(
      'AccessControl',
      name: 'accessControl',
      desc: '',
      args: [],
    );
  }

  /// `Configure application access proxy`
  String get accessControlDesc {
    return Intl.message(
      'Configure application access proxy',
      name: 'accessControlDesc',
      desc: '',
      args: [],
    );
  }

  /// `Application`
  String get application {
    return Intl.message('Application', name: 'application', desc: '', args: []);
  }

  /// `Modify application related settings`
  String get applicationDesc {
    return Intl.message(
      'Modify application related settings',
      name: 'applicationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `Update`
  String get update {
    return Intl.message('Update', name: 'update', desc: '', args: []);
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Seconds`
  String get seconds {
    return Intl.message('Seconds', name: 'seconds', desc: '', args: []);
  }

  /// `QR code`
  String get qrcode {
    return Intl.message('QR code', name: 'qrcode', desc: '', args: []);
  }

  /// `Scan QR code to obtain profile`
  String get qrcodeDesc {
    return Intl.message(
      'Scan QR code to obtain profile',
      name: 'qrcodeDesc',
      desc: '',
      args: [],
    );
  }

  /// `URL`
  String get url {
    return Intl.message('URL', name: 'url', desc: '', args: []);
  }

  /// `Obtain profile through URL`
  String get urlDesc {
    return Intl.message(
      'Obtain profile through URL',
      name: 'urlDesc',
      desc: '',
      args: [],
    );
  }

  /// `File`
  String get file {
    return Intl.message('File', name: 'file', desc: '', args: []);
  }

  /// `Directly upload profile`
  String get fileDesc {
    return Intl.message(
      'Directly upload profile',
      name: 'fileDesc',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `Please input the profile name`
  String get profileNameNullValidationDesc {
    return Intl.message(
      'Please input the profile name',
      name: 'profileNameNullValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please input the profile URL`
  String get profileUrlNullValidationDesc {
    return Intl.message(
      'Please input the profile URL',
      name: 'profileUrlNullValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please input a valid profile URL`
  String get profileUrlInvalidValidationDesc {
    return Intl.message(
      'Please input a valid profile URL',
      name: 'profileUrlInvalidValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Auto update`
  String get autoUpdate {
    return Intl.message('Auto update', name: 'autoUpdate', desc: '', args: []);
  }

  /// `Auto update interval (minutes)`
  String get autoUpdateInterval {
    return Intl.message(
      'Auto update interval (minutes)',
      name: 'autoUpdateInterval',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the auto update interval time`
  String get profileAutoUpdateIntervalNullValidationDesc {
    return Intl.message(
      'Please enter the auto update interval time',
      name: 'profileAutoUpdateIntervalNullValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please input a valid interval time format`
  String get profileAutoUpdateIntervalInvalidValidationDesc {
    return Intl.message(
      'Please input a valid interval time format',
      name: 'profileAutoUpdateIntervalInvalidValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Theme mode`
  String get themeMode {
    return Intl.message('Theme mode', name: 'themeMode', desc: '', args: []);
  }

  /// `Theme color`
  String get themeColor {
    return Intl.message('Theme color', name: 'themeColor', desc: '', args: []);
  }

  /// `Preview`
  String get preview {
    return Intl.message('Preview', name: 'preview', desc: '', args: []);
  }

  /// `Auto`
  String get auto {
    return Intl.message('Auto', name: 'auto', desc: '', args: []);
  }

  /// `Light`
  String get light {
    return Intl.message('Light', name: 'light', desc: '', args: []);
  }

  /// `Dark`
  String get dark {
    return Intl.message('Dark', name: 'dark', desc: '', args: []);
  }

  /// `Import from URL`
  String get importFromURL {
    return Intl.message(
      'Import from URL',
      name: 'importFromURL',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Do you want to pass`
  String get doYouWantToPass {
    return Intl.message(
      'Do you want to pass',
      name: 'doYouWantToPass',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get create {
    return Intl.message('Create', name: 'create', desc: '', args: []);
  }

  /// `Please upload a valid QR code`
  String get pleaseUploadValidQrcode {
    return Intl.message(
      'Please upload a valid QR code',
      name: 'pleaseUploadValidQrcode',
      desc: '',
      args: [],
    );
  }

  /// `Blacklist mode`
  String get blacklistMode {
    return Intl.message(
      'Blacklist mode',
      name: 'blacklistMode',
      desc: '',
      args: [],
    );
  }

  /// `Whitelist mode`
  String get whitelistMode {
    return Intl.message(
      'Whitelist mode',
      name: 'whitelistMode',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get selectAll {
    return Intl.message('Select all', name: 'selectAll', desc: '', args: []);
  }

  /// `Cancel select all`
  String get cancelSelectAll {
    return Intl.message(
      'Cancel select all',
      name: 'cancelSelectAll',
      desc: '',
      args: [],
    );
  }

  /// `App access control`
  String get appAccessControl {
    return Intl.message(
      'App access control',
      name: 'appAccessControl',
      desc: '',
      args: [],
    );
  }

  /// `Only allow selected app to enter VPN`
  String get accessControlAllowDesc {
    return Intl.message(
      'Only allow selected app to enter VPN',
      name: 'accessControlAllowDesc',
      desc: '',
      args: [],
    );
  }

  /// `The selected application will be excluded from VPN`
  String get accessControlNotAllowDesc {
    return Intl.message(
      'The selected application will be excluded from VPN',
      name: 'accessControlNotAllowDesc',
      desc: '',
      args: [],
    );
  }

  /// `Selected`
  String get selected {
    return Intl.message('Selected', name: 'selected', desc: '', args: []);
  }

  /// `ProxyPort`
  String get proxyPort {
    return Intl.message('ProxyPort', name: 'proxyPort', desc: '', args: []);
  }

  /// `Port`
  String get port {
    return Intl.message('Port', name: 'port', desc: '', args: []);
  }

  /// `LogLevel`
  String get logLevel {
    return Intl.message('LogLevel', name: 'logLevel', desc: '', args: []);
  }

  /// `Show`
  String get show {
    return Intl.message('Show', name: 'show', desc: '', args: []);
  }

  /// `Exit`
  String get exit {
    return Intl.message('Exit', name: 'exit', desc: '', args: []);
  }

  /// `System proxy`
  String get systemProxy {
    return Intl.message(
      'System proxy',
      name: 'systemProxy',
      desc: '',
      args: [],
    );
  }

  /// `Project`
  String get project {
    return Intl.message('Project', name: 'project', desc: '', args: []);
  }

  /// `Core`
  String get core {
    return Intl.message('Core', name: 'core', desc: '', args: []);
  }

  /// `Tab animation`
  String get tabAnimation {
    return Intl.message(
      'Tab animation',
      name: 'tabAnimation',
      desc: '',
      args: [],
    );
  }

  /// `A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.`
  String get desc {
    return Intl.message(
      'A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.',
      name: 'desc',
      desc: '',
      args: [],
    );
  }

  /// `Starting VPN...`
  String get startVpn {
    return Intl.message(
      'Starting VPN...',
      name: 'startVpn',
      desc: '',
      args: [],
    );
  }

  /// `Stopping VPN...`
  String get stopVpn {
    return Intl.message('Stopping VPN...', name: 'stopVpn', desc: '', args: []);
  }

  /// `Compatibility mode`
  String get compatible {
    return Intl.message(
      'Compatibility mode',
      name: 'compatible',
      desc: '',
      args: [],
    );
  }

  /// `The current proxy group cannot be selected.`
  String get notSelectedTip {
    return Intl.message(
      'The current proxy group cannot be selected.',
      name: 'notSelectedTip',
      desc: '',
      args: [],
    );
  }

  /// `tip`
  String get tip {
    return Intl.message('tip', name: 'tip', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Backup`
  String get backup {
    return Intl.message('Backup', name: 'backup', desc: '', args: []);
  }

  /// `Backup success`
  String get backupSuccess {
    return Intl.message(
      'Backup success',
      name: 'backupSuccess',
      desc: '',
      args: [],
    );
  }

  /// `No info`
  String get noInfo {
    return Intl.message('No info', name: 'noInfo', desc: '', args: []);
  }

  /// `Please bind WebDAV`
  String get pleaseBindWebDAV {
    return Intl.message(
      'Please bind WebDAV',
      name: 'pleaseBindWebDAV',
      desc: '',
      args: [],
    );
  }

  /// `Bind`
  String get bind {
    return Intl.message('Bind', name: 'bind', desc: '', args: []);
  }

  /// `Connectivity：`
  String get connectivity {
    return Intl.message(
      'Connectivity：',
      name: 'connectivity',
      desc: '',
      args: [],
    );
  }

  /// `WebDAV configuration`
  String get webDAVConfiguration {
    return Intl.message(
      'WebDAV configuration',
      name: 'webDAVConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `WebDAV server address`
  String get addressHelp {
    return Intl.message(
      'WebDAV server address',
      name: 'addressHelp',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid WebDAV address`
  String get addressTip {
    return Intl.message(
      'Please enter a valid WebDAV address',
      name: 'addressTip',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Check for updates`
  String get checkUpdate {
    return Intl.message(
      'Check for updates',
      name: 'checkUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Discover the new version`
  String get discoverNewVersion {
    return Intl.message(
      'Discover the new version',
      name: 'discoverNewVersion',
      desc: '',
      args: [],
    );
  }

  /// `The current application is already the latest version`
  String get checkUpdateError {
    return Intl.message(
      'The current application is already the latest version',
      name: 'checkUpdateError',
      desc: '',
      args: [],
    );
  }

  /// `Go to download`
  String get goDownload {
    return Intl.message(
      'Go to download',
      name: 'goDownload',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get unknown {
    return Intl.message('Unknown', name: 'unknown', desc: '', args: []);
  }

  /// `Country`
  String get country {
    return Intl.message('Country', name: 'country', desc: '', args: []);
  }

  /// `Search`
  String get search {
    return Intl.message('Search', name: 'search', desc: '', args: []);
  }

  /// `Allow applications to bypass VPN`
  String get allowBypass {
    return Intl.message(
      'Allow applications to bypass VPN',
      name: 'allowBypass',
      desc: '',
      args: [],
    );
  }

  /// `Some apps can bypass VPN when turned on`
  String get allowBypassDesc {
    return Intl.message(
      'Some apps can bypass VPN when turned on',
      name: 'allowBypassDesc',
      desc: '',
      args: [],
    );
  }

  /// `ExternalController`
  String get externalController {
    return Intl.message(
      'ExternalController',
      name: 'externalController',
      desc: '',
      args: [],
    );
  }

  /// `Once enabled, the Clash kernel can be controlled on port 9090`
  String get externalControllerDesc {
    return Intl.message(
      'Once enabled, the Clash kernel can be controlled on port 9090',
      name: 'externalControllerDesc',
      desc: '',
      args: [],
    );
  }

  /// `When turned on it will be able to receive IPv6 traffic`
  String get ipv6Desc {
    return Intl.message(
      'When turned on it will be able to receive IPv6 traffic',
      name: 'ipv6Desc',
      desc: '',
      args: [],
    );
  }

  /// `App`
  String get app {
    return Intl.message('App', name: 'app', desc: '', args: []);
  }

  /// `General`
  String get general {
    return Intl.message('General', name: 'general', desc: '', args: []);
  }

  /// `Attach HTTP proxy to VpnService`
  String get systemProxyDesc {
    return Intl.message(
      'Attach HTTP proxy to VpnService',
      name: 'systemProxyDesc',
      desc: '',
      args: [],
    );
  }

  /// `User-Agent`
  String get userAgent {
    return Intl.message('User-Agent', name: 'userAgent', desc: '', args: []);
  }

  /// `Unified delay`
  String get unifiedDelay {
    return Intl.message(
      'Unified delay',
      name: 'unifiedDelay',
      desc: '',
      args: [],
    );
  }

  /// `Remove extra delays such as handshaking`
  String get unifiedDelayDesc {
    return Intl.message(
      'Remove extra delays such as handshaking',
      name: 'unifiedDelayDesc',
      desc: '',
      args: [],
    );
  }

  /// `TCP concurrent`
  String get tcpConcurrent {
    return Intl.message(
      'TCP concurrent',
      name: 'tcpConcurrent',
      desc: '',
      args: [],
    );
  }

  /// `Enabling it will allow TCP concurrency`
  String get tcpConcurrentDesc {
    return Intl.message(
      'Enabling it will allow TCP concurrency',
      name: 'tcpConcurrentDesc',
      desc: '',
      args: [],
    );
  }

  /// `Geo Low Memory Mode`
  String get geodataLoader {
    return Intl.message(
      'Geo Low Memory Mode',
      name: 'geodataLoader',
      desc: '',
      args: [],
    );
  }

  /// `Enabling will use the Geo low memory loader`
  String get geodataLoaderDesc {
    return Intl.message(
      'Enabling will use the Geo low memory loader',
      name: 'geodataLoaderDesc',
      desc: '',
      args: [],
    );
  }

  /// `Requests`
  String get requests {
    return Intl.message('Requests', name: 'requests', desc: '', args: []);
  }

  /// `View recently request records`
  String get requestsDesc {
    return Intl.message(
      'View recently request records',
      name: 'requestsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Find process`
  String get findProcessMode {
    return Intl.message(
      'Find process',
      name: 'findProcessMode',
      desc: '',
      args: [],
    );
  }

  /// `Init`
  String get init {
    return Intl.message('Init', name: 'init', desc: '', args: []);
  }

  /// `Long term effective`
  String get infiniteTime {
    return Intl.message(
      'Long term effective',
      name: 'infiniteTime',
      desc: '',
      args: [],
    );
  }

  /// `Connections`
  String get connections {
    return Intl.message('Connections', name: 'connections', desc: '', args: []);
  }

  /// `View current connections data`
  String get connectionsDesc {
    return Intl.message(
      'View current connections data',
      name: 'connectionsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Intranet IP`
  String get intranetIP {
    return Intl.message('Intranet IP', name: 'intranetIP', desc: '', args: []);
  }

  /// `View`
  String get view {
    return Intl.message('View', name: 'view', desc: '', args: []);
  }

  /// `Cut`
  String get cut {
    return Intl.message('Cut', name: 'cut', desc: '', args: []);
  }

  /// `Copy`
  String get copy {
    return Intl.message('Copy', name: 'copy', desc: '', args: []);
  }

  /// `Paste`
  String get paste {
    return Intl.message('Paste', name: 'paste', desc: '', args: []);
  }

  /// `Test url`
  String get testUrl {
    return Intl.message('Test url', name: 'testUrl', desc: '', args: []);
  }

  /// `Sync`
  String get sync {
    return Intl.message('Sync', name: 'sync', desc: '', args: []);
  }

  /// `Hidden from recent tasks`
  String get exclude {
    return Intl.message(
      'Hidden from recent tasks',
      name: 'exclude',
      desc: '',
      args: [],
    );
  }

  /// `When the app is in the background, the app is hidden from the recent task`
  String get excludeDesc {
    return Intl.message(
      'When the app is in the background, the app is hidden from the recent task',
      name: 'excludeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Standard`
  String get expand {
    return Intl.message('Standard', name: 'expand', desc: '', args: []);
  }

  /// `Shrink`
  String get shrink {
    return Intl.message('Shrink', name: 'shrink', desc: '', args: []);
  }

  /// `Min`
  String get min {
    return Intl.message('Min', name: 'min', desc: '', args: []);
  }

  /// `Tab`
  String get tab {
    return Intl.message('Tab', name: 'tab', desc: '', args: []);
  }

  /// `List`
  String get list {
    return Intl.message('List', name: 'list', desc: '', args: []);
  }

  /// `Delay`
  String get delay {
    return Intl.message('Delay', name: 'delay', desc: '', args: []);
  }

  /// `Style`
  String get style {
    return Intl.message('Style', name: 'style', desc: '', args: []);
  }

  /// `Size`
  String get size {
    return Intl.message('Size', name: 'size', desc: '', args: []);
  }

  /// `Sort`
  String get sort {
    return Intl.message('Sort', name: 'sort', desc: '', args: []);
  }

  /// `Columns`
  String get columns {
    return Intl.message('Columns', name: 'columns', desc: '', args: []);
  }

  /// `Proxy group`
  String get proxyGroup {
    return Intl.message('Proxy group', name: 'proxyGroup', desc: '', args: []);
  }

  /// `Go`
  String get go {
    return Intl.message('Go', name: 'go', desc: '', args: []);
  }

  /// `External link`
  String get externalLink {
    return Intl.message(
      'External link',
      name: 'externalLink',
      desc: '',
      args: [],
    );
  }

  /// `Other contributors`
  String get otherContributors {
    return Intl.message(
      'Other contributors',
      name: 'otherContributors',
      desc: '',
      args: [],
    );
  }

  /// `Auto close connections`
  String get autoCloseConnections {
    return Intl.message(
      'Auto close connections',
      name: 'autoCloseConnections',
      desc: '',
      args: [],
    );
  }

  /// `Auto close connections after change node`
  String get autoCloseConnectionsDesc {
    return Intl.message(
      'Auto close connections after change node',
      name: 'autoCloseConnectionsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Only statistics proxy`
  String get onlyStatisticsProxy {
    return Intl.message(
      'Only statistics proxy',
      name: 'onlyStatisticsProxy',
      desc: '',
      args: [],
    );
  }

  /// `When turned on, only statistics proxy traffic`
  String get onlyStatisticsProxyDesc {
    return Intl.message(
      'When turned on, only statistics proxy traffic',
      name: 'onlyStatisticsProxyDesc',
      desc: '',
      args: [],
    );
  }

  /// `Pure black mode`
  String get pureBlackMode {
    return Intl.message(
      'Pure black mode',
      name: 'pureBlackMode',
      desc: '',
      args: [],
    );
  }

  /// `Tcp keep alive interval`
  String get keepAliveIntervalDesc {
    return Intl.message(
      'Tcp keep alive interval',
      name: 'keepAliveIntervalDesc',
      desc: '',
      args: [],
    );
  }

  /// ` entries`
  String get entries {
    return Intl.message(' entries', name: 'entries', desc: '', args: []);
  }

  /// `Local`
  String get local {
    return Intl.message('Local', name: 'local', desc: '', args: []);
  }

  /// `Remote`
  String get remote {
    return Intl.message('Remote', name: 'remote', desc: '', args: []);
  }

  /// `Backup local data to WebDAV`
  String get remoteBackupDesc {
    return Intl.message(
      'Backup local data to WebDAV',
      name: 'remoteBackupDesc',
      desc: '',
      args: [],
    );
  }

  /// `Backup local data to local`
  String get localBackupDesc {
    return Intl.message(
      'Backup local data to local',
      name: 'localBackupDesc',
      desc: '',
      args: [],
    );
  }

  /// `Mode`
  String get mode {
    return Intl.message('Mode', name: 'mode', desc: '', args: []);
  }

  /// `Time`
  String get time {
    return Intl.message('Time', name: 'time', desc: '', args: []);
  }

  /// `Source`
  String get source {
    return Intl.message('Source', name: 'source', desc: '', args: []);
  }

  /// `Action`
  String get action {
    return Intl.message('Action', name: 'action', desc: '', args: []);
  }

  /// `Intelligent selection`
  String get intelligentSelected {
    return Intl.message(
      'Intelligent selection',
      name: 'intelligentSelected',
      desc: '',
      args: [],
    );
  }

  /// `Clipboard import`
  String get clipboardImport {
    return Intl.message(
      'Clipboard import',
      name: 'clipboardImport',
      desc: '',
      args: [],
    );
  }

  /// `Export clipboard`
  String get clipboardExport {
    return Intl.message(
      'Export clipboard',
      name: 'clipboardExport',
      desc: '',
      args: [],
    );
  }

  /// `Layout`
  String get layout {
    return Intl.message('Layout', name: 'layout', desc: '', args: []);
  }

  /// `Tight`
  String get tight {
    return Intl.message('Tight', name: 'tight', desc: '', args: []);
  }

  /// `Standard`
  String get standard {
    return Intl.message('Standard', name: 'standard', desc: '', args: []);
  }

  /// `Loose`
  String get loose {
    return Intl.message('Loose', name: 'loose', desc: '', args: []);
  }

  /// `Profiles sort`
  String get profilesSort {
    return Intl.message(
      'Profiles sort',
      name: 'profilesSort',
      desc: '',
      args: [],
    );
  }

  /// `Start`
  String get start {
    return Intl.message('Start', name: 'start', desc: '', args: []);
  }

  /// `Stop`
  String get stop {
    return Intl.message('Stop', name: 'stop', desc: '', args: []);
  }

  /// `Update DNS related settings`
  String get dnsDesc {
    return Intl.message(
      'Update DNS related settings',
      name: 'dnsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Key`
  String get key {
    return Intl.message('Key', name: 'key', desc: '', args: []);
  }

  /// `Value`
  String get value {
    return Intl.message('Value', name: 'value', desc: '', args: []);
  }

  /// `Add Hosts`
  String get hostsDesc {
    return Intl.message('Add Hosts', name: 'hostsDesc', desc: '', args: []);
  }

  /// `Changes take effect after restarting the VPN`
  String get vpnTip {
    return Intl.message(
      'Changes take effect after restarting the VPN',
      name: 'vpnTip',
      desc: '',
      args: [],
    );
  }

  /// `Auto routes all system traffic through VpnService`
  String get vpnEnableDesc {
    return Intl.message(
      'Auto routes all system traffic through VpnService',
      name: 'vpnEnableDesc',
      desc: '',
      args: [],
    );
  }

  /// `Options`
  String get options {
    return Intl.message('Options', name: 'options', desc: '', args: []);
  }

  /// `Loopback unlock tool`
  String get loopback {
    return Intl.message(
      'Loopback unlock tool',
      name: 'loopback',
      desc: '',
      args: [],
    );
  }

  /// `Used for UWP loopback unlocking`
  String get loopbackDesc {
    return Intl.message(
      'Used for UWP loopback unlocking',
      name: 'loopbackDesc',
      desc: '',
      args: [],
    );
  }

  /// `Providers`
  String get providers {
    return Intl.message('Providers', name: 'providers', desc: '', args: []);
  }

  /// `Proxy providers`
  String get proxyProviders {
    return Intl.message(
      'Proxy providers',
      name: 'proxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `Rule providers`
  String get ruleProviders {
    return Intl.message(
      'Rule providers',
      name: 'ruleProviders',
      desc: '',
      args: [],
    );
  }

  /// `Override Dns`
  String get overrideDns {
    return Intl.message(
      'Override Dns',
      name: 'overrideDns',
      desc: '',
      args: [],
    );
  }

  /// `Turning it on will override the DNS options in the profile`
  String get overrideDnsDesc {
    return Intl.message(
      'Turning it on will override the DNS options in the profile',
      name: 'overrideDnsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message('Status', name: 'status', desc: '', args: []);
  }

  /// `System DNS will be used when turned off`
  String get statusDesc {
    return Intl.message(
      'System DNS will be used when turned off',
      name: 'statusDesc',
      desc: '',
      args: [],
    );
  }

  /// `Prioritize the use of DOH's http/3`
  String get preferH3Desc {
    return Intl.message(
      'Prioritize the use of DOH\'s http/3',
      name: 'preferH3Desc',
      desc: '',
      args: [],
    );
  }

  /// `Respect rules`
  String get respectRules {
    return Intl.message(
      'Respect rules',
      name: 'respectRules',
      desc: '',
      args: [],
    );
  }

  /// `DNS connection following rules, need to configure proxy-server-nameserver`
  String get respectRulesDesc {
    return Intl.message(
      'DNS connection following rules, need to configure proxy-server-nameserver',
      name: 'respectRulesDesc',
      desc: '',
      args: [],
    );
  }

  /// `DNS mode`
  String get dnsMode {
    return Intl.message('DNS mode', name: 'dnsMode', desc: '', args: []);
  }

  /// `Fakeip range`
  String get fakeipRange {
    return Intl.message(
      'Fakeip range',
      name: 'fakeipRange',
      desc: '',
      args: [],
    );
  }

  /// `Fakeip filter`
  String get fakeipFilter {
    return Intl.message(
      'Fakeip filter',
      name: 'fakeipFilter',
      desc: '',
      args: [],
    );
  }

  /// `Default nameserver`
  String get defaultNameserver {
    return Intl.message(
      'Default nameserver',
      name: 'defaultNameserver',
      desc: '',
      args: [],
    );
  }

  /// `For resolving DNS server`
  String get defaultNameserverDesc {
    return Intl.message(
      'For resolving DNS server',
      name: 'defaultNameserverDesc',
      desc: '',
      args: [],
    );
  }

  /// `Nameserver`
  String get nameserver {
    return Intl.message('Nameserver', name: 'nameserver', desc: '', args: []);
  }

  /// `For resolving domain`
  String get nameserverDesc {
    return Intl.message(
      'For resolving domain',
      name: 'nameserverDesc',
      desc: '',
      args: [],
    );
  }

  /// `Use hosts`
  String get useHosts {
    return Intl.message('Use hosts', name: 'useHosts', desc: '', args: []);
  }

  /// `Use system hosts`
  String get useSystemHosts {
    return Intl.message(
      'Use system hosts',
      name: 'useSystemHosts',
      desc: '',
      args: [],
    );
  }

  /// `Nameserver policy`
  String get nameserverPolicy {
    return Intl.message(
      'Nameserver policy',
      name: 'nameserverPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Specify the corresponding nameserver policy`
  String get nameserverPolicyDesc {
    return Intl.message(
      'Specify the corresponding nameserver policy',
      name: 'nameserverPolicyDesc',
      desc: '',
      args: [],
    );
  }

  /// `Proxy nameserver`
  String get proxyNameserver {
    return Intl.message(
      'Proxy nameserver',
      name: 'proxyNameserver',
      desc: '',
      args: [],
    );
  }

  /// `Domain for resolving proxy nodes`
  String get proxyNameserverDesc {
    return Intl.message(
      'Domain for resolving proxy nodes',
      name: 'proxyNameserverDesc',
      desc: '',
      args: [],
    );
  }

  /// `Fallback`
  String get fallback {
    return Intl.message('Fallback', name: 'fallback', desc: '', args: []);
  }

  /// `Generally use offshore DNS`
  String get fallbackDesc {
    return Intl.message(
      'Generally use offshore DNS',
      name: 'fallbackDesc',
      desc: '',
      args: [],
    );
  }

  /// `Fallback filter`
  String get fallbackFilter {
    return Intl.message(
      'Fallback filter',
      name: 'fallbackFilter',
      desc: '',
      args: [],
    );
  }

  /// `Geoip code`
  String get geoipCode {
    return Intl.message('Geoip code', name: 'geoipCode', desc: '', args: []);
  }

  /// `Ipcidr`
  String get ipcidr {
    return Intl.message('Ipcidr', name: 'ipcidr', desc: '', args: []);
  }

  /// `Domain`
  String get domain {
    return Intl.message('Domain', name: 'domain', desc: '', args: []);
  }

  /// `Reset`
  String get reset {
    return Intl.message('Reset', name: 'reset', desc: '', args: []);
  }

  /// `Show/Hide`
  String get action_view {
    return Intl.message('Show/Hide', name: 'action_view', desc: '', args: []);
  }

  /// `Start/Stop`
  String get action_start {
    return Intl.message('Start/Stop', name: 'action_start', desc: '', args: []);
  }

  /// `Switch mode`
  String get action_mode {
    return Intl.message('Switch mode', name: 'action_mode', desc: '', args: []);
  }

  /// `System proxy`
  String get action_proxy {
    return Intl.message(
      'System proxy',
      name: 'action_proxy',
      desc: '',
      args: [],
    );
  }

  /// `TUN`
  String get action_tun {
    return Intl.message('TUN', name: 'action_tun', desc: '', args: []);
  }

  /// `Disclaimer`
  String get disclaimer {
    return Intl.message('Disclaimer', name: 'disclaimer', desc: '', args: []);
  }

  /// `This software is only used for non-commercial purposes such as learning exchanges and scientific research. It is strictly prohibited to use this software for commercial purposes. Any commercial activity, if any, has nothing to do with this software.`
  String get disclaimerDesc {
    return Intl.message(
      'This software is only used for non-commercial purposes such as learning exchanges and scientific research. It is strictly prohibited to use this software for commercial purposes. Any commercial activity, if any, has nothing to do with this software.',
      name: 'disclaimerDesc',
      desc: '',
      args: [],
    );
  }

  /// `Agree`
  String get agree {
    return Intl.message('Agree', name: 'agree', desc: '', args: []);
  }

  /// `Hotkey Management`
  String get hotkeyManagement {
    return Intl.message(
      'Hotkey Management',
      name: 'hotkeyManagement',
      desc: '',
      args: [],
    );
  }

  /// `Use keyboard to control applications`
  String get hotkeyManagementDesc {
    return Intl.message(
      'Use keyboard to control applications',
      name: 'hotkeyManagementDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please press the keyboard.`
  String get pressKeyboard {
    return Intl.message(
      'Please press the keyboard.',
      name: 'pressKeyboard',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the correct hotkey`
  String get inputCorrectHotkey {
    return Intl.message(
      'Please enter the correct hotkey',
      name: 'inputCorrectHotkey',
      desc: '',
      args: [],
    );
  }

  /// `Hotkey conflict`
  String get hotkeyConflict {
    return Intl.message(
      'Hotkey conflict',
      name: 'hotkeyConflict',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message('Remove', name: 'remove', desc: '', args: []);
  }

  /// `No HotKey`
  String get noHotKey {
    return Intl.message('No HotKey', name: 'noHotKey', desc: '', args: []);
  }

  /// `No network`
  String get noNetwork {
    return Intl.message('No network', name: 'noNetwork', desc: '', args: []);
  }

  /// `Allow IPv6 inbound`
  String get ipv6InboundDesc {
    return Intl.message(
      'Allow IPv6 inbound',
      name: 'ipv6InboundDesc',
      desc: '',
      args: [],
    );
  }

  /// `Export logs`
  String get exportLogs {
    return Intl.message('Export logs', name: 'exportLogs', desc: '', args: []);
  }

  /// `Export Success`
  String get exportSuccess {
    return Intl.message(
      'Export Success',
      name: 'exportSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Icon style`
  String get iconStyle {
    return Intl.message('Icon style', name: 'iconStyle', desc: '', args: []);
  }

  /// `Icon`
  String get onlyIcon {
    return Intl.message('Icon', name: 'onlyIcon', desc: '', args: []);
  }

  /// `Stack mode`
  String get stackMode {
    return Intl.message('Stack mode', name: 'stackMode', desc: '', args: []);
  }

  /// `Network`
  String get network {
    return Intl.message('Network', name: 'network', desc: '', args: []);
  }

  /// `Modify network-related settings`
  String get networkDesc {
    return Intl.message(
      'Modify network-related settings',
      name: 'networkDesc',
      desc: '',
      args: [],
    );
  }

  /// `Bypass domain`
  String get bypassDomain {
    return Intl.message(
      'Bypass domain',
      name: 'bypassDomain',
      desc: '',
      args: [],
    );
  }

  /// `Only takes effect when the system proxy is enabled`
  String get bypassDomainDesc {
    return Intl.message(
      'Only takes effect when the system proxy is enabled',
      name: 'bypassDomainDesc',
      desc: '',
      args: [],
    );
  }

  /// `Make sure to reset`
  String get resetTip {
    return Intl.message(
      'Make sure to reset',
      name: 'resetTip',
      desc: '',
      args: [],
    );
  }

  /// `Icon`
  String get icon {
    return Intl.message('Icon', name: 'icon', desc: '', args: []);
  }

  /// `No data`
  String get noData {
    return Intl.message('No data', name: 'noData', desc: '', args: []);
  }

  /// `FontFamily`
  String get fontFamily {
    return Intl.message('FontFamily', name: 'fontFamily', desc: '', args: []);
  }

  /// `Toggle`
  String get toggle {
    return Intl.message('Toggle', name: 'toggle', desc: '', args: []);
  }

  /// `System`
  String get system {
    return Intl.message('System', name: 'system', desc: '', args: []);
  }

  /// `Route mode`
  String get routeMode {
    return Intl.message('Route mode', name: 'routeMode', desc: '', args: []);
  }

  /// `Bypass private route address`
  String get routeMode_bypassPrivate {
    return Intl.message(
      'Bypass private route address',
      name: 'routeMode_bypassPrivate',
      desc: '',
      args: [],
    );
  }

  /// `Use config`
  String get routeMode_config {
    return Intl.message(
      'Use config',
      name: 'routeMode_config',
      desc: '',
      args: [],
    );
  }

  /// `Route address`
  String get routeAddress {
    return Intl.message(
      'Route address',
      name: 'routeAddress',
      desc: '',
      args: [],
    );
  }

  /// `Config listen route address`
  String get routeAddressDesc {
    return Intl.message(
      'Config listen route address',
      name: 'routeAddressDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the admin password`
  String get pleaseInputAdminPassword {
    return Intl.message(
      'Please enter the admin password',
      name: 'pleaseInputAdminPassword',
      desc: '',
      args: [],
    );
  }

  /// `Copying environment variables`
  String get copyEnvVar {
    return Intl.message(
      'Copying environment variables',
      name: 'copyEnvVar',
      desc: '',
      args: [],
    );
  }

  /// `Memory info`
  String get memoryInfo {
    return Intl.message('Memory info', name: 'memoryInfo', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `The file has been modified. Do you want to save the changes?`
  String get fileIsUpdate {
    return Intl.message(
      'The file has been modified. Do you want to save the changes?',
      name: 'fileIsUpdate',
      desc: '',
      args: [],
    );
  }

  /// `The profile has been modified. Do you want to disable auto update?`
  String get profileHasUpdate {
    return Intl.message(
      'The profile has been modified. Do you want to disable auto update?',
      name: 'profileHasUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to cache the changes?`
  String get hasCacheChange {
    return Intl.message(
      'Do you want to cache the changes?',
      name: 'hasCacheChange',
      desc: '',
      args: [],
    );
  }

  /// `Copy success`
  String get copySuccess {
    return Intl.message(
      'Copy success',
      name: 'copySuccess',
      desc: '',
      args: [],
    );
  }

  /// `Copy link`
  String get copyLink {
    return Intl.message('Copy link', name: 'copyLink', desc: '', args: []);
  }

  /// `Export file`
  String get exportFile {
    return Intl.message('Export file', name: 'exportFile', desc: '', args: []);
  }

  /// `The cache is corrupt. Do you want to clear it?`
  String get cacheCorrupt {
    return Intl.message(
      'The cache is corrupt. Do you want to clear it?',
      name: 'cacheCorrupt',
      desc: '',
      args: [],
    );
  }

  /// `Relying on third-party api is for reference only`
  String get detectionTip {
    return Intl.message(
      'Relying on third-party api is for reference only',
      name: 'detectionTip',
      desc: '',
      args: [],
    );
  }

  /// `Listen`
  String get listen {
    return Intl.message('Listen', name: 'listen', desc: '', args: []);
  }

  /// `undo`
  String get undo {
    return Intl.message('undo', name: 'undo', desc: '', args: []);
  }

  /// `redo`
  String get redo {
    return Intl.message('redo', name: 'redo', desc: '', args: []);
  }

  /// `none`
  String get none {
    return Intl.message('none', name: 'none', desc: '', args: []);
  }

  /// `Basic configuration`
  String get basicConfig {
    return Intl.message(
      'Basic configuration',
      name: 'basicConfig',
      desc: '',
      args: [],
    );
  }

  /// `Modify the basic configuration globally`
  String get basicConfigDesc {
    return Intl.message(
      'Modify the basic configuration globally',
      name: 'basicConfigDesc',
      desc: '',
      args: [],
    );
  }

  /// `Advanced configuration`
  String get advancedConfig {
    return Intl.message(
      'Advanced configuration',
      name: 'advancedConfig',
      desc: '',
      args: [],
    );
  }

  /// `Provide diverse configuration options`
  String get advancedConfigDesc {
    return Intl.message(
      'Provide diverse configuration options',
      name: 'advancedConfigDesc',
      desc: '',
      args: [],
    );
  }

  /// `{count} items have been selected`
  String selectedCountTitle(Object count) {
    return Intl.message(
      '$count items have been selected',
      name: 'selectedCountTitle',
      desc: '',
      args: [count],
    );
  }

  /// `Add rule`
  String get addRule {
    return Intl.message('Add rule', name: 'addRule', desc: '', args: []);
  }

  /// `Rule name`
  String get ruleName {
    return Intl.message('Rule name', name: 'ruleName', desc: '', args: []);
  }

  /// `Content`
  String get content {
    return Intl.message('Content', name: 'content', desc: '', args: []);
  }

  /// `Sub rule`
  String get subRule {
    return Intl.message('Sub rule', name: 'subRule', desc: '', args: []);
  }

  /// `Rule target`
  String get ruleTarget {
    return Intl.message('Rule target', name: 'ruleTarget', desc: '', args: []);
  }

  /// `Source IP`
  String get sourceIp {
    return Intl.message('Source IP', name: 'sourceIp', desc: '', args: []);
  }

  /// `No resolve IP`
  String get noResolve {
    return Intl.message('No resolve IP', name: 'noResolve', desc: '', args: []);
  }

  /// `Do you want to save the changes?`
  String get saveChanges {
    return Intl.message(
      'Do you want to save the changes?',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `There is a certain performance loss after opening`
  String get findProcessModeDesc {
    return Intl.message(
      'There is a certain performance loss after opening',
      name: 'findProcessModeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Effective only in mobile view`
  String get tabAnimationDesc {
    return Intl.message(
      'Effective only in mobile view',
      name: 'tabAnimationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Color schemes`
  String get colorSchemes {
    return Intl.message(
      'Color schemes',
      name: 'colorSchemes',
      desc: '',
      args: [],
    );
  }

  /// `Palette`
  String get palette {
    return Intl.message('Palette', name: 'palette', desc: '', args: []);
  }

  /// `TonalSpot`
  String get tonalSpotScheme {
    return Intl.message(
      'TonalSpot',
      name: 'tonalSpotScheme',
      desc: '',
      args: [],
    );
  }

  /// `Fidelity`
  String get fidelityScheme {
    return Intl.message('Fidelity', name: 'fidelityScheme', desc: '', args: []);
  }

  /// `Monochrome`
  String get monochromeScheme {
    return Intl.message(
      'Monochrome',
      name: 'monochromeScheme',
      desc: '',
      args: [],
    );
  }

  /// `Neutral`
  String get neutralScheme {
    return Intl.message('Neutral', name: 'neutralScheme', desc: '', args: []);
  }

  /// `Vibrant`
  String get vibrantScheme {
    return Intl.message('Vibrant', name: 'vibrantScheme', desc: '', args: []);
  }

  /// `Expressive`
  String get expressiveScheme {
    return Intl.message(
      'Expressive',
      name: 'expressiveScheme',
      desc: '',
      args: [],
    );
  }

  /// `Content`
  String get contentScheme {
    return Intl.message('Content', name: 'contentScheme', desc: '', args: []);
  }

  /// `Rainbow`
  String get rainbowScheme {
    return Intl.message('Rainbow', name: 'rainbowScheme', desc: '', args: []);
  }

  /// `FruitSalad`
  String get fruitSaladScheme {
    return Intl.message(
      'FruitSalad',
      name: 'fruitSaladScheme',
      desc: '',
      args: [],
    );
  }

  /// `Developer mode`
  String get developerMode {
    return Intl.message(
      'Developer mode',
      name: 'developerMode',
      desc: '',
      args: [],
    );
  }

  /// `Developer mode is enabled.`
  String get developerModeEnableTip {
    return Intl.message(
      'Developer mode is enabled.',
      name: 'developerModeEnableTip',
      desc: '',
      args: [],
    );
  }

  /// `Message test`
  String get messageTest {
    return Intl.message(
      'Message test',
      name: 'messageTest',
      desc: '',
      args: [],
    );
  }

  /// `This is a message.`
  String get messageTestTip {
    return Intl.message(
      'This is a message.',
      name: 'messageTestTip',
      desc: '',
      args: [],
    );
  }

  /// `Crash test`
  String get crashTest {
    return Intl.message('Crash test', name: 'crashTest', desc: '', args: []);
  }

  /// `Clear Data`
  String get clearData {
    return Intl.message('Clear Data', name: 'clearData', desc: '', args: []);
  }

  /// `Text Scaling`
  String get textScale {
    return Intl.message('Text Scaling', name: 'textScale', desc: '', args: []);
  }

  /// `Internet`
  String get internet {
    return Intl.message('Internet', name: 'internet', desc: '', args: []);
  }

  /// `System APP`
  String get systemApp {
    return Intl.message('System APP', name: 'systemApp', desc: '', args: []);
  }

  /// `No network APP`
  String get noNetworkApp {
    return Intl.message(
      'No network APP',
      name: 'noNetworkApp',
      desc: '',
      args: [],
    );
  }

  /// `Restore strategy`
  String get restoreStrategy {
    return Intl.message(
      'Restore strategy',
      name: 'restoreStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Override`
  String get restoreStrategy_override {
    return Intl.message(
      'Override',
      name: 'restoreStrategy_override',
      desc: '',
      args: [],
    );
  }

  /// `Compatible`
  String get restoreStrategy_compatible {
    return Intl.message(
      'Compatible',
      name: 'restoreStrategy_compatible',
      desc: '',
      args: [],
    );
  }

  /// `Logs test`
  String get logsTest {
    return Intl.message('Logs test', name: 'logsTest', desc: '', args: []);
  }

  /// `{label} cannot be empty`
  String emptyTip(Object label) {
    return Intl.message(
      '$label cannot be empty',
      name: 'emptyTip',
      desc: '',
      args: [label],
    );
  }

  /// `{label} must be a url`
  String urlTip(Object label) {
    return Intl.message(
      '$label must be a url',
      name: 'urlTip',
      desc: '',
      args: [label],
    );
  }

  /// `{label} must be a number`
  String numberTip(Object label) {
    return Intl.message(
      '$label must be a number',
      name: 'numberTip',
      desc: '',
      args: [label],
    );
  }

  /// `Interval`
  String get interval {
    return Intl.message('Interval', name: 'interval', desc: '', args: []);
  }

  /// `Current {label} already exists`
  String existsTip(Object label) {
    return Intl.message(
      'Current $label already exists',
      name: 'existsTip',
      desc: '',
      args: [label],
    );
  }

  /// `Are you sure you want to delete the current {label}?`
  String deleteTip(Object label) {
    return Intl.message(
      'Are you sure you want to delete the current $label?',
      name: 'deleteTip',
      desc: '',
      args: [label],
    );
  }

  /// `Are you sure you want to delete the selected {label}?`
  String deleteMultipTip(Object label) {
    return Intl.message(
      'Are you sure you want to delete the selected $label?',
      name: 'deleteMultipTip',
      desc: '',
      args: [label],
    );
  }

  /// `No {label} yet`
  String nullTip(Object label) {
    return Intl.message(
      'No $label yet',
      name: 'nullTip',
      desc: '',
      args: [label],
    );
  }

  /// `Script`
  String get script {
    return Intl.message('Script', name: 'script', desc: '', args: []);
  }

  /// `Color`
  String get color {
    return Intl.message('Color', name: 'color', desc: '', args: []);
  }

  /// `Rename`
  String get rename {
    return Intl.message('Rename', name: 'rename', desc: '', args: []);
  }

  /// `Unnamed`
  String get unnamed {
    return Intl.message('Unnamed', name: 'unnamed', desc: '', args: []);
  }

  /// `Please enter a script name`
  String get pleaseEnterScriptName {
    return Intl.message(
      'Please enter a script name',
      name: 'pleaseEnterScriptName',
      desc: '',
      args: [],
    );
  }

  /// `Mixed Port`
  String get mixedPort {
    return Intl.message('Mixed Port', name: 'mixedPort', desc: '', args: []);
  }

  /// `Socks Port`
  String get socksPort {
    return Intl.message('Socks Port', name: 'socksPort', desc: '', args: []);
  }

  /// `Redir Port`
  String get redirPort {
    return Intl.message('Redir Port', name: 'redirPort', desc: '', args: []);
  }

  /// `Tproxy Port`
  String get tproxyPort {
    return Intl.message('Tproxy Port', name: 'tproxyPort', desc: '', args: []);
  }

  /// `{label} must be between 1024 and 49151`
  String portTip(Object label) {
    return Intl.message(
      '$label must be between 1024 and 49151',
      name: 'portTip',
      desc: '',
      args: [label],
    );
  }

  /// `Please enter a different port`
  String get portConflictTip {
    return Intl.message(
      'Please enter a different port',
      name: 'portConflictTip',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get import {
    return Intl.message('Import', name: 'import', desc: '', args: []);
  }

  /// `Import from file`
  String get importFile {
    return Intl.message(
      'Import from file',
      name: 'importFile',
      desc: '',
      args: [],
    );
  }

  /// `Import from URL`
  String get importUrl {
    return Intl.message(
      'Import from URL',
      name: 'importUrl',
      desc: '',
      args: [],
    );
  }

  /// `Auto set system DNS`
  String get autoSetSystemDns {
    return Intl.message(
      'Auto set system DNS',
      name: 'autoSetSystemDns',
      desc: '',
      args: [],
    );
  }

  /// `Pin DNS queries to the current proxy to keep them off your local ISP. Falls back to compatible mode when the node cannot be statically verified.`
  String get autoSetSystemDnsDesc {
    return Intl.message(
      'Pin DNS queries to the current proxy to keep them off your local ISP. Falls back to compatible mode when the node cannot be statically verified.',
      name: 'autoSetSystemDnsDesc',
      desc: '',
      args: [],
    );
  }

  /// `{label} details`
  String details(Object label) {
    return Intl.message(
      '$label details',
      name: 'details',
      desc: '',
      args: [label],
    );
  }

  /// `Creation time`
  String get creationTime {
    return Intl.message(
      'Creation time',
      name: 'creationTime',
      desc: '',
      args: [],
    );
  }

  /// `Process`
  String get process {
    return Intl.message('Process', name: 'process', desc: '', args: []);
  }

  /// `Host`
  String get host {
    return Intl.message('Host', name: 'host', desc: '', args: []);
  }

  /// `Destination`
  String get destination {
    return Intl.message('Destination', name: 'destination', desc: '', args: []);
  }

  /// `Destination GeoIP`
  String get destinationGeoIP {
    return Intl.message(
      'Destination GeoIP',
      name: 'destinationGeoIP',
      desc: '',
      args: [],
    );
  }

  /// `Destination IPASN`
  String get destinationIPASN {
    return Intl.message(
      'Destination IPASN',
      name: 'destinationIPASN',
      desc: '',
      args: [],
    );
  }

  /// `Special proxy`
  String get specialProxy {
    return Intl.message(
      'Special proxy',
      name: 'specialProxy',
      desc: '',
      args: [],
    );
  }

  /// `special rules`
  String get specialRules {
    return Intl.message(
      'special rules',
      name: 'specialRules',
      desc: '',
      args: [],
    );
  }

  /// `Remote destination`
  String get remoteDestination {
    return Intl.message(
      'Remote destination',
      name: 'remoteDestination',
      desc: '',
      args: [],
    );
  }

  /// `Network type`
  String get networkType {
    return Intl.message(
      'Network type',
      name: 'networkType',
      desc: '',
      args: [],
    );
  }

  /// `Proxy chains`
  String get proxyChains {
    return Intl.message(
      'Proxy chains',
      name: 'proxyChains',
      desc: '',
      args: [],
    );
  }

  /// `Log`
  String get log {
    return Intl.message('Log', name: 'log', desc: '', args: []);
  }

  /// `Connection`
  String get connection {
    return Intl.message('Connection', name: 'connection', desc: '', args: []);
  }

  /// `Request`
  String get request {
    return Intl.message('Request', name: 'request', desc: '', args: []);
  }

  /// `Connected`
  String get connected {
    return Intl.message('Connected', name: 'connected', desc: '', args: []);
  }

  /// `Disconnected`
  String get disconnected {
    return Intl.message(
      'Disconnected',
      name: 'disconnected',
      desc: '',
      args: [],
    );
  }

  /// `Connecting...`
  String get connecting {
    return Intl.message(
      'Connecting...',
      name: 'connecting',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to restart the core?`
  String get restartCoreTip {
    return Intl.message(
      'Are you sure you want to restart the core?',
      name: 'restartCoreTip',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to force restart the core?`
  String get forceRestartCoreTip {
    return Intl.message(
      'Are you sure you want to force restart the core?',
      name: 'forceRestartCoreTip',
      desc: '',
      args: [],
    );
  }

  /// `DNS hijacking`
  String get dnsHijacking {
    return Intl.message(
      'DNS hijacking',
      name: 'dnsHijacking',
      desc: '',
      args: [],
    );
  }

  /// `Core status`
  String get coreStatus {
    return Intl.message('Core status', name: 'coreStatus', desc: '', args: []);
  }

  /// `Data Collection Notice`
  String get dataCollectionTip {
    return Intl.message(
      'Data Collection Notice',
      name: 'dataCollectionTip',
      desc: '',
      args: [],
    );
  }

  /// `This app uses Firebase Crashlytics to collect crash information to improve app stability.\nThe collected data includes device information and crash details, but does not contain personal sensitive data.\nYou can disable this feature in settings.`
  String get dataCollectionContent {
    return Intl.message(
      'This app uses Firebase Crashlytics to collect crash information to improve app stability.\nThe collected data includes device information and crash details, but does not contain personal sensitive data.\nYou can disable this feature in settings.',
      name: 'dataCollectionContent',
      desc: '',
      args: [],
    );
  }

  /// `Crash Analysis`
  String get crashlytics {
    return Intl.message(
      'Crash Analysis',
      name: 'crashlytics',
      desc: '',
      args: [],
    );
  }

  /// `When enabled, automatically uploads crash logs without sensitive information when the app crashes`
  String get crashlyticsTip {
    return Intl.message(
      'When enabled, automatically uploads crash logs without sensitive information when the app crashes',
      name: 'crashlyticsTip',
      desc: '',
      args: [],
    );
  }

  /// `Append System DNS`
  String get appendSystemDns {
    return Intl.message(
      'Append System DNS',
      name: 'appendSystemDns',
      desc: '',
      args: [],
    );
  }

  /// `Forcefully append system DNS to the configuration`
  String get appendSystemDnsTip {
    return Intl.message(
      'Forcefully append system DNS to the configuration',
      name: 'appendSystemDnsTip',
      desc: '',
      args: [],
    );
  }

  /// `Edit rule`
  String get editRule {
    return Intl.message('Edit rule', name: 'editRule', desc: '', args: []);
  }

  /// `Override mode`
  String get overrideMode {
    return Intl.message(
      'Override mode',
      name: 'overrideMode',
      desc: '',
      args: [],
    );
  }

  /// `Standard mode, override basic configuration, provide simple rule addition capability`
  String get standardModeDesc {
    return Intl.message(
      'Standard mode, override basic configuration, provide simple rule addition capability',
      name: 'standardModeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Script mode, use external extension scripts, provide one-click override configuration capability`
  String get scriptModeDesc {
    return Intl.message(
      'Script mode, use external extension scripts, provide one-click override configuration capability',
      name: 'scriptModeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Added rules`
  String get addedRules {
    return Intl.message('Added rules', name: 'addedRules', desc: '', args: []);
  }

  /// `Control global added rules`
  String get controlGlobalAddedRules {
    return Intl.message(
      'Control global added rules',
      name: 'controlGlobalAddedRules',
      desc: '',
      args: [],
    );
  }

  /// `Override script`
  String get overrideScript {
    return Intl.message(
      'Override script',
      name: 'overrideScript',
      desc: '',
      args: [],
    );
  }

  /// `Go to configure script`
  String get goToConfigureScript {
    return Intl.message(
      'Go to configure script',
      name: 'goToConfigureScript',
      desc: '',
      args: [],
    );
  }

  /// `Edit global rules`
  String get editGlobalRules {
    return Intl.message(
      'Edit global rules',
      name: 'editGlobalRules',
      desc: '',
      args: [],
    );
  }

  /// `External fetch`
  String get externalFetch {
    return Intl.message(
      'External fetch',
      name: 'externalFetch',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to force crash the core?`
  String get confirmForceCrashCore {
    return Intl.message(
      'Are you sure you want to force crash the core?',
      name: 'confirmForceCrashCore',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to clear all data?`
  String get confirmClearAllData {
    return Intl.message(
      'Are you sure you want to clear all data?',
      name: 'confirmClearAllData',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message('Loading...', name: 'loading', desc: '', args: []);
  }

  /// `Load test`
  String get loadTest {
    return Intl.message('Load test', name: 'loadTest', desc: '', args: []);
  }

  /// `{count, plural, =1{1 year ago} other{{count} years ago}}`
  String yearsAgo(num count) {
    return Intl.plural(
      count,
      one: '1 year ago',
      other: '$count years ago',
      name: 'yearsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 month ago} other{{count} months ago}}`
  String monthsAgo(num count) {
    return Intl.plural(
      count,
      one: '1 month ago',
      other: '$count months ago',
      name: 'monthsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 day ago} other{{count} days ago}}`
  String daysAgo(num count) {
    return Intl.plural(
      count,
      one: '1 day ago',
      other: '$count days ago',
      name: 'daysAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 hour ago} other{{count} hours ago}}`
  String hoursAgo(num count) {
    return Intl.plural(
      count,
      one: '1 hour ago',
      other: '$count hours ago',
      name: 'hoursAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 minute ago} other{{count} minutes ago}}`
  String minutesAgo(num count) {
    return Intl.plural(
      count,
      one: '1 minute ago',
      other: '$count minutes ago',
      name: 'minutesAgo',
      desc: '',
      args: [count],
    );
  }

  /// `Just now`
  String get justNow {
    return Intl.message('Just now', name: 'justNow', desc: '', args: []);
  }

  /// `Don't remind again`
  String get noLongerRemind {
    return Intl.message(
      'Don\'t remind again',
      name: 'noLongerRemind',
      desc: '',
      args: [],
    );
  }

  /// `Access Control Settings`
  String get accessControlSettings {
    return Intl.message(
      'Access Control Settings',
      name: 'accessControlSettings',
      desc: '',
      args: [],
    );
  }

  /// `Turn On`
  String get turnOn {
    return Intl.message('Turn On', name: 'turnOn', desc: '', args: []);
  }

  /// `Turn Off`
  String get turnOff {
    return Intl.message('Turn Off', name: 'turnOff', desc: '', args: []);
  }

  /// `VPN configuration change detected`
  String get vpnConfigChangeDetected {
    return Intl.message(
      'VPN configuration change detected',
      name: 'vpnConfigChangeDetected',
      desc: '',
      args: [],
    );
  }

  /// `Restart`
  String get restart {
    return Intl.message('Restart', name: 'restart', desc: '', args: []);
  }

  /// `Speed statistics`
  String get speedStatistics {
    return Intl.message(
      'Speed statistics',
      name: 'speedStatistics',
      desc: '',
      args: [],
    );
  }

  /// `The current page has changes. Are you sure you want to reset?`
  String get resetPageChangesTip {
    return Intl.message(
      'The current page has changes. Are you sure you want to reset?',
      name: 'resetPageChangesTip',
      desc: '',
      args: [],
    );
  }

  /// `Custom`
  String get overwriteTypeCustom {
    return Intl.message(
      'Custom',
      name: 'overwriteTypeCustom',
      desc: '',
      args: [],
    );
  }

  /// `Custom mode, fully customize proxy groups and rules`
  String get overwriteTypeCustomDesc {
    return Intl.message(
      'Custom mode, fully customize proxy groups and rules',
      name: 'overwriteTypeCustomDesc',
      desc: '',
      args: [],
    );
  }

  /// `Unknown network error`
  String get unknownNetworkError {
    return Intl.message(
      'Unknown network error',
      name: 'unknownNetworkError',
      desc: '',
      args: [],
    );
  }

  /// `Recovery exception`
  String get restoreException {
    return Intl.message(
      'Recovery exception',
      name: 'restoreException',
      desc: '',
      args: [],
    );
  }

  /// `Network exception, please check your connection and try again`
  String get networkException {
    return Intl.message(
      'Network exception, please check your connection and try again',
      name: 'networkException',
      desc: '',
      args: [],
    );
  }

  /// `Invalid backup file`
  String get invalidBackupFile {
    return Intl.message(
      'Invalid backup file',
      name: 'invalidBackupFile',
      desc: '',
      args: [],
    );
  }

  /// `Prune cache`
  String get pruneCache {
    return Intl.message('Prune cache', name: 'pruneCache', desc: '', args: []);
  }

  /// `Backup and Restore`
  String get backupAndRestore {
    return Intl.message(
      'Backup and Restore',
      name: 'backupAndRestore',
      desc: '',
      args: [],
    );
  }

  /// `Sync data via WebDAV or files`
  String get backupAndRestoreDesc {
    return Intl.message(
      'Sync data via WebDAV or files',
      name: 'backupAndRestoreDesc',
      desc: '',
      args: [],
    );
  }

  /// `Restore`
  String get restore {
    return Intl.message('Restore', name: 'restore', desc: '', args: []);
  }

  /// `Restore success`
  String get restoreSuccess {
    return Intl.message(
      'Restore success',
      name: 'restoreSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Restore data via WebDAV`
  String get restoreFromWebDAVDesc {
    return Intl.message(
      'Restore data via WebDAV',
      name: 'restoreFromWebDAVDesc',
      desc: '',
      args: [],
    );
  }

  /// `Restore data via file`
  String get restoreFromFileDesc {
    return Intl.message(
      'Restore data via file',
      name: 'restoreFromFileDesc',
      desc: '',
      args: [],
    );
  }

  /// `Restore configuration files only`
  String get restoreOnlyConfig {
    return Intl.message(
      'Restore configuration files only',
      name: 'restoreOnlyConfig',
      desc: '',
      args: [],
    );
  }

  /// `Restore all data`
  String get restoreAllData {
    return Intl.message(
      'Restore all data',
      name: 'restoreAllData',
      desc: '',
      args: [],
    );
  }

  /// `Add Profile`
  String get addProfile {
    return Intl.message('Add Profile', name: 'addProfile', desc: '', args: []);
  }

  /// `Delay Test`
  String get delayTest {
    return Intl.message('Delay Test', name: 'delayTest', desc: '', args: []);
  }

  /// `Proxy group is empty`
  String get proxyGroupEmpty {
    return Intl.message(
      'Proxy group is empty',
      name: 'proxyGroupEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy group name cannot be empty`
  String get proxyGroupNameEmpty {
    return Intl.message(
      'Proxy group name cannot be empty',
      name: 'proxyGroupNameEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy group name is duplicate`
  String get proxyGroupNameDuplicate {
    return Intl.message(
      'Proxy group name is duplicate',
      name: 'proxyGroupNameDuplicate',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to exit the current window?`
  String get confirmExitWindow {
    return Intl.message(
      'Are you sure you want to exit the current window?',
      name: 'confirmExitWindow',
      desc: '',
      args: [],
    );
  }

  /// `Data changes detected, do you want to save?`
  String get dataChangedSave {
    return Intl.message(
      'Data changes detected, do you want to save?',
      name: 'dataChangedSave',
      desc: '',
      args: [],
    );
  }

  /// `Select proxy providers`
  String get selectProxyProviders {
    return Intl.message(
      'Select proxy providers',
      name: 'selectProxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `Proxy filter`
  String get proxyFilter {
    return Intl.message(
      'Proxy filter',
      name: 'proxyFilter',
      desc: '',
      args: [],
    );
  }

  /// `Optional`
  String get optional {
    return Intl.message('Optional', name: 'optional', desc: '', args: []);
  }

  /// `Max failed times`
  String get maxFailedTimes {
    return Intl.message(
      'Max failed times',
      name: 'maxFailedTimes',
      desc: '',
      args: [],
    );
  }

  /// `Test interval`
  String get testInterval {
    return Intl.message(
      'Test interval',
      name: 'testInterval',
      desc: '',
      args: [],
    );
  }

  /// `Exclude proxy filter`
  String get excludeProxyFilter {
    return Intl.message(
      'Exclude proxy filter',
      name: 'excludeProxyFilter',
      desc: '',
      args: [],
    );
  }

  /// `Exclude type`
  String get excludeType {
    return Intl.message(
      'Exclude type',
      name: 'excludeType',
      desc: '',
      args: [],
    );
  }

  /// `Expected status`
  String get expectedStatus {
    return Intl.message(
      'Expected status',
      name: 'expectedStatus',
      desc: '',
      args: [],
    );
  }

  /// `Select proxies`
  String get selectProxies {
    return Intl.message(
      'Select proxies',
      name: 'selectProxies',
      desc: '',
      args: [],
    );
  }

  /// `Input proxy group name`
  String get inputProxyGroupName {
    return Intl.message(
      'Input proxy group name',
      name: 'inputProxyGroupName',
      desc: '',
      args: [],
    );
  }

  /// `Hide from list`
  String get hideFromList {
    return Intl.message(
      'Hide from list',
      name: 'hideFromList',
      desc: '',
      args: [],
    );
  }

  /// `Test when used`
  String get testWhenUsed {
    return Intl.message(
      'Test when used',
      name: 'testWhenUsed',
      desc: '',
      args: [],
    );
  }

  /// `Disable UDP`
  String get disableUDP {
    return Intl.message('Disable UDP', name: 'disableUDP', desc: '', args: []);
  }

  /// `Are you sure you want to delete the current proxy group?`
  String get confirmDeleteProxyGroup {
    return Intl.message(
      'Are you sure you want to delete the current proxy group?',
      name: 'confirmDeleteProxyGroup',
      desc: '',
      args: [],
    );
  }

  /// `Rule is empty`
  String get ruleEmpty {
    return Intl.message('Rule is empty', name: 'ruleEmpty', desc: '', args: []);
  }

  /// `Input rule content`
  String get inputRuleContent {
    return Intl.message(
      'Input rule content',
      name: 'inputRuleContent',
      desc: '',
      args: [],
    );
  }

  /// `Rule set`
  String get ruleSet {
    return Intl.message('Rule set', name: 'ruleSet', desc: '', args: []);
  }

  /// `Please select rule set`
  String get selectRuleSet {
    return Intl.message(
      'Please select rule set',
      name: 'selectRuleSet',
      desc: '',
      args: [],
    );
  }

  /// `Split strategy`
  String get splitStrategy {
    return Intl.message(
      'Split strategy',
      name: 'splitStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Please select split strategy`
  String get selectSplitStrategy {
    return Intl.message(
      'Please select split strategy',
      name: 'selectSplitStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Please select sub rule`
  String get selectSubRule {
    return Intl.message(
      'Please select sub rule',
      name: 'selectSubRule',
      desc: '',
      args: [],
    );
  }

  /// `No resolve hostname`
  String get noResolveHostname {
    return Intl.message(
      'No resolve hostname',
      name: 'noResolveHostname',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP`
  String get matchSourceIp {
    return Intl.message(
      'Match source IP',
      name: 'matchSourceIp',
      desc: '',
      args: [],
    );
  }

  /// `Basic info`
  String get basicInfo {
    return Intl.message('Basic info', name: 'basicInfo', desc: '', args: []);
  }

  /// `Additional parameters`
  String get additionalParameters {
    return Intl.message(
      'Additional parameters',
      name: 'additionalParameters',
      desc: '',
      args: [],
    );
  }

  /// `Proxy type`
  String get proxyType {
    return Intl.message('Proxy type', name: 'proxyType', desc: '', args: []);
  }

  /// `Basic strategy`
  String get basicStrategy {
    return Intl.message(
      'Basic strategy',
      name: 'basicStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Edit proxy`
  String get editProxy {
    return Intl.message('Edit proxy', name: 'editProxy', desc: '', args: []);
  }

  /// `Include all proxy providers`
  String get includeAllProxyProviders {
    return Intl.message(
      'Include all proxy providers',
      name: 'includeAllProxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `When enabled, it will override the imported proxy providers`
  String get includeAllProxyProvidersTip {
    return Intl.message(
      'When enabled, it will override the imported proxy providers',
      name: 'includeAllProxyProvidersTip',
      desc: '',
      args: [],
    );
  }

  /// `Add proxy providers`
  String get addProxyProviders {
    return Intl.message(
      'Add proxy providers',
      name: 'addProxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `Include all proxies`
  String get includeAllProxies {
    return Intl.message(
      'Include all proxies',
      name: 'includeAllProxies',
      desc: '',
      args: [],
    );
  }

  /// `Import all proxies not containing proxy groups, additional proxy groups can be added below`
  String get includeAllProxiesTip {
    return Intl.message(
      'Import all proxies not containing proxy groups, additional proxy groups can be added below',
      name: 'includeAllProxiesTip',
      desc: '',
      args: [],
    );
  }

  /// `Proxies is empty`
  String get proxiesEmpty {
    return Intl.message(
      'Proxies is empty',
      name: 'proxiesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Add proxies`
  String get addProxies {
    return Intl.message('Add proxies', name: 'addProxies', desc: '', args: []);
  }

  /// `Add proxy group`
  String get addProxyGroup {
    return Intl.message(
      'Add proxy group',
      name: 'addProxyGroup',
      desc: '',
      args: [],
    );
  }

  /// `Edit proxy group`
  String get editProxyGroup {
    return Intl.message(
      'Edit proxy group',
      name: 'editProxyGroup',
      desc: '',
      args: [],
    );
  }

  /// `Existing data will be overwritten after confirmation`
  String get confirmOverwriteTip {
    return Intl.message(
      'Existing data will be overwritten after confirmation',
      name: 'confirmOverwriteTip',
      desc: '',
      args: [],
    );
  }

  /// `Data detected in configuration`
  String get configDataDetected {
    return Intl.message(
      'Data detected in configuration',
      name: 'configDataDetected',
      desc: '',
      args: [],
    );
  }

  /// `Quick fill`
  String get quickFill {
    return Intl.message('Quick fill', name: 'quickFill', desc: '', args: []);
  }

  /// `Icon URL`
  String get iconUrl {
    return Intl.message('Icon URL', name: 'iconUrl', desc: '', args: []);
  }

  /// `Icon records`
  String get iconRecords {
    return Intl.message(
      'Icon records',
      name: 'iconRecords',
      desc: '',
      args: [],
    );
  }

  /// `No records`
  String get noRecords {
    return Intl.message('No records', name: 'noRecords', desc: '', args: []);
  }

  /// `Custom`
  String get custom {
    return Intl.message('Custom', name: 'custom', desc: '', args: []);
  }

  /// `Match full domain`
  String get ruleActionDomainDesc {
    return Intl.message(
      'Match full domain',
      name: 'ruleActionDomainDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match domain suffix`
  String get ruleActionDomainSuffixDesc {
    return Intl.message(
      'Match domain suffix',
      name: 'ruleActionDomainSuffixDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match domain keyword`
  String get ruleActionDomainKeywordDesc {
    return Intl.message(
      'Match domain keyword',
      name: 'ruleActionDomainKeywordDesc',
      desc: '',
      args: [],
    );
  }

  /// `Wildcard match, only supports * and ? wildcards`
  String get ruleActionDomainRegexDesc {
    return Intl.message(
      'Wildcard match, only supports * and ? wildcards',
      name: 'ruleActionDomainRegexDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match domains within Geosite`
  String get ruleActionGeositeDesc {
    return Intl.message(
      'Match domains within Geosite',
      name: 'ruleActionGeositeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP address range`
  String get ruleActionIpCidrDesc {
    return Intl.message(
      'Match IP address range',
      name: 'ruleActionIpCidrDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP address range, IP-CIDR6 is just an alias`
  String get ruleActionIpCidr6Desc {
    return Intl.message(
      'Match IP address range, IP-CIDR6 is just an alias',
      name: 'ruleActionIpCidr6Desc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP suffix range`
  String get ruleActionIpSuffixDesc {
    return Intl.message(
      'Match IP suffix range',
      name: 'ruleActionIpSuffixDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP's ASN`
  String get ruleActionIpAsnDesc {
    return Intl.message(
      'Match IP\'s ASN',
      name: 'ruleActionIpAsnDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP's country code`
  String get ruleActionGeoipDesc {
    return Intl.message(
      'Match IP\'s country code',
      name: 'ruleActionGeoipDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP's country code`
  String get ruleActionSrcGeoipDesc {
    return Intl.message(
      'Match source IP\'s country code',
      name: 'ruleActionSrcGeoipDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP's ASN`
  String get ruleActionSrcIpAsnDesc {
    return Intl.message(
      'Match source IP\'s ASN',
      name: 'ruleActionSrcIpAsnDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP address range`
  String get ruleActionSrcIpCidrDesc {
    return Intl.message(
      'Match source IP address range',
      name: 'ruleActionSrcIpCidrDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP suffix range`
  String get ruleActionSrcIpSuffixDesc {
    return Intl.message(
      'Match source IP suffix range',
      name: 'ruleActionSrcIpSuffixDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match request target port range`
  String get ruleActionDstPortDesc {
    return Intl.message(
      'Match request target port range',
      name: 'ruleActionDstPortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match request source port range`
  String get ruleActionSrcPortDesc {
    return Intl.message(
      'Match request source port range',
      name: 'ruleActionSrcPortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound port`
  String get ruleActionInPortDesc {
    return Intl.message(
      'Match inbound port',
      name: 'ruleActionInPortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound type`
  String get ruleActionInTypeDesc {
    return Intl.message(
      'Match inbound type',
      name: 'ruleActionInTypeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound username, supports multiple usernames separated by /`
  String get ruleActionInUserDesc {
    return Intl.message(
      'Match inbound username, supports multiple usernames separated by /',
      name: 'ruleActionInUserDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound name`
  String get ruleActionInNameDesc {
    return Intl.message(
      'Match inbound name',
      name: 'ruleActionInNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using full process path`
  String get ruleActionProcessPathDesc {
    return Intl.message(
      'Match using full process path',
      name: 'ruleActionProcessPathDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using process path regex`
  String get ruleActionProcessPathRegexDesc {
    return Intl.message(
      'Match using process path regex',
      name: 'ruleActionProcessPathRegexDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using process name, matches package name on Android`
  String get ruleActionProcessNameDesc {
    return Intl.message(
      'Match using process name, matches package name on Android',
      name: 'ruleActionProcessNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using process name regex, matches package name on Android`
  String get ruleActionProcessNameRegexDesc {
    return Intl.message(
      'Match using process name regex, matches package name on Android',
      name: 'ruleActionProcessNameRegexDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match Linux USER ID`
  String get ruleActionUidDesc {
    return Intl.message(
      'Match Linux USER ID',
      name: 'ruleActionUidDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match TCP or UDP`
  String get ruleActionNetworkDesc {
    return Intl.message(
      'Match TCP or UDP',
      name: 'ruleActionNetworkDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match DSCP mark (tproxy udp inbound only)`
  String get ruleActionDscpDesc {
    return Intl.message(
      'Match DSCP mark (tproxy udp inbound only)',
      name: 'ruleActionDscpDesc',
      desc: '',
      args: [],
    );
  }

  /// `Reference rule set, requires rule-providers configuration`
  String get ruleActionRuleSetDesc {
    return Intl.message(
      'Reference rule set, requires rule-providers configuration',
      name: 'ruleActionRuleSetDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logical rule AND`
  String get ruleActionAndDesc {
    return Intl.message(
      'Logical rule AND',
      name: 'ruleActionAndDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logical rule OR`
  String get ruleActionOrDesc {
    return Intl.message(
      'Logical rule OR',
      name: 'ruleActionOrDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logical rule NOT`
  String get ruleActionNotDesc {
    return Intl.message(
      'Logical rule NOT',
      name: 'ruleActionNotDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match to sub-rule, pay attention to the use of parentheses`
  String get ruleActionSubRuleDesc {
    return Intl.message(
      'Match to sub-rule, pay attention to the use of parentheses',
      name: 'ruleActionSubRuleDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match all requests, no conditions needed`
  String get ruleActionMatchDesc {
    return Intl.message(
      'Match all requests, no conditions needed',
      name: 'ruleActionMatchDesc',
      desc: '',
      args: [],
    );
  }

  /// `Sub rule is empty`
  String get subRuleEmpty {
    return Intl.message(
      'Sub rule is empty',
      name: 'subRuleEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy providers cannot be empty`
  String get proxyProvidersNotEmpty {
    return Intl.message(
      'Proxy providers cannot be empty',
      name: 'proxyProvidersNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Content cannot be empty`
  String get contentNotEmpty {
    return Intl.message(
      'Content cannot be empty',
      name: 'contentNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Sub rule cannot be empty`
  String get subRuleNotEmpty {
    return Intl.message(
      'Sub rule cannot be empty',
      name: 'subRuleNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Split strategy cannot be empty`
  String get splitStrategyNotEmpty {
    return Intl.message(
      'Split strategy cannot be empty',
      name: 'splitStrategyNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy providers is empty`
  String get proxyProvidersEmpty {
    return Intl.message(
      'Proxy providers is empty',
      name: 'proxyProvidersEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Timeout`
  String get timeout {
    return Intl.message('Timeout', name: 'timeout', desc: '', args: []);
  }

  /// `{subRule} is an invalid SUB_RULE`
  String invalidSubRule(Object subRule) {
    return Intl.message(
      '$subRule is an invalid SUB_RULE',
      name: 'invalidSubRule',
      desc: '',
      args: [subRule],
    );
  }

  /// `{target} is an invalid policy`
  String invalidPolicy(Object target) {
    return Intl.message(
      '$target is an invalid policy',
      name: 'invalidPolicy',
      desc: '',
      args: [target],
    );
  }

  /// `{providerName} is an invalid proxy provider`
  String invalidProxyProvider(Object providerName) {
    return Intl.message(
      '$providerName is an invalid proxy provider',
      name: 'invalidProxyProvider',
      desc: '',
      args: [providerName],
    );
  }

  /// `{proxyName} is an invalid proxy`
  String invalidProxy(Object proxyName) {
    return Intl.message(
      '$proxyName is an invalid proxy',
      name: 'invalidProxy',
      desc: '',
      args: [proxyName],
    );
  }

  /// `Detected current proxy group is abnormal`
  String get proxyGroupDetectedAbnormal {
    return Intl.message(
      'Detected current proxy group is abnormal',
      name: 'proxyGroupDetectedAbnormal',
      desc: '',
      args: [],
    );
  }

  /// `Detected selected proxy providers are abnormal`
  String get proxyProviderDetectedAbnormal {
    return Intl.message(
      'Detected selected proxy providers are abnormal',
      name: 'proxyProviderDetectedAbnormal',
      desc: '',
      args: [],
    );
  }

  /// `Detected selected proxies are abnormal`
  String get proxyDetectedAbnormal {
    return Intl.message(
      'Detected selected proxies are abnormal',
      name: 'proxyDetectedAbnormal',
      desc: '',
      args: [],
    );
  }

  /// `Create Profile`
  String get createProfile {
    return Intl.message(
      'Create Profile',
      name: 'createProfile',
      desc: '',
      args: [],
    );
  }

  /// `Location Permission Required`
  String get locationPermissionRequired {
    return Intl.message(
      'Location Permission Required',
      name: 'locationPermissionRequired',
      desc: '',
      args: [],
    );
  }

  /// `1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check {appName} in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.`
  String locationPermissionGuide(Object appName) {
    return Intl.message(
      '1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check $appName in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.',
      name: 'locationPermissionGuide',
      desc: '',
      args: [appName],
    );
  }

  /// `Prerequisites`
  String get prerequisites {
    return Intl.message(
      'Prerequisites',
      name: 'prerequisites',
      desc: '',
      args: [],
    );
  }

  /// `Ignore Battery Optimization`
  String get ignoreBatteryOptimization {
    return Intl.message(
      'Ignore Battery Optimization',
      name: 'ignoreBatteryOptimization',
      desc: '',
      args: [],
    );
  }

  /// `To ensure background operation, please disable battery optimization for this app. Tap to go to settings.`
  String get batteryOptimizationDesc {
    return Intl.message(
      'To ensure background operation, please disable battery optimization for this app. Tap to go to settings.',
      name: 'batteryOptimizationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Affected by the system, this status may not always be accurate.`
  String get batteryOptimizationStatusTip {
    return Intl.message(
      'Affected by the system, this status may not always be accurate.',
      name: 'batteryOptimizationStatusTip',
      desc: '',
      args: [],
    );
  }

  /// `Location Permission`
  String get locationPermission {
    return Intl.message(
      'Location Permission',
      name: 'locationPermission',
      desc: '',
      args: [],
    );
  }

  /// `According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.`
  String get locationPermissionDesc {
    return Intl.message(
      'According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.',
      name: 'locationPermissionDesc',
      desc: '',
      args: [],
    );
  }

  /// `Exclude SSIDs`
  String get excludeSsids {
    return Intl.message(
      'Exclude SSIDs',
      name: 'excludeSsids',
      desc: '',
      args: [],
    );
  }

  /// `When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.`
  String get excludeSsidsDesc {
    return Intl.message(
      'When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.',
      name: 'excludeSsidsDesc',
      desc: '',
      args: [],
    );
  }

  /// `SSIDs is empty`
  String get ssidsEmpty {
    return Intl.message(
      'SSIDs is empty',
      name: 'ssidsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `On Demand`
  String get onDemand {
    return Intl.message('On Demand', name: 'onDemand', desc: '', args: []);
  }

  /// `Configure the program running state for specific scenarios`
  String get onDemandDesc {
    return Intl.message(
      'Configure the program running state for specific scenarios',
      name: 'onDemandDesc',
      desc: '',
      args: [],
    );
  }

  /// `Location permission was denied, so the current Wi-Fi name cannot be obtained. Please open location permission manually in system settings.`
  String get locationPermissionDeniedMessage {
    return Intl.message(
      'Location permission was denied, so the current Wi-Fi name cannot be obtained. Please open location permission manually in system settings.',
      name: 'locationPermissionDeniedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Add SSID`
  String get addSsid {
    return Intl.message('Add SSID', name: 'addSsid', desc: '', args: []);
  }

  /// `Edit SSID`
  String get editSsid {
    return Intl.message('Edit SSID', name: 'editSsid', desc: '', args: []);
  }

  /// `Authorized`
  String get authorized {
    return Intl.message('Authorized', name: 'authorized', desc: '', args: []);
  }

  /// `Tap to authorize`
  String get tapToAuthorize {
    return Intl.message(
      'Tap to authorize',
      name: 'tapToAuthorize',
      desc: '',
      args: [],
    );
  }

  /// `Suspended...`
  String get suspended {
    return Intl.message('Suspended...', name: 'suspended', desc: '', args: []);
  }

  /// `Geo Options`
  String get geoOptions {
    return Intl.message('Geo Options', name: 'geoOptions', desc: '', args: []);
  }

  /// `Auto Update`
  String get geoAutoUpdate {
    return Intl.message(
      'Auto Update',
      name: 'geoAutoUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Auto Update Interval`
  String get geoAutoUpdateInterval {
    return Intl.message(
      'Auto Update Interval',
      name: 'geoAutoUpdateInterval',
      desc: '',
      args: [],
    );
  }

  /// `Auto update interval must be greater than 0`
  String get geoAutoUpdateIntervalTip {
    return Intl.message(
      'Auto update interval must be greater than 0',
      name: 'geoAutoUpdateIntervalTip',
      desc: '',
      args: [],
    );
  }

  /// `hours`
  String get hours {
    return Intl.message('hours', name: 'hours', desc: '', args: []);
  }

  /// `{count} hours`
  String hoursCount(Object count) {
    return Intl.message(
      '$count hours',
      name: 'hoursCount',
      desc: '',
      args: [count],
    );
  }

  /// `Geo Resources`
  String get geoResources {
    return Intl.message(
      'Geo Resources',
      name: 'geoResources',
      desc: '',
      args: [],
    );
  }

  /// `Updating {name}...`
  String geoUpdating(Object name) {
    return Intl.message(
      'Updating $name...',
      name: 'geoUpdating',
      desc: '',
      args: [name],
    );
  }

  /// `{name} skipped`
  String geoSkipped(Object name) {
    return Intl.message(
      '$name skipped',
      name: 'geoSkipped',
      desc: '',
      args: [name],
    );
  }

  /// `{name} updated`
  String geoUpdated(Object name) {
    return Intl.message(
      '$name updated',
      name: 'geoUpdated',
      desc: '',
      args: [name],
    );
  }

  /// `{count} seconds`
  String secondsCount(Object count) {
    return Intl.message(
      '$count seconds',
      name: 'secondsCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count} entries`
  String entriesCount(Object count) {
    return Intl.message(
      '$count entries',
      name: 'entriesCount',
      desc: '',
      args: [count],
    );
  }

  /// `DNS safety mode`
  String get dnsSafetyMode {
    return Intl.message(
      'DNS safety mode',
      name: 'dnsSafetyMode',
      desc: '',
      args: [],
    );
  }

  /// `Auto leak protection is on: DNS queries are pinned to the current node.`
  String get dnsAutoLeakProtectionActive {
    return Intl.message(
      'Auto leak protection is on: DNS queries are pinned to the current node.',
      name: 'dnsAutoLeakProtectionActive',
      desc: '',
      args: [],
    );
  }

  /// `Proxy-only requires a static all-proxy target and explicit IP-address bootstrap resolvers. Bootstrap is direct; this is not a DNS leak test.`
  String get dnsSafetyModeDesc {
    return Intl.message(
      'Proxy-only requires a static all-proxy target and explicit IP-address bootstrap resolvers. Bootstrap is direct; this is not a DNS leak test.',
      name: 'dnsSafetyModeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Compatible`
  String get dnsSafetyModeCompatible {
    return Intl.message(
      'Compatible',
      name: 'dnsSafetyModeCompatible',
      desc: '',
      args: [],
    );
  }

  /// `Proxy only`
  String get dnsSafetyModeProxyOnly {
    return Intl.message(
      'Proxy only',
      name: 'dnsSafetyModeProxyOnly',
      desc: '',
      args: [],
    );
  }

  /// `Custom`
  String get dnsSafetyModeCustom {
    return Intl.message(
      'Custom',
      name: 'dnsSafetyModeCustom',
      desc: '',
      args: [],
    );
  }

  /// `DNS proxy target`
  String get dnsProxyTarget {
    return Intl.message(
      'DNS proxy target',
      name: 'dnsProxyTarget',
      desc: '',
      args: [],
    );
  }

  /// `Use an existing static proxy or group without DIRECT, provider auto-inclusion or filtering. Ordinary and direct-traffic DNS use this target.`
  String get dnsProxyTargetDesc {
    return Intl.message(
      'Use an existing static proxy or group without DIRECT, provider auto-inclusion or filtering. Ordinary and direct-traffic DNS use this target.',
      name: 'dnsProxyTargetDesc',
      desc: '',
      args: [],
    );
  }

  /// `DNS safety check failed: {codes}`
  String dnsSafetyInvalidConfig(Object codes) {
    return Intl.message(
      'DNS safety check failed: $codes',
      name: 'dnsSafetyInvalidConfig',
      desc: '',
      args: [codes],
    );
  }

  /// `Active DNS paths`
  String get dnsDiagnosticTitle {
    return Intl.message(
      'Active DNS paths',
      name: 'dnsDiagnosticTitle',
      desc: '',
      args: [],
    );
  }

  /// `Inspect the configuration currently installed in the core; no DNS probes`
  String get dnsDiagnosticDescription {
    return Intl.message(
      'Inspect the configuration currently installed in the core; no DNS probes',
      name: 'dnsDiagnosticDescription',
      desc: '',
      args: [],
    );
  }

  /// `Refresh snapshot`
  String get dnsDiagnosticRefresh {
    return Intl.message(
      'Refresh snapshot',
      name: 'dnsDiagnosticRefresh',
      desc: '',
      args: [],
    );
  }

  /// `Configuration snapshot, not a DNS leak verdict`
  String get dnsDiagnosticScope {
    return Intl.message(
      'Configuration snapshot, not a DNS leak verdict',
      name: 'dnsDiagnosticScope',
      desc: '',
      args: [],
    );
  }

  /// `Shows the active core configuration, not pending settings. Routes are configured paths, not captured packets. Proxy groups may choose DIRECT. Application-owned DoH/DoT and traffic outside TUN need separate testing. DNS privacy is separate from IP reputation.`
  String get dnsDiagnosticLimitations {
    return Intl.message(
      'Shows the active core configuration, not pending settings. Routes are configured paths, not captured packets. Proxy groups may choose DIRECT. Application-owned DoH/DoT and traffic outside TUN need separate testing. DNS privacy is separate from IP reputation.',
      name: 'dnsDiagnosticLimitations',
      desc: '',
      args: [],
    );
  }

  /// `DNS diagnostic unavailable`
  String get dnsDiagnosticUnavailable {
    return Intl.message(
      'DNS diagnostic unavailable',
      name: 'dnsDiagnosticUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `No current result. Refresh to retry; an older core may not support this action.`
  String get dnsDiagnosticRetryHint {
    return Intl.message(
      'No current result. Refresh to retry; an older core may not support this action.',
      name: 'dnsDiagnosticRetryHint',
      desc: '',
      args: [],
    );
  }

  /// `Core not ready`
  String get dnsDiagnosticInactive {
    return Intl.message(
      'Core not ready',
      name: 'dnsDiagnosticInactive',
      desc: '',
      args: [],
    );
  }

  /// `Connect and initialize the core before reading its DNS configuration.`
  String get dnsDiagnosticInactiveHint {
    return Intl.message(
      'Connect and initialize the core before reading its DNS configuration.',
      name: 'dnsDiagnosticInactiveHint',
      desc: '',
      args: [],
    );
  }

  /// `Active configuration read`
  String get dnsDiagnosticReady {
    return Intl.message(
      'Active configuration read',
      name: 'dnsDiagnosticReady',
      desc: '',
      args: [],
    );
  }

  /// `Core DNS is disabled`
  String get dnsDiagnosticDisabled {
    return Intl.message(
      'Core DNS is disabled',
      name: 'dnsDiagnosticDisabled',
      desc: '',
      args: [],
    );
  }

  /// `No active DNS configuration`
  String get dnsDiagnosticNotConfigured {
    return Intl.message(
      'No active DNS configuration',
      name: 'dnsDiagnosticNotConfigured',
      desc: '',
      args: [],
    );
  }

  /// `Snapshot read at {time}`
  String dnsDiagnosticReadAt(Object time) {
    return Intl.message(
      'Snapshot read at $time',
      name: 'dnsDiagnosticReadAt',
      desc: '',
      args: [time],
    );
  }

  /// `Resolver inheritance`
  String get dnsDiagnosticInheritance {
    return Intl.message(
      'Resolver inheritance',
      name: 'dnsDiagnosticInheritance',
      desc: '',
      args: [],
    );
  }

  /// `Dedicated resolvers`
  String get dnsDiagnosticDedicated {
    return Intl.message(
      'Dedicated resolvers',
      name: 'dnsDiagnosticDedicated',
      desc: '',
      args: [],
    );
  }

  /// `Inherits ordinary resolvers`
  String get dnsDiagnosticInheritsMain {
    return Intl.message(
      'Inherits ordinary resolvers',
      name: 'dnsDiagnosticInheritsMain',
      desc: '',
      args: [],
    );
  }

  /// `Ordinary queries: main / fallback / policy`
  String get dnsDiagnosticOrdinary {
    return Intl.message(
      'Ordinary queries: main / fallback / policy',
      name: 'dnsDiagnosticOrdinary',
      desc: '',
      args: [],
    );
  }

  /// `Bootstrap: resolver / proxy hostnames`
  String get dnsDiagnosticBootstrap {
    return Intl.message(
      'Bootstrap: resolver / proxy hostnames',
      name: 'dnsDiagnosticBootstrap',
      desc: '',
      args: [],
    );
  }

  /// `Direct-traffic queries`
  String get dnsDiagnosticDirect {
    return Intl.message(
      'Direct-traffic queries',
      name: 'dnsDiagnosticDirect',
      desc: '',
      args: [],
    );
  }

  /// `Path warnings and limitations`
  String get dnsDiagnosticWarnings {
    return Intl.message(
      'Path warnings and limitations',
      name: 'dnsDiagnosticWarnings',
      desc: '',
      args: [],
    );
  }

  /// `No warning codes returned; this does not prove the absence of leaks.`
  String get dnsDiagnosticNoWarnings {
    return Intl.message(
      'No warning codes returned; this does not prove the absence of leaks.',
      name: 'dnsDiagnosticNoWarnings',
      desc: '',
      args: [],
    );
  }

  /// `No network endpoint`
  String get dnsDiagnosticNoEndpoint {
    return Intl.message(
      'No network endpoint',
      name: 'dnsDiagnosticNoEndpoint',
      desc: '',
      args: [],
    );
  }

  /// `Configured target: {target}`
  String dnsDiagnosticTarget(Object target) {
    return Intl.message(
      'Configured target: $target',
      name: 'dnsDiagnosticTarget',
      desc: '',
      args: [target],
    );
  }

  /// `Direct path`
  String get dnsDiagnosticPathDirect {
    return Intl.message(
      'Direct path',
      name: 'dnsDiagnosticPathDirect',
      desc: '',
      args: [],
    );
  }

  /// `Rules-routed; may select DIRECT`
  String get dnsDiagnosticPathRules {
    return Intl.message(
      'Rules-routed; may select DIRECT',
      name: 'dnsDiagnosticPathRules',
      desc: '',
      args: [],
    );
  }

  /// `Configured proxy path; not empirically verified`
  String get dnsDiagnosticPathProxy {
    return Intl.message(
      'Configured proxy path; not empirically verified',
      name: 'dnsDiagnosticPathProxy',
      desc: '',
      args: [],
    );
  }

  /// `Interface-bound direct path`
  String get dnsDiagnosticPathInterface {
    return Intl.message(
      'Interface-bound direct path',
      name: 'dnsDiagnosticPathInterface',
      desc: '',
      args: [],
    );
  }

  /// `Host system resolver`
  String get dnsDiagnosticPathSystem {
    return Intl.message(
      'Host system resolver',
      name: 'dnsDiagnosticPathSystem',
      desc: '',
      args: [],
    );
  }

  /// `Resolver obtained through DHCP`
  String get dnsDiagnosticPathDhcp {
    return Intl.message(
      'Resolver obtained through DHCP',
      name: 'dnsDiagnosticPathDhcp',
      desc: '',
      args: [],
    );
  }

  /// `Overlay resolver; not verified proxy-only`
  String get dnsDiagnosticPathOverlay {
    return Intl.message(
      'Overlay resolver; not verified proxy-only',
      name: 'dnsDiagnosticPathOverlay',
      desc: '',
      args: [],
    );
  }

  /// `Synthetic DNS response`
  String get dnsDiagnosticPathSynthetic {
    return Intl.message(
      'Synthetic DNS response',
      name: 'dnsDiagnosticPathSynthetic',
      desc: '',
      args: [],
    );
  }

  /// `Blocked by configured target`
  String get dnsDiagnosticPathBlocked {
    return Intl.message(
      'Blocked by configured target',
      name: 'dnsDiagnosticPathBlocked',
      desc: '',
      args: [],
    );
  }

  /// `System or DHCP resolver path is present.`
  String get dnsDiagnosticWarningHost {
    return Intl.message(
      'System or DHCP resolver path is present.',
      name: 'dnsDiagnosticWarningHost',
      desc: '',
      args: [],
    );
  }

  /// `DNS rules may select DIRECT; respecting rules is not proxy-only.`
  String get dnsDiagnosticWarningRules {
    return Intl.message(
      'DNS rules may select DIRECT; respecting rules is not proxy-only.',
      name: 'dnsDiagnosticWarningRules',
      desc: '',
      args: [],
    );
  }

  /// `Bootstrap DNS can query directly. Review the explicit bootstrap endpoints.`
  String get dnsDiagnosticWarningBootstrap {
    return Intl.message(
      'Bootstrap DNS can query directly. Review the explicit bootstrap endpoints.',
      name: 'dnsDiagnosticWarningBootstrap',
      desc: '',
      args: [],
    );
  }

  /// `An ordinary or direct-traffic resolver can query directly.`
  String get dnsDiagnosticWarningDirect {
    return Intl.message(
      'An ordinary or direct-traffic resolver can query directly.',
      name: 'dnsDiagnosticWarningDirect',
      desc: '',
      args: [],
    );
  }

  /// `A proxy or overlay is configured, but its actual egress has not been verified.`
  String get dnsDiagnosticWarningProxy {
    return Intl.message(
      'A proxy or overlay is configured, but its actual egress has not been verified.',
      name: 'dnsDiagnosticWarningProxy',
      desc: '',
      args: [],
    );
  }

  /// `An unknown or unverified path requires further inspection.`
  String get dnsDiagnosticWarningUnknown {
    return Intl.message(
      'An unknown or unverified path requires further inspection.',
      name: 'dnsDiagnosticWarningUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Node quality`
  String get nodeQualityTitle {
    return Intl.message(
      'Node quality',
      name: 'nodeQualityTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manual HTTPS checks through this node. Cloudflare measures reachability, egress IP and edge TTFB, not IP purity. Adapter DNS/bootstrap may still be direct. DIRECT tests your direct connection.`
  String get nodeQualityScope {
    return Intl.message(
      'Manual HTTPS checks through this node. Cloudflare measures reachability, egress IP and edge TTFB, not IP purity. Adapter DNS/bootstrap may still be direct. DIRECT tests your direct connection.',
      name: 'nodeQualityScope',
      desc: '',
      args: [],
    );
  }

  /// `Include IPPure risk check`
  String get nodeQualityOptIn {
    return Intl.message(
      'Include IPPure risk check',
      name: 'nodeQualityOptIn',
      desc: '',
      args: [],
    );
  }

  /// `Opt-in for this dialog only: IPPure receives the node's egress IP and request metadata. No account or proxy credentials are sent by QuanClash. Cloudflare receives its own probe. Nothing runs automatically.`
  String get nodeQualityPrivacy {
    return Intl.message(
      'Opt-in for this dialog only: IPPure receives the node\'s egress IP and request metadata. No account or proxy credentials are sent by QuanClash. Cloudflare receives its own probe. Nothing runs automatically.',
      name: 'nodeQualityPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `Check now`
  String get nodeQualityRun {
    return Intl.message(
      'Check now',
      name: 'nodeQualityRun',
      desc: '',
      args: [],
    );
  }

  /// `Probe succeeded`
  String get nodeQualityOk {
    return Intl.message(
      'Probe succeeded',
      name: 'nodeQualityOk',
      desc: '',
      args: [],
    );
  }

  /// `Unknown: check unavailable or failed. Retry manually; older cores may not support this feature.`
  String get nodeQualityFailed {
    return Intl.message(
      'Unknown: check unavailable or failed. Retry manually; older cores may not support this feature.',
      name: 'nodeQualityFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unknown: check timed out`
  String get nodeQualityTimeout {
    return Intl.message(
      'Unknown: check timed out',
      name: 'nodeQualityTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Start and initialize the core before checking.`
  String get nodeQualityInactive {
    return Intl.message(
      'Start and initialize the core before checking.',
      name: 'nodeQualityInactive',
      desc: '',
      args: [],
    );
  }

  /// `Not requested`
  String get nodeQualityNotRequested {
    return Intl.message(
      'Not requested',
      name: 'nodeQualityNotRequested',
      desc: '',
      args: [],
    );
  }

  /// `Select a concrete node. Mutable or load-balancing groups are not supported.`
  String get nodeQualityConcreteOnly {
    return Intl.message(
      'Select a concrete node. Mutable or load-balancing groups are not supported.',
      name: 'nodeQualityConcreteOnly',
      desc: '',
      args: [],
    );
  }

  /// `Other checks are running. Retry shortly.`
  String get nodeQualityBusy {
    return Intl.message(
      'Other checks are running. Retry shortly.',
      name: 'nodeQualityBusy',
      desc: '',
      args: [],
    );
  }

  /// `Egress IP`
  String get nodeQualityEgressIp {
    return Intl.message(
      'Egress IP',
      name: 'nodeQualityEgressIp',
      desc: '',
      args: [],
    );
  }

  /// `Edge / country`
  String get nodeQualityEdge {
    return Intl.message(
      'Edge / country',
      name: 'nodeQualityEdge',
      desc: '',
      args: [],
    );
  }

  /// `IP risk score (IPPure)`
  String get nodeQualityRiskScore {
    return Intl.message(
      'IP risk score (IPPure)',
      name: 'nodeQualityRiskScore',
      desc: '',
      args: [],
    );
  }

  /// `IP type`
  String get nodeQualityIpType {
    return Intl.message(
      'IP type',
      name: 'nodeQualityIpType',
      desc: '',
      args: [],
    );
  }

  /// `Residential`
  String get nodeQualityResidential {
    return Intl.message(
      'Residential',
      name: 'nodeQualityResidential',
      desc: '',
      args: [],
    );
  }

  /// `Non-residential (not necessarily a data center)`
  String get nodeQualityNonResidential {
    return Intl.message(
      'Non-residential (not necessarily a data center)',
      name: 'nodeQualityNonResidential',
      desc: '',
      args: [],
    );
  }

  /// `IPPure Beta risk data is advisory, not a purity percentage, a Cloudflare score or a security guarantee. Missing or unverified IPv6 scores remain unknown.`
  String get nodeQualityScoreScope {
    return Intl.message(
      'IPPure Beta risk data is advisory, not a purity percentage, a Cloudflare score or a security guarantee. Missing or unverified IPv6 scores remain unknown.',
      name: 'nodeQualityScoreScope',
      desc: '',
      args: [],
    );
  }

  /// `The providers observed different egress IPs. Do not attribute the risk score to the Cloudflare IP.`
  String get nodeQualityMismatch {
    return Intl.message(
      'The providers observed different egress IPs. Do not attribute the risk score to the Cloudflare IP.',
      name: 'nodeQualityMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Sampled at {time}`
  String nodeQualitySampledAt(Object time) {
    return Intl.message(
      'Sampled at $time',
      name: 'nodeQualitySampledAt',
      desc: '',
      args: [time],
    );
  }

  /// `Cloudflare request score`
  String get nodeQualityCloudflareScore {
    return Intl.message(
      'Cloudflare request score',
      name: 'nodeQualityCloudflareScore',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable: /cdn-cgi/trace does not return a Bot Score; this app does not estimate or fabricate one.`
  String get nodeQualityCloudflareScoreUnavailable {
    return Intl.message(
      'Unavailable: /cdn-cgi/trace does not return a Bot Score; this app does not estimate or fabricate one.',
      name: 'nodeQualityCloudflareScoreUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Each manual check sends one HTTPS request per selected provider: no automatic retries, no shared cookies and no spoofed browser fingerprint. Third parties may still log it; zero impact cannot be guaranteed.`
  String get nodeQualityProbeFootprint {
    return Intl.message(
      'Each manual check sends one HTTPS request per selected provider: no automatic retries, no shared cookies and no spoofed browser fingerprint. Third parties may still log it; zero impact cannot be guaranteed.',
      name: 'nodeQualityProbeFootprint',
      desc: '',
      args: [],
    );
  }

  /// `Checked recently. Try again in {seconds}s.`
  String nodeQualityCooldown(Object seconds) {
    return Intl.message(
      'Checked recently. Try again in ${seconds}s.',
      name: 'nodeQualityCooldown',
      desc: '',
      args: [seconds],
    );
  }

  /// `Select a concrete proxy on the Proxies page first.`
  String get nodeQualityPickNode {
    return Intl.message(
      'Select a concrete proxy on the Proxies page first.',
      name: 'nodeQualityPickNode',
      desc: '',
      args: [],
    );
  }

  /// `Available nodes`
  String get dashboardAvailableNodes {
    return Intl.message(
      'Available nodes',
      name: 'dashboardAvailableNodes',
      desc: '',
      args: [],
    );
  }

  /// `Coverage`
  String get dashboardCoverage {
    return Intl.message(
      'Coverage',
      name: 'dashboardCoverage',
      desc: '',
      args: [],
    );
  }

  /// `Current node`
  String get dashboardCurrentNode {
    return Intl.message(
      'Current node',
      name: 'dashboardCurrentNode',
      desc: '',
      args: [],
    );
  }

  /// `Node speed`
  String get dashboardNodeSpeed {
    return Intl.message(
      'Node speed',
      name: 'dashboardNodeSpeed',
      desc: '',
      args: [],
    );
  }

  /// `Testing…`
  String get speedTestRunning {
    return Intl.message(
      'Testing…',
      name: 'speedTestRunning',
      desc: '',
      args: [],
    );
  }

  /// `Speed test failed`
  String get speedTestFailed {
    return Intl.message(
      'Speed test failed',
      name: 'speedTestFailed',
      desc: '',
      args: [],
    );
  }

  /// `Tap to test`
  String get speedTestTapToRun {
    return Intl.message(
      'Tap to test',
      name: 'speedTestTapToRun',
      desc: '',
      args: [],
    );
  }

  /// `Start the core before testing`
  String get speedTestInactive {
    return Intl.message(
      'Start the core before testing',
      name: 'speedTestInactive',
      desc: '',
      args: [],
    );
  }

  /// `Auto speed test`
  String get autoSpeedTest {
    return Intl.message(
      'Auto speed test',
      name: 'autoSpeedTest',
      desc: '',
      args: [],
    );
  }

  /// `Tests on startup and after switching nodes; uses significant data`
  String get autoSpeedTestDesc {
    return Intl.message(
      'Tests on startup and after switching nodes; uses significant data',
      name: 'autoSpeedTestDesc',
      desc: '',
      args: [],
    );
  }

  /// `Risk index`
  String get riskIndex {
    return Intl.message('Risk index', name: 'riskIndex', desc: '', args: []);
  }

  /// `Not checked`
  String get riskIndexNotChecked {
    return Intl.message(
      'Not checked',
      name: 'riskIndexNotChecked',
      desc: '',
      args: [],
    );
  }

  /// `Tap to check the risk index`
  String get riskIndexTapToCheck {
    return Intl.message(
      'Tap to check the risk index',
      name: 'riskIndexTapToCheck',
      desc: '',
      args: [],
    );
  }

  /// `Overview`
  String get overviewTitle {
    return Intl.message('Overview', name: 'overviewTitle', desc: '', args: []);
  }

  /// `Service running`
  String get serviceRunning {
    return Intl.message(
      'Service running',
      name: 'serviceRunning',
      desc: '',
      args: [],
    );
  }

  /// `Main`
  String get sectionMain {
    return Intl.message('Main', name: 'sectionMain', desc: '', args: []);
  }

  /// `Monitor`
  String get sectionMonitor {
    return Intl.message('Monitor', name: 'sectionMonitor', desc: '', args: []);
  }

  /// `System`
  String get sectionSystem {
    return Intl.message('System', name: 'sectionSystem', desc: '', args: []);
  }

  /// `Fresh start, steady protection all day.`
  String get overviewPhraseMorning {
    return Intl.message(
      'Fresh start, steady protection all day.',
      name: 'overviewPhraseMorning',
      desc: '',
      args: [],
    );
  }

  /// `Going strong, staying connected.`
  String get overviewPhraseAfternoon {
    return Intl.message(
      'Going strong, staying connected.',
      name: 'overviewPhraseAfternoon',
      desc: '',
      args: [],
    );
  }

  /// `Still going strong through the evening.`
  String get overviewPhraseEvening {
    return Intl.message(
      'Still going strong through the evening.',
      name: 'overviewPhraseEvening',
      desc: '',
      args: [],
    );
  }

  /// `Late night, rock-solid protection.`
  String get overviewPhraseNight {
    return Intl.message(
      'Late night, rock-solid protection.',
      name: 'overviewPhraseNight',
      desc: '',
      args: [],
    );
  }

  /// `View`
  String get proxiesViewMode {
    return Intl.message('View', name: 'proxiesViewMode', desc: '', args: []);
  }

  /// `All nodes`
  String get proxiesViewAll {
    return Intl.message(
      'All nodes',
      name: 'proxiesViewAll',
      desc: '',
      args: [],
    );
  }

  /// `Group by region`
  String get proxiesViewRegion {
    return Intl.message(
      'Group by region',
      name: 'proxiesViewRegion',
      desc: '',
      args: [],
    );
  }

  /// `Locate current node`
  String get proxiesLocateSelected {
    return Intl.message(
      'Locate current node',
      name: 'proxiesLocateSelected',
      desc: '',
      args: [],
    );
  }

  /// `Recent`
  String get proxiesRecent {
    return Intl.message('Recent', name: 'proxiesRecent', desc: '', args: []);
  }

  /// `Frequently used`
  String get proxiesFrequent {
    return Intl.message(
      'Frequently used',
      name: 'proxiesFrequent',
      desc: '',
      args: [],
    );
  }

  /// `Provider info`
  String get proxiesProviderInfo {
    return Intl.message(
      'Provider info',
      name: 'proxiesProviderInfo',
      desc: '',
      args: [],
    );
  }

  /// `Other regions`
  String get proxiesOtherRegion {
    return Intl.message(
      'Other regions',
      name: 'proxiesOtherRegion',
      desc: '',
      args: [],
    );
  }

  /// `Low risk`
  String get riskIndexLow {
    return Intl.message('Low risk', name: 'riskIndexLow', desc: '', args: []);
  }

  /// `Medium risk`
  String get riskIndexMedium {
    return Intl.message(
      'Medium risk',
      name: 'riskIndexMedium',
      desc: '',
      args: [],
    );
  }

  /// `High risk`
  String get riskIndexHigh {
    return Intl.message('High risk', name: 'riskIndexHigh', desc: '', args: []);
  }

  /// `No score`
  String get riskIndexNoScore {
    return Intl.message(
      'No score',
      name: 'riskIndexNoScore',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get nodeQualityStatusOk {
    return Intl.message('OK', name: 'nodeQualityStatusOk', desc: '', args: []);
  }

  /// `Timeout`
  String get nodeQualityStatusTimeout {
    return Intl.message(
      'Timeout',
      name: 'nodeQualityStatusTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get nodeQualityStatusFailed {
    return Intl.message(
      'Failed',
      name: 'nodeQualityStatusFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable`
  String get nodeQualityStatusUnavailable {
    return Intl.message(
      'Unavailable',
      name: 'nodeQualityStatusUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `In use`
  String get profileActive {
    return Intl.message('In use', name: 'profileActive', desc: '', args: []);
  }

  /// `Not in use`
  String get profileInactive {
    return Intl.message(
      'Not in use',
      name: 'profileInactive',
      desc: '',
      args: [],
    );
  }

  /// `Remote`
  String get profileRemote {
    return Intl.message('Remote', name: 'profileRemote', desc: '', args: []);
  }

  /// `Local file`
  String get profileLocalFile {
    return Intl.message(
      'Local file',
      name: 'profileLocalFile',
      desc: '',
      args: [],
    );
  }

  /// `Remaining`
  String get profileRemainingTraffic {
    return Intl.message(
      'Remaining',
      name: 'profileRemainingTraffic',
      desc: '',
      args: [],
    );
  }

  /// `Used {percent}%`
  String profileUsedPercent(Object percent) {
    return Intl.message(
      'Used $percent%',
      name: 'profileUsedPercent',
      desc: '',
      args: [percent],
    );
  }

  /// `Expires`
  String get profileExpire {
    return Intl.message('Expires', name: 'profileExpire', desc: '', args: []);
  }

  /// `{days} days left`
  String profileDaysLeft(Object days) {
    return Intl.message(
      '$days days left',
      name: 'profileDaysLeft',
      desc: '',
      args: [days],
    );
  }

  /// `{days} d left`
  String profileDaysLeftShort(Object days) {
    return Intl.message(
      '$days d left',
      name: 'profileDaysLeftShort',
      desc: '',
      args: [days],
    );
  }

  /// `Nodes`
  String get profileNodeCount {
    return Intl.message('Nodes', name: 'profileNodeCount', desc: '', args: []);
  }

  /// `Current node`
  String get profileCurrentNode {
    return Intl.message(
      'Current node',
      name: 'profileCurrentNode',
      desc: '',
      args: [],
    );
  }

  /// `Group`
  String get profileStrategyGroup {
    return Intl.message(
      'Group',
      name: 'profileStrategyGroup',
      desc: '',
      args: [],
    );
  }

  /// `Auto update`
  String get profileAutoUpdate {
    return Intl.message(
      'Auto update',
      name: 'profileAutoUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Set as current`
  String get profileSetCurrent {
    return Intl.message(
      'Set as current',
      name: 'profileSetCurrent',
      desc: '',
      args: [],
    );
  }

  /// `Current`
  String get profileCurrentConfig {
    return Intl.message(
      'Current',
      name: 'profileCurrentConfig',
      desc: '',
      args: [],
    );
  }

  /// `Update now`
  String get profileUpdateNow {
    return Intl.message(
      'Update now',
      name: 'profileUpdateNow',
      desc: '',
      args: [],
    );
  }

  /// `Replace file`
  String get profileReplaceFile {
    return Intl.message(
      'Replace file',
      name: 'profileReplaceFile',
      desc: '',
      args: [],
    );
  }

  /// `Subscription URL`
  String get profileSubscriptionUrl {
    return Intl.message(
      'Subscription URL',
      name: 'profileSubscriptionUrl',
      desc: '',
      args: [],
    );
  }

  /// `Tap for details`
  String get profileTapToExpand {
    return Intl.message(
      'Tap for details',
      name: 'profileTapToExpand',
      desc: '',
      args: [],
    );
  }

  /// `Collapse`
  String get profileCollapse {
    return Intl.message(
      'Collapse',
      name: 'profileCollapse',
      desc: '',
      args: [],
    );
  }

  /// `Last update`
  String get profileLastUpdate {
    return Intl.message(
      'Last update',
      name: 'profileLastUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Every {hours} h`
  String profileEveryHours(Object hours) {
    return Intl.message(
      'Every $hours h',
      name: 'profileEveryHours',
      desc: '',
      args: [hours],
    );
  }

  /// `Every {minutes} min`
  String profileEveryMinutes(Object minutes) {
    return Intl.message(
      'Every $minutes min',
      name: 'profileEveryMinutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `Off`
  String get profileOff {
    return Intl.message('Off', name: 'profileOff', desc: '', args: []);
  }

  /// `No traffic info`
  String get profileNoTrafficInfo {
    return Intl.message(
      'No traffic info',
      name: 'profileNoTrafficInfo',
      desc: '',
      args: [],
    );
  }

  /// `Local YAML`
  String get profileLocalYaml {
    return Intl.message(
      'Local YAML',
      name: 'profileLocalYaml',
      desc: '',
      args: [],
    );
  }

  /// `Tap a card for details; drag or use arrow keys to switch`
  String get profileCarouselHint {
    return Intl.message(
      'Tap a card for details; drag or use arrow keys to switch',
      name: 'profileCarouselHint',
      desc: '',
      args: [],
    );
  }

  /// `Shown after switching`
  String get profileNotLoaded {
    return Intl.message(
      'Shown after switching',
      name: 'profileNotLoaded',
      desc: '',
      args: [],
    );
  }

  /// `Used`
  String get profileUsed {
    return Intl.message('Used', name: 'profileUsed', desc: '', args: []);
  }

  /// `Days left`
  String get profileRemainingDays {
    return Intl.message(
      'Days left',
      name: 'profileRemainingDays',
      desc: '',
      args: [],
    );
  }

  /// `Subscription`
  String get profileSubscription {
    return Intl.message(
      'Subscription',
      name: 'profileSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Interval`
  String get profileUpdateInterval {
    return Intl.message(
      'Interval',
      name: 'profileUpdateInterval',
      desc: '',
      args: [],
    );
  }

  /// `Manual`
  String get profileManualUpdate {
    return Intl.message(
      'Manual',
      name: 'profileManualUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Edit profile`
  String get profileEditTitle {
    return Intl.message(
      'Edit profile',
      name: 'profileEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Open full editor`
  String get profileOpenEditor {
    return Intl.message(
      'Open full editor',
      name: 'profileOpenEditor',
      desc: '',
      args: [],
    );
  }

  /// `Save changes`
  String get profileSaveChanges {
    return Intl.message(
      'Save changes',
      name: 'profileSaveChanges',
      desc: '',
      args: [],
    );
  }

  /// `{count} nodes`
  String profileNodeCountValue(Object count) {
    return Intl.message(
      '$count nodes',
      name: 'profileNodeCountValue',
      desc: '',
      args: [count],
    );
  }

  /// `{days} days`
  String profileDaysCount(Object days) {
    return Intl.message(
      '$days days',
      name: 'profileDaysCount',
      desc: '',
      args: [days],
    );
  }

  /// `Show link`
  String get profileShowLink {
    return Intl.message(
      'Show link',
      name: 'profileShowLink',
      desc: '',
      args: [],
    );
  }

  /// `Hide link`
  String get profileHideLink {
    return Intl.message(
      'Hide link',
      name: 'profileHideLink',
      desc: '',
      args: [],
    );
  }

  /// `Enter a subscription URL`
  String get profileUrlRequired {
    return Intl.message(
      'Enter a subscription URL',
      name: 'profileUrlRequired',
      desc: '',
      args: [],
    );
  }

  /// `New profile`
  String get profileNew {
    return Intl.message('New profile', name: 'profileNew', desc: '', args: []);
  }

  /// `Enter a name and subscription URL; the config is fetched on save`
  String get profileDraftHint {
    return Intl.message(
      'Enter a name and subscription URL; the config is fetched on save',
      name: 'profileDraftHint',
      desc: '',
      args: [],
    );
  }

  /// `Import file`
  String get profileImportFile {
    return Intl.message(
      'Import file',
      name: 'profileImportFile',
      desc: '',
      args: [],
    );
  }

  /// `Copy info`
  String get copyInfo {
    return Intl.message('Copy info', name: 'copyInfo', desc: '', args: []);
  }

  /// `Traffic`
  String get traffic {
    return Intl.message('Traffic', name: 'traffic', desc: '', args: []);
  }

  /// `Upload speed`
  String get uploadSpeed {
    return Intl.message(
      'Upload speed',
      name: 'uploadSpeed',
      desc: '',
      args: [],
    );
  }

  /// `Download speed`
  String get downloadSpeed {
    return Intl.message(
      'Download speed',
      name: 'downloadSpeed',
      desc: '',
      args: [],
    );
  }

  /// `Close all connections`
  String get closeAllConnections {
    return Intl.message(
      'Close all connections',
      name: 'closeAllConnections',
      desc: '',
      args: [],
    );
  }

  /// `Auto scroll`
  String get autoScroll {
    return Intl.message('Auto scroll', name: 'autoScroll', desc: '', args: []);
  }

  /// `Appearance`
  String get appearance {
    return Intl.message('Appearance', name: 'appearance', desc: '', args: []);
  }

  /// `Startup`
  String get startup {
    return Intl.message('Startup', name: 'startup', desc: '', args: []);
  }

  /// `Data`
  String get data {
    return Intl.message('Data', name: 'data', desc: '', args: []);
  }

  /// `Behavior`
  String get behavior {
    return Intl.message('Behavior', name: 'behavior', desc: '', args: []);
  }

  /// `Diagnostics`
  String get diagnostics {
    return Intl.message('Diagnostics', name: 'diagnostics', desc: '', args: []);
  }

  /// `Version`
  String get version {
    return Intl.message('Version', name: 'version', desc: '', args: []);
  }

  /// `Licenses`
  String get licenses {
    return Intl.message('Licenses', name: 'licenses', desc: '', args: []);
  }

  /// `Feedback`
  String get feedback {
    return Intl.message('Feedback', name: 'feedback', desc: '', args: []);
  }

  /// `Links`
  String get links {
    return Intl.message('Links', name: 'links', desc: '', args: []);
  }

  /// `Appearance, network, core and data`
  String get settingsDesc {
    return Intl.message(
      'Appearance, network, core and data',
      name: 'settingsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Text size`
  String get settingsTextScale {
    return Intl.message(
      'Text size',
      name: 'settingsTextScale',
      desc: '',
      args: [],
    );
  }

  /// `Brand color`
  String get settingsThemeColor {
    return Intl.message(
      'Brand color',
      name: 'settingsThemeColor',
      desc: '',
      args: [],
    );
  }

  /// `Open logs`
  String get settingsOpenLogs {
    return Intl.message(
      'Open logs',
      name: 'settingsOpenLogs',
      desc: '',
      args: [],
    );
  }

  /// `Current core`
  String get settingsCurrentCore {
    return Intl.message(
      'Current core',
      name: 'settingsCurrentCore',
      desc: '',
      args: [],
    );
  }

  /// `Log level`
  String get settingsLogLevel {
    return Intl.message(
      'Log level',
      name: 'settingsLogLevel',
      desc: '',
      args: [],
    );
  }

  /// `About QuanClash`
  String get settingsAboutApp {
    return Intl.message(
      'About QuanClash',
      name: 'settingsAboutApp',
      desc: '',
      args: [],
    );
  }

  /// `General`
  String get settingsGeneral {
    return Intl.message('General', name: 'settingsGeneral', desc: '', args: []);
  }

  /// `Local`
  String get settingsBackupLocal {
    return Intl.message(
      'Local',
      name: 'settingsBackupLocal',
      desc: '',
      args: [],
    );
  }

  /// `WebDAV`
  String get settingsBackupRemote {
    return Intl.message(
      'WebDAV',
      name: 'settingsBackupRemote',
      desc: '',
      args: [],
    );
  }

  /// `Restore from file`
  String get settingsImportFile {
    return Intl.message(
      'Restore from file',
      name: 'settingsImportFile',
      desc: '',
      args: [],
    );
  }

  /// `Back up now`
  String get settingsBackupNow {
    return Intl.message(
      'Back up now',
      name: 'settingsBackupNow',
      desc: '',
      args: [],
    );
  }

  /// `Bind`
  String get settingsBindDav {
    return Intl.message('Bind', name: 'settingsBindDav', desc: '', args: []);
  }

  /// `Edit`
  String get settingsEditDav {
    return Intl.message('Edit', name: 'settingsEditDav', desc: '', args: []);
  }

  /// `Sync to remote`
  String get settingsSyncDav {
    return Intl.message(
      'Sync to remote',
      name: 'settingsSyncDav',
      desc: '',
      args: [],
    );
  }

  /// `Restore from remote`
  String get settingsRestoreDav {
    return Intl.message(
      'Restore from remote',
      name: 'settingsRestoreDav',
      desc: '',
      args: [],
    );
  }

  /// `WebDAV not bound`
  String get settingsNoDav {
    return Intl.message(
      'WebDAV not bound',
      name: 'settingsNoDav',
      desc: '',
      args: [],
    );
  }

  /// `Reset all shortcuts`
  String get settingsResetHotkeys {
    return Intl.message(
      'Reset all shortcuts',
      name: 'settingsResetHotkeys',
      desc: '',
      args: [],
    );
  }

  /// `Advanced`
  String get advanced {
    return Intl.message('Advanced', name: 'advanced', desc: '', args: []);
  }

  /// `How existing data is handled on restore`
  String get restoreStrategyDesc {
    return Intl.message(
      'How existing data is handled on restore',
      name: 'restoreStrategyDesc',
      desc: '',
      args: [],
    );
  }

  /// `Edit global basic configuration`
  String get settingsEnterBasic {
    return Intl.message(
      'Edit global basic configuration',
      name: 'settingsEnterBasic',
      desc: '',
      args: [],
    );
  }

  /// `Network, DNS, rules and scripts`
  String get settingsEnterAdvanced {
    return Intl.message(
      'Network, DNS, rules and scripts',
      name: 'settingsEnterAdvanced',
      desc: '',
      args: [],
    );
  }

  /// `GeoIP / GeoSite resources`
  String get settingsEnterResources {
    return Intl.message(
      'GeoIP / GeoSite resources',
      name: 'settingsEnterResources',
      desc: '',
      args: [],
    );
  }

  /// `Configure per-app proxy access`
  String get settingsEnterAccess {
    return Intl.message(
      'Configure per-app proxy access',
      name: 'settingsEnterAccess',
      desc: '',
      args: [],
    );
  }

  /// `Network options`
  String get settingsNetworkOptions {
    return Intl.message(
      'Network options',
      name: 'settingsNetworkOptions',
      desc: '',
      args: [],
    );
  }

  /// `DNS settings`
  String get settingsDns {
    return Intl.message(
      'DNS settings',
      name: 'settingsDns',
      desc: '',
      args: [],
    );
  }

  /// `Reset DNS`
  String get settingsResetDns {
    return Intl.message(
      'Reset DNS',
      name: 'settingsResetDns',
      desc: '',
      args: [],
    );
  }

  /// `Access mode`
  String get settingsAccessMode {
    return Intl.message(
      'Access mode',
      name: 'settingsAccessMode',
      desc: '',
      args: [],
    );
  }

  /// `App source`
  String get settingsAccessSource {
    return Intl.message(
      'App source',
      name: 'settingsAccessSource',
      desc: '',
      args: [],
    );
  }

  /// `Save access control`
  String get settingsSaveAccess {
    return Intl.message(
      'Save access control',
      name: 'settingsSaveAccess',
      desc: '',
      args: [],
    );
  }

  /// `Resource actions`
  String get settingsResourceActions {
    return Intl.message(
      'Resource actions',
      name: 'settingsResourceActions',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
