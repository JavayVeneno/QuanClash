// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
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
  String get localeName => 'ru';

  static String m0(count) =>
      "${Intl.plural(count, one: '${count} день назад', few: '${count} дня назад', many: '${count} дней назад', other: '${count} дня назад')}";

  static String m1(label) =>
      "Вы уверены, что хотите удалить выбранные ${label}?";

  static String m2(label) => "Вы уверены, что хотите удалить текущий ${label}?";

  static String m3(label) => "Детали {}";

  static String m4(time) => "Снимок прочитан: ${time}";

  static String m5(target) => "Настроенная цель: ${target}";

  static String m6(codes) => "Проверка безопасности DNS не пройдена: ${codes}";

  static String m7(label) => "${label} не может быть пустым";

  static String m8(count) => "${count} записей";

  static String m9(label) => "Текущий ${label} уже существует";

  static String m10(name) => "${name} пропущено";

  static String m11(name) => "${name} обновлено";

  static String m12(name) => "Обновление ${name}...";

  static String m13(count) =>
      "${Intl.plural(count, one: '${count} час назад', few: '${count} часа назад', many: '${count} часов назад', other: '${count} часа назад')}";

  static String m14(count) => "${count} часов";

  static String m15(target) => "${target} является недопустимой политикой";

  static String m16(proxyName) => "${proxyName} является недопустимым прокси";

  static String m17(providerName) =>
      "${providerName} является недопустимым провайдером прокси";

  static String m18(subRule) => "${subRule} является недопустимым подправилом";

  static String m19(appName) =>
      "1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check ${appName} in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.";

  static String m20(count) =>
      "${Intl.plural(count, one: '${count} минута назад', few: '${count} минуты назад', many: '${count} минут назад', other: '${count} минуты назад')}";

  static String m21(count) =>
      "${Intl.plural(count, one: '${count} месяц назад', few: '${count} месяца назад', many: '${count} месяцев назад', other: '${count} месяца назад')}";

  static String m22(seconds) =>
      "Проверка выполнялась недавно. Повторите через ${seconds} с.";

  static String m23(time) => "Время проверки: ${time}";

  static String m24(label) => "${label} пока отсутствуют";

  static String m25(label) => "${label} должно быть числом";

  static String m26(label) => "${label} должен быть числом от 1024 до 49151";

  static String m27(days) => "${days} дн.";

  static String m28(days) => "Осталось ${days} дн.";

  static String m29(days) => "Осталось ${days} дн.";

  static String m30(hours) => "Каждые ${hours} ч";

  static String m31(minutes) => "Каждые ${minutes} мин";

  static String m32(count) => "${count} узлов";

  static String m33(percent) => "Использовано ${percent}%";

  static String m34(count) => "${count} секунд";

  static String m35(count) => "Выбрано ${count} элементов";

  static String m36(label) => "${label} должен быть URL";

  static String m37(count) =>
      "${Intl.plural(count, one: '${count} год назад', few: '${count} года назад', many: '${count} лет назад', other: '${count} года назад')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("О программе"),
    "accessControl": MessageLookupByLibrary.simpleMessage("Контроль доступа"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Разрешить только выбранным приложениям доступ к VPN",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "Настройка доступа приложений к прокси",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Выбранные приложения будут исключены из VPN",
    ),
    "accessControlSettings": MessageLookupByLibrary.simpleMessage(
      "Настройки контроля доступа",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Аккаунт"),
    "action": MessageLookupByLibrary.simpleMessage("Действие"),
    "action_mode": MessageLookupByLibrary.simpleMessage("Переключить режим"),
    "action_proxy": MessageLookupByLibrary.simpleMessage("Системный прокси"),
    "action_start": MessageLookupByLibrary.simpleMessage("Старт/Стоп"),
    "action_tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "action_view": MessageLookupByLibrary.simpleMessage("Показать/Скрыть"),
    "add": MessageLookupByLibrary.simpleMessage("Добавить"),
    "addProfile": MessageLookupByLibrary.simpleMessage("Добавить профиль"),
    "addProxies": MessageLookupByLibrary.simpleMessage("Добавить прокси"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Добавить группу прокси",
    ),
    "addProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Добавить провайдеров прокси",
    ),
    "addRule": MessageLookupByLibrary.simpleMessage("Добавить правило"),
    "addSsid": MessageLookupByLibrary.simpleMessage("Добавить SSID"),
    "addedRules": MessageLookupByLibrary.simpleMessage("Добавленные правила"),
    "additionalParameters": MessageLookupByLibrary.simpleMessage(
      "Дополнительные параметры",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Адрес"),
    "addressHelp": MessageLookupByLibrary.simpleMessage("Адрес сервера WebDAV"),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите действительный адрес WebDAV",
    ),
    "advanced": MessageLookupByLibrary.simpleMessage("Дополнительно"),
    "advancedConfig": MessageLookupByLibrary.simpleMessage(
      "Расширенная конфигурация",
    ),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Предоставляет разнообразные варианты конфигурации",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("Согласен"),
    "allowBypass": MessageLookupByLibrary.simpleMessage(
      "Разрешить приложениям обходить VPN",
    ),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "Некоторые приложения могут обходить VPN при включении",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("Разрешить LAN"),
    "allowLanDesc": MessageLookupByLibrary.simpleMessage(
      "Разрешить доступ к прокси через локальную сеть",
    ),
    "app": MessageLookupByLibrary.simpleMessage("Приложение"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage(
      "Контроль доступа приложений",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("Внешний вид"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage(
      "Добавить системный DNS",
    ),
    "appendSystemDnsTip": MessageLookupByLibrary.simpleMessage(
      "Принудительно добавить системный DNS к конфигурации",
    ),
    "application": MessageLookupByLibrary.simpleMessage("Приложение"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage(
      "Изменение настроек, связанных с приложением",
    ),
    "authorized": MessageLookupByLibrary.simpleMessage("Разрешено"),
    "auto": MessageLookupByLibrary.simpleMessage("Авто"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage(
      "Автопроверка обновлений",
    ),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "Автоматически проверять обновления при запуске приложения",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Автоматическое закрытие соединений",
    ),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Автоматически закрывать соединения после смены узла",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Автозапуск"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Следовать автозапуску системы",
    ),
    "autoRun": MessageLookupByLibrary.simpleMessage("Автозапуск"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "Автоматический запуск при открытии приложения",
    ),
    "autoScroll": MessageLookupByLibrary.simpleMessage("Автопрокрутка"),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage(
      "Автоматическая настройка системного DNS",
    ),
    "autoSetSystemDnsDesc": MessageLookupByLibrary.simpleMessage(
      "Привязывает DNS-запросы к текущему прокси, чтобы они не уходили к местному провайдеру. Если узел нельзя проверить статически, используется совместимый режим.",
    ),
    "autoSpeedTest": MessageLookupByLibrary.simpleMessage("Автотест скорости"),
    "autoSpeedTestDesc": MessageLookupByLibrary.simpleMessage(
      "Тест при запуске и после смены узла; расходует трафик",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("Автообновление"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Интервал автообновления (минуты)",
    ),
    "backup": MessageLookupByLibrary.simpleMessage("Резервное копирование"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование и восстановление",
    ),
    "backupAndRestoreDesc": MessageLookupByLibrary.simpleMessage(
      "Синхронизация данных через WebDAV или файлы",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование успешно",
    ),
    "basicConfig": MessageLookupByLibrary.simpleMessage("Базовая конфигурация"),
    "basicConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Глобальное изменение базовых настроек",
    ),
    "basicInfo": MessageLookupByLibrary.simpleMessage("Основная информация"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("Базовая стратегия"),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "To ensure background operation, please disable battery optimization for this app. Tap to go to settings.",
    ),
    "batteryOptimizationStatusTip": MessageLookupByLibrary.simpleMessage(
      "Из-за особенностей системы этот статус не всегда может быть точным.",
    ),
    "behavior": MessageLookupByLibrary.simpleMessage("Поведение"),
    "bind": MessageLookupByLibrary.simpleMessage("Привязать"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage(
      "Режим черного списка",
    ),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Обход домена"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Действует только при включенном системном прокси",
    ),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "Кэш поврежден. Хотите очистить его?",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Отмена"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage(
      "Отменить выбор всего",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("Проверить обновления"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "Текущее приложение уже является последней версией",
    ),
    "clearData": MessageLookupByLibrary.simpleMessage("Очистить данные"),
    "clipboardExport": MessageLookupByLibrary.simpleMessage(
      "Экспорт в буфер обмена",
    ),
    "clipboardImport": MessageLookupByLibrary.simpleMessage(
      "Импорт из буфера обмена",
    ),
    "closeAllConnections": MessageLookupByLibrary.simpleMessage(
      "Закрыть все соединения",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Цвет"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("Цветовые схемы"),
    "columns": MessageLookupByLibrary.simpleMessage("Столбцы"),
    "compatible": MessageLookupByLibrary.simpleMessage("Режим совместимости"),
    "configDataDetected": MessageLookupByLibrary.simpleMessage(
      "Данные обнаружены в конфигурации",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Подтвердить"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите очистить все данные?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите удалить текущую группу прокси?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите выйти из текущего окна?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите принудительно аварийно завершить работу ядра?",
    ),
    "confirmOverwriteTip": MessageLookupByLibrary.simpleMessage(
      "Существующие данные будут перезаписаны после подтверждения",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("Подключено"),
    "connecting": MessageLookupByLibrary.simpleMessage("Подключение..."),
    "connection": MessageLookupByLibrary.simpleMessage("Соединение"),
    "connections": MessageLookupByLibrary.simpleMessage("Соединения"),
    "connectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Просмотр текущих данных о соединениях",
    ),
    "connectivity": MessageLookupByLibrary.simpleMessage("Связь："),
    "content": MessageLookupByLibrary.simpleMessage("Содержание"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Содержимое не может быть пустым",
    ),
    "contentScheme": MessageLookupByLibrary.simpleMessage("Контентная тема"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "Управление глобальными добавленными правилами",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Копировать"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage(
      "Копирование переменных окружения",
    ),
    "copyInfo": MessageLookupByLibrary.simpleMessage("Копировать данные"),
    "copyLink": MessageLookupByLibrary.simpleMessage("Копировать ссылку"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("Копирование успешно"),
    "core": MessageLookupByLibrary.simpleMessage("Ядро"),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Основной статус"),
    "country": MessageLookupByLibrary.simpleMessage("Страна"),
    "crashTest": MessageLookupByLibrary.simpleMessage("Тест на сбои"),
    "crashlytics": MessageLookupByLibrary.simpleMessage("Анализ сбоев"),
    "crashlyticsTip": MessageLookupByLibrary.simpleMessage(
      "При включении автоматически загружает журналы сбоев без конфиденциальной информации, когда приложение выходит из строя",
    ),
    "create": MessageLookupByLibrary.simpleMessage("Создать"),
    "createProfile": MessageLookupByLibrary.simpleMessage("Create Profile"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Время создания"),
    "custom": MessageLookupByLibrary.simpleMessage("Пользовательский"),
    "cut": MessageLookupByLibrary.simpleMessage("Вырезать"),
    "dark": MessageLookupByLibrary.simpleMessage("Темный"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Панель управления"),
    "dashboardAvailableNodes": MessageLookupByLibrary.simpleMessage(
      "Доступные узлы",
    ),
    "dashboardCoverage": MessageLookupByLibrary.simpleMessage("Покрытие"),
    "dashboardCurrentNode": MessageLookupByLibrary.simpleMessage(
      "Текущий узел",
    ),
    "dashboardNodeSpeed": MessageLookupByLibrary.simpleMessage("Скорость узла"),
    "data": MessageLookupByLibrary.simpleMessage("Данные"),
    "dataChangedSave": MessageLookupByLibrary.simpleMessage(
      "Обнаружены изменения данных, хотите сохранить?",
    ),
    "dataCollectionContent": MessageLookupByLibrary.simpleMessage(
      "Это приложение использует Firebase Crashlytics для сбора информации о сбоях nhằm улучшения стабильности приложения.\nСобираемые данные включают информацию об устройстве и подробности о сбоях, но не содержат персональных конфиденциальных данных.\nВы можете отключить эту функцию в настройках.",
    ),
    "dataCollectionTip": MessageLookupByLibrary.simpleMessage(
      "Уведомление о сборе данных",
    ),
    "daysAgo": m0,
    "defaultNameserver": MessageLookupByLibrary.simpleMessage(
      "Сервер имен по умолчанию",
    ),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Для разрешения DNS-сервера",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("По умолчанию"),
    "delay": MessageLookupByLibrary.simpleMessage("Задержка"),
    "delayTest": MessageLookupByLibrary.simpleMessage("Тест задержки"),
    "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
    "deleteMultipTip": m1,
    "deleteTip": m2,
    "desc": MessageLookupByLibrary.simpleMessage(
      "Многоплатформенный прокси-клиент на основе ClashMeta, простой и удобный в использовании, с открытым исходным кодом и без рекламы.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Назначение"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage(
      "Геолокация назначения",
    ),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("ASN назначения"),
    "details": m3,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Опирается на сторонний API, только для справки",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Режим разработчика"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "Режим разработчика активирован.",
    ),
    "diagnostics": MessageLookupByLibrary.simpleMessage("Диагностика"),
    "direct": MessageLookupByLibrary.simpleMessage("Прямой"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("Отключить UDP"),
    "disclaimer": MessageLookupByLibrary.simpleMessage(
      "Отказ от ответственности",
    ),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "Это программное обеспечение используется только в некоммерческих целях, таких как учебные обмены и научные исследования. Запрещено использовать это программное обеспечение в коммерческих целях. Любая коммерческая деятельность, если таковая имеется, не имеет отношения к этому программному обеспечению.",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("Отключено"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "Обнаружена новая версия",
    ),
    "dnsAutoLeakProtectionActive": MessageLookupByLibrary.simpleMessage(
      "Автозащита от утечек включена: DNS-запросы привязаны к текущему узлу.",
    ),
    "dnsDesc": MessageLookupByLibrary.simpleMessage(
      "Обновление настроек, связанных с DNS",
    ),
    "dnsDiagnosticBootstrap": MessageLookupByLibrary.simpleMessage(
      "Загрузочный DNS: имена резолверов / прокси",
    ),
    "dnsDiagnosticDedicated": MessageLookupByLibrary.simpleMessage(
      "Отдельные резолверы",
    ),
    "dnsDiagnosticDescription": MessageLookupByLibrary.simpleMessage(
      "Просмотр текущей конфигурации ядра без DNS-запросов",
    ),
    "dnsDiagnosticDirect": MessageLookupByLibrary.simpleMessage(
      "Запросы прямого трафика",
    ),
    "dnsDiagnosticDisabled": MessageLookupByLibrary.simpleMessage(
      "DNS ядра отключён",
    ),
    "dnsDiagnosticInactive": MessageLookupByLibrary.simpleMessage(
      "Ядро не готово",
    ),
    "dnsDiagnosticInactiveHint": MessageLookupByLibrary.simpleMessage(
      "Подключите и инициализируйте ядро для чтения настроек DNS.",
    ),
    "dnsDiagnosticInheritance": MessageLookupByLibrary.simpleMessage(
      "Наследование резолверов",
    ),
    "dnsDiagnosticInheritsMain": MessageLookupByLibrary.simpleMessage(
      "Наследует обычные резолверы",
    ),
    "dnsDiagnosticLimitations": MessageLookupByLibrary.simpleMessage(
      "Показана применённая конфигурация, а не ожидающие настройки. Это заданные маршруты, не захват пакетов. Группа может выбрать DIRECT. DoH/DoT приложений и трафик вне TUN требуют отдельной проверки. Приватность DNS и репутация IP — разные показатели.",
    ),
    "dnsDiagnosticNoEndpoint": MessageLookupByLibrary.simpleMessage(
      "Нет сетевого адреса",
    ),
    "dnsDiagnosticNoWarnings": MessageLookupByLibrary.simpleMessage(
      "Коды предупреждений не получены; это не доказывает отсутствие утечек.",
    ),
    "dnsDiagnosticNotConfigured": MessageLookupByLibrary.simpleMessage(
      "Нет активной конфигурации DNS",
    ),
    "dnsDiagnosticOrdinary": MessageLookupByLibrary.simpleMessage(
      "Обычные запросы: основные / резервные / политики",
    ),
    "dnsDiagnosticPathBlocked": MessageLookupByLibrary.simpleMessage(
      "Заблокирован заданной целью",
    ),
    "dnsDiagnosticPathDhcp": MessageLookupByLibrary.simpleMessage(
      "Резолвер, полученный через DHCP",
    ),
    "dnsDiagnosticPathDirect": MessageLookupByLibrary.simpleMessage(
      "Прямой маршрут",
    ),
    "dnsDiagnosticPathInterface": MessageLookupByLibrary.simpleMessage(
      "Прямой маршрут через заданный интерфейс",
    ),
    "dnsDiagnosticPathOverlay": MessageLookupByLibrary.simpleMessage(
      "Оверлейный резолвер; прокси-only не подтверждён",
    ),
    "dnsDiagnosticPathProxy": MessageLookupByLibrary.simpleMessage(
      "Задан прокси-маршрут; фактически не проверен",
    ),
    "dnsDiagnosticPathRules": MessageLookupByLibrary.simpleMessage(
      "По правилам; возможен DIRECT",
    ),
    "dnsDiagnosticPathSynthetic": MessageLookupByLibrary.simpleMessage(
      "Синтетический ответ DNS",
    ),
    "dnsDiagnosticPathSystem": MessageLookupByLibrary.simpleMessage(
      "Системный резолвер",
    ),
    "dnsDiagnosticReadAt": m4,
    "dnsDiagnosticReady": MessageLookupByLibrary.simpleMessage(
      "Активная конфигурация прочитана",
    ),
    "dnsDiagnosticRefresh": MessageLookupByLibrary.simpleMessage(
      "Обновить снимок",
    ),
    "dnsDiagnosticRetryHint": MessageLookupByLibrary.simpleMessage(
      "Текущего результата нет. Повторите обновление; старое ядро может не поддерживать этот запрос.",
    ),
    "dnsDiagnosticScope": MessageLookupByLibrary.simpleMessage(
      "Снимок конфигурации, а не заключение об утечках DNS",
    ),
    "dnsDiagnosticTarget": m5,
    "dnsDiagnosticTitle": MessageLookupByLibrary.simpleMessage(
      "Активные маршруты DNS",
    ),
    "dnsDiagnosticUnavailable": MessageLookupByLibrary.simpleMessage(
      "Диагностика DNS недоступна",
    ),
    "dnsDiagnosticWarningBootstrap": MessageLookupByLibrary.simpleMessage(
      "Загрузочный DNS может обращаться напрямую. Проверьте его адреса.",
    ),
    "dnsDiagnosticWarningDirect": MessageLookupByLibrary.simpleMessage(
      "Резолвер обычного или прямого трафика может обращаться напрямую.",
    ),
    "dnsDiagnosticWarningHost": MessageLookupByLibrary.simpleMessage(
      "Присутствует системный или DHCP-резолвер.",
    ),
    "dnsDiagnosticWarningProxy": MessageLookupByLibrary.simpleMessage(
      "Прокси или оверлей настроен, но фактический выход не проверен.",
    ),
    "dnsDiagnosticWarningRules": MessageLookupByLibrary.simpleMessage(
      "Правила DNS могут выбрать DIRECT; соблюдение правил не означает «только прокси».",
    ),
    "dnsDiagnosticWarningUnknown": MessageLookupByLibrary.simpleMessage(
      "Неизвестный или непроверенный маршрут требует проверки.",
    ),
    "dnsDiagnosticWarnings": MessageLookupByLibrary.simpleMessage(
      "Предупреждения и ограничения маршрутов",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNS-перехват"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("Режим DNS"),
    "dnsProxyTarget": MessageLookupByLibrary.simpleMessage("Цель DNS-прокси"),
    "dnsProxyTargetDesc": MessageLookupByLibrary.simpleMessage(
      "Укажите существующий статический прокси или группу без DIRECT, автоматического включения провайдеров и фильтров. Цель используется для DNS обычного и прямого трафика.",
    ),
    "dnsSafetyInvalidConfig": m6,
    "dnsSafetyMode": MessageLookupByLibrary.simpleMessage(
      "Режим безопасности DNS",
    ),
    "dnsSafetyModeCompatible": MessageLookupByLibrary.simpleMessage(
      "Совместимый",
    ),
    "dnsSafetyModeCustom": MessageLookupByLibrary.simpleMessage("Свой"),
    "dnsSafetyModeDesc": MessageLookupByLibrary.simpleMessage(
      "Режим «только прокси» требует статической прокси-цели и явных загрузочных DNS с IP-адресами. Загрузочные запросы идут напрямую; это не тест утечек DNS.",
    ),
    "dnsSafetyModeProxyOnly": MessageLookupByLibrary.simpleMessage(
      "Только прокси",
    ),
    "doYouWantToPass": MessageLookupByLibrary.simpleMessage(
      "Вы хотите пропустить",
    ),
    "domain": MessageLookupByLibrary.simpleMessage("Домен"),
    "download": MessageLookupByLibrary.simpleMessage("Скачивание"),
    "downloadSpeed": MessageLookupByLibrary.simpleMessage("Скорость загрузки"),
    "edit": MessageLookupByLibrary.simpleMessage("Редактировать"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage(
      "Редактировать глобальные правила",
    ),
    "editProxy": MessageLookupByLibrary.simpleMessage("Редактировать прокси"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Редактировать группу прокси",
    ),
    "editRule": MessageLookupByLibrary.simpleMessage("Редактировать правило"),
    "editSsid": MessageLookupByLibrary.simpleMessage("Изменить SSID"),
    "emptyTip": m7,
    "en": MessageLookupByLibrary.simpleMessage("Английский"),
    "entries": MessageLookupByLibrary.simpleMessage(" записей"),
    "entriesCount": m8,
    "exclude": MessageLookupByLibrary.simpleMessage(
      "Скрыть из последних задач",
    ),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "Когда приложение находится в фоновом режиме, оно скрыто из последних задач",
    ),
    "excludeProxyFilter": MessageLookupByLibrary.simpleMessage(
      "Исключить фильтр прокси",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Exclude SSIDs"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.",
    ),
    "excludeType": MessageLookupByLibrary.simpleMessage("Тип исключения"),
    "existsTip": m9,
    "exit": MessageLookupByLibrary.simpleMessage("Выход"),
    "expand": MessageLookupByLibrary.simpleMessage("Стандартный"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("Ожидаемый статус"),
    "exportFile": MessageLookupByLibrary.simpleMessage("Экспорт файла"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Экспорт логов"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Экспорт успешен"),
    "expressiveScheme": MessageLookupByLibrary.simpleMessage("Экспрессивные"),
    "externalController": MessageLookupByLibrary.simpleMessage(
      "Внешний контроллер",
    ),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "При включении ядро Clash можно контролировать на порту 9090",
    ),
    "externalFetch": MessageLookupByLibrary.simpleMessage("Внешнее получение"),
    "externalLink": MessageLookupByLibrary.simpleMessage("Внешняя ссылка"),
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Фильтр Fakeip"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Диапазон Fakeip"),
    "fallback": MessageLookupByLibrary.simpleMessage("Резервный"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage(
      "Обычно используется оффшорный DNS",
    ),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage(
      "Фильтр резервного DNS",
    ),
    "feedback": MessageLookupByLibrary.simpleMessage("Обратная связь"),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("Точная передача"),
    "file": MessageLookupByLibrary.simpleMessage("Файл"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("Прямая загрузка профиля"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "Файл был изменен. Хотите сохранить изменения?",
    ),
    "findProcessMode": MessageLookupByLibrary.simpleMessage(
      "Режим поиска процесса",
    ),
    "findProcessModeDesc": MessageLookupByLibrary.simpleMessage(
      "При включении возможны небольшие потери производительности",
    ),
    "fontFamily": MessageLookupByLibrary.simpleMessage("Семейство шрифтов"),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите принудительно перезапустить ядро?",
    ),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("Фруктовый микс"),
    "general": MessageLookupByLibrary.simpleMessage("Общие"),
    "geoAutoUpdate": MessageLookupByLibrary.simpleMessage("Автообновление"),
    "geoAutoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Интервал автообновления",
    ),
    "geoAutoUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "Интервал автообновления должен быть больше 0",
    ),
    "geoOptions": MessageLookupByLibrary.simpleMessage("Настройки Geo"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Ресурсы Geo"),
    "geoSkipped": m10,
    "geoUpdated": m11,
    "geoUpdating": m12,
    "geodataLoader": MessageLookupByLibrary.simpleMessage(
      "Режим низкого потребления памяти для геоданных",
    ),
    "geodataLoaderDesc": MessageLookupByLibrary.simpleMessage(
      "Включение будет использовать загрузчик геоданных с низким потреблением памяти",
    ),
    "geoipCode": MessageLookupByLibrary.simpleMessage("Код Geoip"),
    "global": MessageLookupByLibrary.simpleMessage("Глобальный"),
    "go": MessageLookupByLibrary.simpleMessage("Перейти"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Перейти к загрузке"),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage(
      "Перейти к настройке скрипта",
    ),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "Хотите сохранить изменения в кэше?",
    ),
    "hideFromList": MessageLookupByLibrary.simpleMessage("Скрыть из списка"),
    "host": MessageLookupByLibrary.simpleMessage("Хост"),
    "hostsDesc": MessageLookupByLibrary.simpleMessage("Добавить Hosts"),
    "hotkeyConflict": MessageLookupByLibrary.simpleMessage(
      "Конфликт горячих клавиш",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage(
      "Управление горячими клавишами",
    ),
    "hotkeyManagementDesc": MessageLookupByLibrary.simpleMessage(
      "Использование клавиатуры для управления приложением",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("часов"),
    "hoursAgo": m13,
    "hoursCount": m14,
    "icon": MessageLookupByLibrary.simpleMessage("Иконка"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("История иконок"),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Стиль иконки"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("URL иконки"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignore Battery Optimization",
    ),
    "import": MessageLookupByLibrary.simpleMessage("Импорт"),
    "importFile": MessageLookupByLibrary.simpleMessage("Импорт из файла"),
    "importFromURL": MessageLookupByLibrary.simpleMessage("Импорт из URL"),
    "importUrl": MessageLookupByLibrary.simpleMessage("Импорт по URL"),
    "includeAllProxies": MessageLookupByLibrary.simpleMessage(
      "Включить все прокси",
    ),
    "includeAllProxiesTip": MessageLookupByLibrary.simpleMessage(
      "Импорт всех прокси, не содержащих группы прокси, дополнительные группы прокси можно добавить ниже",
    ),
    "includeAllProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Включить всех провайдеров прокси",
    ),
    "includeAllProxyProvidersTip": MessageLookupByLibrary.simpleMessage(
      "При включении это переопределит импортированных провайдеров прокси",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage(
      "Долгосрочное действие",
    ),
    "init": MessageLookupByLibrary.simpleMessage("Инициализация"),
    "inputCorrectHotkey": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите правильную горячую клавишу",
    ),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "Введите имя группы прокси",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage(
      "Введите содержимое правила",
    ),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage(
      "Интеллектуальный выбор",
    ),
    "internet": MessageLookupByLibrary.simpleMessage("Интернет"),
    "interval": MessageLookupByLibrary.simpleMessage("Интервал"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("Внутренний IP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage(
      "Неверный файл резервной копии",
    ),
    "invalidPolicy": m15,
    "invalidProxy": m16,
    "invalidProxyProvider": m17,
    "invalidSubRule": m18,
    "ipcidr": MessageLookupByLibrary.simpleMessage("IPCIDR"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "При включении будет возможно получать IPv6 трафик",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "Разрешить входящий IPv6",
    ),
    "ja": MessageLookupByLibrary.simpleMessage("Японский"),
    "justNow": MessageLookupByLibrary.simpleMessage("Только что"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "Интервал поддержания TCP-соединения",
    ),
    "key": MessageLookupByLibrary.simpleMessage("Ключ"),
    "language": MessageLookupByLibrary.simpleMessage("Язык"),
    "layout": MessageLookupByLibrary.simpleMessage("Макет"),
    "licenses": MessageLookupByLibrary.simpleMessage("Лицензии"),
    "light": MessageLookupByLibrary.simpleMessage("Светлый"),
    "links": MessageLookupByLibrary.simpleMessage("Ссылки"),
    "list": MessageLookupByLibrary.simpleMessage("Список"),
    "listen": MessageLookupByLibrary.simpleMessage("Слушать"),
    "loadTest": MessageLookupByLibrary.simpleMessage("Тест загрузки"),
    "loading": MessageLookupByLibrary.simpleMessage("Загрузка..."),
    "local": MessageLookupByLibrary.simpleMessage("Локальный"),
    "localBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование локальных данных на локальный диск",
    ),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Location Permission",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Разрешение на геолокацию отклонено, поэтому невозможно получить имя текущей Wi-Fi сети. Включите разрешение на геолокацию вручную в системных настройках.",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.",
    ),
    "locationPermissionGuide": m19,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Location Permission Required",
    ),
    "log": MessageLookupByLibrary.simpleMessage("Журнал"),
    "logLevel": MessageLookupByLibrary.simpleMessage("Уровень логов"),
    "logcat": MessageLookupByLibrary.simpleMessage("Logcat"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "Отключение скроет запись логов",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("Логи"),
    "logsDesc": MessageLookupByLibrary.simpleMessage("Записи захвата логов"),
    "logsTest": MessageLookupByLibrary.simpleMessage("Тест журналов"),
    "loopback": MessageLookupByLibrary.simpleMessage(
      "Инструмент разблокировки Loopback",
    ),
    "loopbackDesc": MessageLookupByLibrary.simpleMessage(
      "Используется для разблокировки Loopback UWP",
    ),
    "loose": MessageLookupByLibrary.simpleMessage("Свободный"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage(
      "Сопоставить исходный IP",
    ),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage(
      "Макс. количество неудач",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("Информация о памяти"),
    "messageTest": MessageLookupByLibrary.simpleMessage(
      "Тестирование сообщения",
    ),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("Это сообщение."),
    "min": MessageLookupByLibrary.simpleMessage("Мин"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage(
      "Свернуть при выходе",
    ),
    "minimizeOnExitDesc": MessageLookupByLibrary.simpleMessage(
      "Изменить стандартное событие выхода из системы",
    ),
    "minutesAgo": m20,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Смешанный порт"),
    "mode": MessageLookupByLibrary.simpleMessage("Режим"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Монохром"),
    "monthsAgo": m21,
    "more": MessageLookupByLibrary.simpleMessage("Еще"),
    "name": MessageLookupByLibrary.simpleMessage("Имя"),
    "nameserver": MessageLookupByLibrary.simpleMessage("Сервер имен"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Для разрешения домена",
    ),
    "nameserverPolicy": MessageLookupByLibrary.simpleMessage(
      "Политика сервера имен",
    ),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "Указать соответствующую политику сервера имен",
    ),
    "network": MessageLookupByLibrary.simpleMessage("Сеть"),
    "networkDesc": MessageLookupByLibrary.simpleMessage(
      "Изменение настроек, связанных с сетью",
    ),
    "networkDetection": MessageLookupByLibrary.simpleMessage(
      "Обнаружение сети",
    ),
    "networkException": MessageLookupByLibrary.simpleMessage(
      "Ошибка сети, проверьте соединение и попробуйте еще раз",
    ),
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Скорость сети"),
    "networkType": MessageLookupByLibrary.simpleMessage("Тип сети"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("Нейтральные"),
    "noData": MessageLookupByLibrary.simpleMessage("Нет данных"),
    "noHotKey": MessageLookupByLibrary.simpleMessage("Нет горячей клавиши"),
    "noInfo": MessageLookupByLibrary.simpleMessage("Нет информации"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage(
      "Больше не напоминать",
    ),
    "noNetwork": MessageLookupByLibrary.simpleMessage("Нет сети"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("Приложение без сети"),
    "noRecords": MessageLookupByLibrary.simpleMessage("Нет записей"),
    "noResolve": MessageLookupByLibrary.simpleMessage("Не разрешать IP"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage(
      "Не разрешать имя хоста",
    ),
    "nodeQualityBusy": MessageLookupByLibrary.simpleMessage(
      "Выполняются другие проверки. Повторите чуть позже.",
    ),
    "nodeQualityCloudflareScore": MessageLookupByLibrary.simpleMessage(
      "Оценка запроса Cloudflare",
    ),
    "nodeQualityCloudflareScoreUnavailable": MessageLookupByLibrary.simpleMessage(
      "Недоступно: /cdn-cgi/trace не возвращает Bot Score; приложение не оценивает и не подделывает его.",
    ),
    "nodeQualityConcreteOnly": MessageLookupByLibrary.simpleMessage(
      "Выберите конкретный узел. Динамические группы и балансировка пока не поддерживаются.",
    ),
    "nodeQualityCooldown": m22,
    "nodeQualityEdge": MessageLookupByLibrary.simpleMessage("Сервер / страна"),
    "nodeQualityEgressIp": MessageLookupByLibrary.simpleMessage("Выходной IP"),
    "nodeQualityFailed": MessageLookupByLibrary.simpleMessage(
      "Неизвестно: проверка недоступна или завершилась ошибкой. Повторите вручную; старое ядро может не поддерживать функцию.",
    ),
    "nodeQualityInactive": MessageLookupByLibrary.simpleMessage(
      "Сначала запустите и инициализируйте ядро.",
    ),
    "nodeQualityIpType": MessageLookupByLibrary.simpleMessage("Тип IP"),
    "nodeQualityMismatch": MessageLookupByLibrary.simpleMessage(
      "Провайдеры видят разные выходные IP. Не относите оценку риска к IP, полученному от Cloudflare.",
    ),
    "nodeQualityNonResidential": MessageLookupByLibrary.simpleMessage(
      "Нежилой IP (не обязательно дата-центр)",
    ),
    "nodeQualityNotRequested": MessageLookupByLibrary.simpleMessage(
      "Не запрошено",
    ),
    "nodeQualityOk": MessageLookupByLibrary.simpleMessage("Проверка успешна"),
    "nodeQualityOptIn": MessageLookupByLibrary.simpleMessage(
      "Проверить риск через IPPure",
    ),
    "nodeQualityPickNode": MessageLookupByLibrary.simpleMessage(
      "Сначала выберите конкретный узел на странице прокси.",
    ),
    "nodeQualityPrivacy": MessageLookupByLibrary.simpleMessage(
      "Только для этого окна: IPPure получит выходной IP и метаданные запроса. QuanClash не передаёт учётные данные аккаунта или прокси. Cloudflare получает свой запрос. Автоматических проверок нет.",
    ),
    "nodeQualityProbeFootprint": MessageLookupByLibrary.simpleMessage(
      "Каждая ручная проверка отправляет по одному HTTPS-запросу выбранным сервисам: без автоматических повторов, повторного использования Cookie и подделки отпечатка браузера. Третья сторона всё равно может записать запрос; нулевое влияние не гарантируется.",
    ),
    "nodeQualityResidential": MessageLookupByLibrary.simpleMessage("Жилой IP"),
    "nodeQualityRiskScore": MessageLookupByLibrary.simpleMessage(
      "Оценка риска IP (IPPure)",
    ),
    "nodeQualityRun": MessageLookupByLibrary.simpleMessage("Проверить"),
    "nodeQualitySampledAt": m23,
    "nodeQualityScope": MessageLookupByLibrary.simpleMessage(
      "Ручная HTTPS-проверка через узел. Cloudflare проверяет доступность, выходной IP и TTFB, но не чистоту IP. DNS и начальное разрешение могут идти напрямую. DIRECT проверяет прямое соединение.",
    ),
    "nodeQualityScoreScope": MessageLookupByLibrary.simpleMessage(
      "Данные IPPure Beta справочные: это не процент чистоты, не оценка Cloudflare и не гарантия безопасности. Отсутствующие и непроверенные оценки IPv6 остаются неизвестными.",
    ),
    "nodeQualityStatusFailed": MessageLookupByLibrary.simpleMessage("Ошибка"),
    "nodeQualityStatusOk": MessageLookupByLibrary.simpleMessage("Успех"),
    "nodeQualityStatusTimeout": MessageLookupByLibrary.simpleMessage("Таймаут"),
    "nodeQualityStatusUnavailable": MessageLookupByLibrary.simpleMessage(
      "Недоступно",
    ),
    "nodeQualityTimeout": MessageLookupByLibrary.simpleMessage(
      "Неизвестно: время ожидания истекло",
    ),
    "nodeQualityTitle": MessageLookupByLibrary.simpleMessage("Качество узла"),
    "none": MessageLookupByLibrary.simpleMessage("Нет"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "Текущая группа прокси не может быть выбрана.",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Нет профиля, пожалуйста, добавьте профиль",
    ),
    "nullTip": m24,
    "numberTip": m25,
    "onDemand": MessageLookupByLibrary.simpleMessage("On Demand"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "Configure the program running state for specific scenarios",
    ),
    "onlyIcon": MessageLookupByLibrary.simpleMessage("Только иконка"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "Только статистика прокси",
    ),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "При включении будет учитываться только трафик прокси",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Необязательно"),
    "options": MessageLookupByLibrary.simpleMessage("Опции"),
    "other": MessageLookupByLibrary.simpleMessage("Другое"),
    "otherContributors": MessageLookupByLibrary.simpleMessage(
      "Другие участники",
    ),
    "outboundMode": MessageLookupByLibrary.simpleMessage(
      "Режим исходящего трафика",
    ),
    "override": MessageLookupByLibrary.simpleMessage("Переопределить"),
    "overrideDns": MessageLookupByLibrary.simpleMessage("Переопределить DNS"),
    "overrideDnsDesc": MessageLookupByLibrary.simpleMessage(
      "Включение переопределит настройки DNS в профиле",
    ),
    "overrideMode": MessageLookupByLibrary.simpleMessage(
      "Режим переопределения",
    ),
    "overrideScript": MessageLookupByLibrary.simpleMessage(
      "Скрипт переопределения",
    ),
    "overviewPhraseAfternoon": MessageLookupByLibrary.simpleMessage(
      "Всё отлично, соединение стабильно.",
    ),
    "overviewPhraseEvening": MessageLookupByLibrary.simpleMessage(
      "Бодро сопровождаем вас весь вечер.",
    ),
    "overviewPhraseMorning": MessageLookupByLibrary.simpleMessage(
      "Заряд бодрости и стабильная защита на весь день.",
    ),
    "overviewPhraseNight": MessageLookupByLibrary.simpleMessage(
      "Поздняя ночь, надёжная защита.",
    ),
    "overviewTitle": MessageLookupByLibrary.simpleMessage("Обзор"),
    "overwriteTypeCustom": MessageLookupByLibrary.simpleMessage(
      "Пользовательский",
    ),
    "overwriteTypeCustomDesc": MessageLookupByLibrary.simpleMessage(
      "Пользовательский режим, полная настройка групп прокси и правил",
    ),
    "palette": MessageLookupByLibrary.simpleMessage("Палитра"),
    "password": MessageLookupByLibrary.simpleMessage("Пароль"),
    "paste": MessageLookupByLibrary.simpleMessage("Вставить"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, привяжите WebDAV",
    ),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите название скрипта",
    ),
    "pleaseInputAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите пароль администратора",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, загрузите действительный QR-код",
    ),
    "port": MessageLookupByLibrary.simpleMessage("Порт"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Введите другой порт",
    ),
    "portTip": m26,
    "preferH3Desc": MessageLookupByLibrary.simpleMessage(
      "Приоритетное использование HTTP/3 для DOH",
    ),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Prerequisites"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, нажмите клавишу.",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Предпросмотр"),
    "process": MessageLookupByLibrary.simpleMessage("процесс"),
    "profile": MessageLookupByLibrary.simpleMessage("Профиль"),
    "profileActive": MessageLookupByLibrary.simpleMessage("Используется"),
    "profileAutoUpdate": MessageLookupByLibrary.simpleMessage("Автообновление"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, введите действительный формат интервала времени",
        ),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, введите интервал времени для автообновления",
        ),
    "profileCarouselHint": MessageLookupByLibrary.simpleMessage(
      "Нажмите на карточку для деталей; перетаскивайте или используйте стрелки",
    ),
    "profileCollapse": MessageLookupByLibrary.simpleMessage("Свернуть"),
    "profileCurrentConfig": MessageLookupByLibrary.simpleMessage(
      "Текущий профиль",
    ),
    "profileCurrentNode": MessageLookupByLibrary.simpleMessage("Текущий узел"),
    "profileDaysCount": m27,
    "profileDaysLeft": m28,
    "profileDaysLeftShort": m29,
    "profileDraftHint": MessageLookupByLibrary.simpleMessage(
      "Укажите имя и URL подписки; конфигурация загрузится при сохранении",
    ),
    "profileEditTitle": MessageLookupByLibrary.simpleMessage(
      "Изменить профиль",
    ),
    "profileEveryHours": m30,
    "profileEveryMinutes": m31,
    "profileExpire": MessageLookupByLibrary.simpleMessage("Истекает"),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "Профиль был изменен. Хотите отключить автообновление?",
    ),
    "profileHideLink": MessageLookupByLibrary.simpleMessage("Скрыть ссылку"),
    "profileImportFile": MessageLookupByLibrary.simpleMessage(
      "Импорт из файла",
    ),
    "profileInactive": MessageLookupByLibrary.simpleMessage("Не используется"),
    "profileLastUpdate": MessageLookupByLibrary.simpleMessage("Обновлено"),
    "profileLocalFile": MessageLookupByLibrary.simpleMessage("Локальный файл"),
    "profileLocalYaml": MessageLookupByLibrary.simpleMessage("Локальный YAML"),
    "profileManualUpdate": MessageLookupByLibrary.simpleMessage("Вручную"),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите имя профиля",
    ),
    "profileNew": MessageLookupByLibrary.simpleMessage("Новый профиль"),
    "profileNoTrafficInfo": MessageLookupByLibrary.simpleMessage(
      "Нет данных о трафике",
    ),
    "profileNodeCount": MessageLookupByLibrary.simpleMessage("Узлы"),
    "profileNodeCountValue": m32,
    "profileNotLoaded": MessageLookupByLibrary.simpleMessage(
      "После переключения",
    ),
    "profileOff": MessageLookupByLibrary.simpleMessage("Выкл."),
    "profileOpenEditor": MessageLookupByLibrary.simpleMessage(
      "Открыть редактор",
    ),
    "profileRemainingDays": MessageLookupByLibrary.simpleMessage(
      "Осталось дней",
    ),
    "profileRemainingTraffic": MessageLookupByLibrary.simpleMessage(
      "Остаток трафика",
    ),
    "profileRemote": MessageLookupByLibrary.simpleMessage("Удалённая подписка"),
    "profileReplaceFile": MessageLookupByLibrary.simpleMessage("Заменить файл"),
    "profileSaveChanges": MessageLookupByLibrary.simpleMessage(
      "Сохранить изменения",
    ),
    "profileSetCurrent": MessageLookupByLibrary.simpleMessage(
      "Сделать текущей",
    ),
    "profileShowLink": MessageLookupByLibrary.simpleMessage("Показать ссылку"),
    "profileStrategyGroup": MessageLookupByLibrary.simpleMessage("Группа"),
    "profileSubscription": MessageLookupByLibrary.simpleMessage("Подписка"),
    "profileSubscriptionUrl": MessageLookupByLibrary.simpleMessage(
      "URL подписки",
    ),
    "profileTapToExpand": MessageLookupByLibrary.simpleMessage(
      "Нажмите для деталей",
    ),
    "profileUpdateInterval": MessageLookupByLibrary.simpleMessage("Интервал"),
    "profileUpdateNow": MessageLookupByLibrary.simpleMessage("Обновить сейчас"),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите действительный URL профиля",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите URL профиля",
    ),
    "profileUrlRequired": MessageLookupByLibrary.simpleMessage(
      "Введите URL подписки",
    ),
    "profileUsed": MessageLookupByLibrary.simpleMessage("Использовано"),
    "profileUsedPercent": m33,
    "profiles": MessageLookupByLibrary.simpleMessage("Профили"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Сортировка профилей"),
    "project": MessageLookupByLibrary.simpleMessage("Проект"),
    "providers": MessageLookupByLibrary.simpleMessage("Провайдеры"),
    "proxies": MessageLookupByLibrary.simpleMessage("Прокси"),
    "proxiesEmpty": MessageLookupByLibrary.simpleMessage("Список прокси пуст"),
    "proxiesFrequent": MessageLookupByLibrary.simpleMessage(
      "Часто используемые",
    ),
    "proxiesLocateSelected": MessageLookupByLibrary.simpleMessage(
      "Перейти к текущему узлу",
    ),
    "proxiesOtherRegion": MessageLookupByLibrary.simpleMessage(
      "Другие регионы",
    ),
    "proxiesProviderInfo": MessageLookupByLibrary.simpleMessage(
      "Инфо провайдера",
    ),
    "proxiesRecent": MessageLookupByLibrary.simpleMessage("Недавние"),
    "proxiesViewAll": MessageLookupByLibrary.simpleMessage("Все узлы"),
    "proxiesViewMode": MessageLookupByLibrary.simpleMessage("Отображение"),
    "proxiesViewRegion": MessageLookupByLibrary.simpleMessage(
      "Группировать по регионам",
    ),
    "proxyChains": MessageLookupByLibrary.simpleMessage("Цепочки прокси"),
    "proxyDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Обнаружена аномалия выбранных прокси",
    ),
    "proxyFilter": MessageLookupByLibrary.simpleMessage("Фильтр прокси"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Группа прокси"),
    "proxyGroupDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Обнаружена аномалия текущей группы прокси",
    ),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "Группа прокси пуста",
    ),
    "proxyGroupNameDuplicate": MessageLookupByLibrary.simpleMessage(
      "Имя группы прокси дублируется",
    ),
    "proxyGroupNameEmpty": MessageLookupByLibrary.simpleMessage(
      "Имя группы прокси не может быть пустым",
    ),
    "proxyNameserver": MessageLookupByLibrary.simpleMessage(
      "Прокси-сервер имен",
    ),
    "proxyNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Домен для разрешения прокси-узлов",
    ),
    "proxyPort": MessageLookupByLibrary.simpleMessage("Порт прокси"),
    "proxyProviderDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Обнаружена аномалия выбранных провайдеров прокси",
    ),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("Провайдеры прокси"),
    "proxyProvidersEmpty": MessageLookupByLibrary.simpleMessage(
      "Провайдеры прокси пусты",
    ),
    "proxyProvidersNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Провайдеры прокси не могут быть пустыми",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("Тип прокси"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("Очистить кэш"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Чисто черный режим"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QR-код"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "Сканируйте QR-код для получения профиля",
    ),
    "quickFill": MessageLookupByLibrary.simpleMessage("Быстрое заполнение"),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("Радужные"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redir-порт"),
    "redo": MessageLookupByLibrary.simpleMessage("Повторить"),
    "remote": MessageLookupByLibrary.simpleMessage("Удаленный"),
    "remoteBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование локальных данных на WebDAV",
    ),
    "remoteDestination": MessageLookupByLibrary.simpleMessage(
      "Удалённое назначение",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Удалить"),
    "rename": MessageLookupByLibrary.simpleMessage("Переименовать"),
    "request": MessageLookupByLibrary.simpleMessage("Запрос"),
    "requests": MessageLookupByLibrary.simpleMessage("Запросы"),
    "requestsDesc": MessageLookupByLibrary.simpleMessage(
      "Просмотр последних записей запросов",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("Сброс"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "На текущей странице есть изменения. Вы уверены, что хотите сбросить?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage(
      "Убедитесь, что хотите сбросить",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("Ресурсы"),
    "resourcesDesc": MessageLookupByLibrary.simpleMessage(
      "Информация, связанная с внешними ресурсами",
    ),
    "respectRules": MessageLookupByLibrary.simpleMessage("Соблюдение правил"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "DNS-соединение следует правилам, необходимо настроить proxy-server-nameserver",
    ),
    "restart": MessageLookupByLibrary.simpleMessage("Перезапустить"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите перезапустить ядро?",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Восстановить"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage(
      "Восстановить все данные",
    ),
    "restoreException": MessageLookupByLibrary.simpleMessage(
      "Ошибка восстановления",
    ),
    "restoreFromFileDesc": MessageLookupByLibrary.simpleMessage(
      "Восстановить данные из файла",
    ),
    "restoreFromWebDAVDesc": MessageLookupByLibrary.simpleMessage(
      "Восстановить данные через WebDAV",
    ),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage(
      "Восстановить только файлы конфигурации",
    ),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage(
      "Стратегия восстановления",
    ),
    "restoreStrategyDesc": MessageLookupByLibrary.simpleMessage(
      "Как обрабатывать существующие данные",
    ),
    "restoreStrategy_compatible": MessageLookupByLibrary.simpleMessage(
      "Совместимый",
    ),
    "restoreStrategy_override": MessageLookupByLibrary.simpleMessage(
      "Перезаписать",
    ),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage(
      "Восстановление успешно",
    ),
    "riskIndex": MessageLookupByLibrary.simpleMessage("Индекс риска"),
    "riskIndexHigh": MessageLookupByLibrary.simpleMessage("Высокий риск"),
    "riskIndexLow": MessageLookupByLibrary.simpleMessage("Низкий риск"),
    "riskIndexMedium": MessageLookupByLibrary.simpleMessage("Средний риск"),
    "riskIndexNoScore": MessageLookupByLibrary.simpleMessage("Нет оценки"),
    "riskIndexNotChecked": MessageLookupByLibrary.simpleMessage("Не проверено"),
    "riskIndexTapToCheck": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы проверить индекс риска",
    ),
    "routeAddress": MessageLookupByLibrary.simpleMessage("Адрес маршрутизации"),
    "routeAddressDesc": MessageLookupByLibrary.simpleMessage(
      "Настройка адреса прослушивания маршрутизации",
    ),
    "routeMode": MessageLookupByLibrary.simpleMessage("Режим маршрутизации"),
    "routeMode_bypassPrivate": MessageLookupByLibrary.simpleMessage(
      "Обход частных адресов маршрутизации",
    ),
    "routeMode_config": MessageLookupByLibrary.simpleMessage(
      "Использовать конфигурацию",
    ),
    "ru": MessageLookupByLibrary.simpleMessage("Русский"),
    "rule": MessageLookupByLibrary.simpleMessage("Правило"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage(
      "Логическое правило AND",
    ),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить полный домен",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить ключевое слово домена",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставление по маске, поддерживает только * и ?",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить суффикс домена",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить метку DSCP (только для tproxy udp inbound)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить диапазон портов назначения запроса",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить код страны IP-адреса",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить домены внутри Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить входящее имя",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить входящий порт",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить входящий тип",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить входящее имя пользователя, поддерживает несколько имен через /",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить ASN IP-адреса",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить диапазон IP-адресов (IP-CIDR6 — это просто псевдоним)",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить диапазон IP-адресов",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить диапазон суффиксов IP",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить все запросы, условия не требуются",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить TCP или UDP",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage(
      "Логическое правило NOT",
    ),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage(
      "Логическое правило OR",
    ),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить по имени процесса, на Android соответствует имени пакета",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить по регулярному выражению имени процесса, на Android соответствует имени пакета",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить по полному пути процесса",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить по регулярному выражению пути процесса",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "Ссылка на набор правил, требуется настройка rule-providers",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить код страны исходного IP",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить ASN исходного IP",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить диапазон исходных IP-адресов",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить диапазон исходных суффиксов IP",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить диапазон портов источника запроса",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить с подправилом, обратите внимание на использование скобок",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Сопоставить Linux USER ID",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("Правило пусто"),
    "ruleName": MessageLookupByLibrary.simpleMessage("Название правила"),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("Провайдеры правил"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("Набор правил"),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Цель правила"),
    "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Сохранить изменения?"),
    "script": MessageLookupByLibrary.simpleMessage("Скрипт"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "Режим скрипта, использование внешних расширяющих скриптов, предоставление возможности переопределения конфигурации одним кликом",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Поиск"),
    "seconds": MessageLookupByLibrary.simpleMessage("Секунд"),
    "secondsCount": m34,
    "sectionMain": MessageLookupByLibrary.simpleMessage("Основное"),
    "sectionMonitor": MessageLookupByLibrary.simpleMessage("Мониторинг"),
    "sectionSystem": MessageLookupByLibrary.simpleMessage("Система"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Выбрать все"),
    "selectProxies": MessageLookupByLibrary.simpleMessage("Выбрать прокси"),
    "selectProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Выбрать провайдеров прокси",
    ),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите набор правил",
    ),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите стратегию разделения",
    ),
    "selectSubRule": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите подправило",
    ),
    "selected": MessageLookupByLibrary.simpleMessage("Выбрано"),
    "selectedCountTitle": m35,
    "serviceRunning": MessageLookupByLibrary.simpleMessage("Сервис работает"),
    "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
    "settingsAboutApp": MessageLookupByLibrary.simpleMessage("О QuanClash"),
    "settingsAccessMode": MessageLookupByLibrary.simpleMessage("Режим доступа"),
    "settingsAccessSource": MessageLookupByLibrary.simpleMessage(
      "Источник приложений",
    ),
    "settingsBackupLocal": MessageLookupByLibrary.simpleMessage("Локально"),
    "settingsBackupNow": MessageLookupByLibrary.simpleMessage(
      "Создать резервную копию",
    ),
    "settingsBackupRemote": MessageLookupByLibrary.simpleMessage("WebDAV"),
    "settingsBindDav": MessageLookupByLibrary.simpleMessage("Привязать"),
    "settingsCurrentCore": MessageLookupByLibrary.simpleMessage("Текущее ядро"),
    "settingsDesc": MessageLookupByLibrary.simpleMessage(
      "Внешний вид, сеть, ядро и данные",
    ),
    "settingsDns": MessageLookupByLibrary.simpleMessage("Настройки DNS"),
    "settingsEditDav": MessageLookupByLibrary.simpleMessage("Изменить"),
    "settingsEnterAccess": MessageLookupByLibrary.simpleMessage(
      "Настроить доступ приложений",
    ),
    "settingsEnterAdvanced": MessageLookupByLibrary.simpleMessage(
      "Сеть, DNS, правила и скрипты",
    ),
    "settingsEnterBasic": MessageLookupByLibrary.simpleMessage(
      "Изменить базовую конфигурацию",
    ),
    "settingsEnterResources": MessageLookupByLibrary.simpleMessage(
      "Ресурсы GeoIP / GeoSite",
    ),
    "settingsGeneral": MessageLookupByLibrary.simpleMessage("Общие"),
    "settingsImportFile": MessageLookupByLibrary.simpleMessage(
      "Восстановить из файла",
    ),
    "settingsLogLevel": MessageLookupByLibrary.simpleMessage("Уровень логов"),
    "settingsNetworkOptions": MessageLookupByLibrary.simpleMessage(
      "Параметры сети",
    ),
    "settingsNoDav": MessageLookupByLibrary.simpleMessage("WebDAV не привязан"),
    "settingsOpenLogs": MessageLookupByLibrary.simpleMessage("Открыть логи"),
    "settingsResetDns": MessageLookupByLibrary.simpleMessage("Сбросить DNS"),
    "settingsResetHotkeys": MessageLookupByLibrary.simpleMessage(
      "Сбросить все сочетания",
    ),
    "settingsResourceActions": MessageLookupByLibrary.simpleMessage(
      "Действия с ресурсами",
    ),
    "settingsRestoreDav": MessageLookupByLibrary.simpleMessage(
      "Восстановить из облака",
    ),
    "settingsSaveAccess": MessageLookupByLibrary.simpleMessage(
      "Сохранить доступ",
    ),
    "settingsSyncDav": MessageLookupByLibrary.simpleMessage("Синхронизировать"),
    "settingsTextScale": MessageLookupByLibrary.simpleMessage("Размер текста"),
    "settingsThemeColor": MessageLookupByLibrary.simpleMessage("Цвет бренда"),
    "show": MessageLookupByLibrary.simpleMessage("Показать"),
    "shrink": MessageLookupByLibrary.simpleMessage("Сжать"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("Тихий запуск"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Запуск в фоновом режиме",
    ),
    "size": MessageLookupByLibrary.simpleMessage("Размер"),
    "socksPort": MessageLookupByLibrary.simpleMessage("Socks-порт"),
    "sort": MessageLookupByLibrary.simpleMessage("Сортировка"),
    "source": MessageLookupByLibrary.simpleMessage("Источник"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("Исходный IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Специальный прокси"),
    "specialRules": MessageLookupByLibrary.simpleMessage("Специальные правила"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage(
      "Статистика скорости",
    ),
    "speedTestFailed": MessageLookupByLibrary.simpleMessage(
      "Не удалось измерить скорость",
    ),
    "speedTestInactive": MessageLookupByLibrary.simpleMessage(
      "Сначала запустите ядро",
    ),
    "speedTestRunning": MessageLookupByLibrary.simpleMessage("Тестирование…"),
    "speedTestTapToRun": MessageLookupByLibrary.simpleMessage(
      "Нажмите для теста",
    ),
    "splitStrategy": MessageLookupByLibrary.simpleMessage(
      "Стратегия разделения",
    ),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Стратегия разделения не может быть пустой",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDs is empty"),
    "stackMode": MessageLookupByLibrary.simpleMessage("Режим стека"),
    "standard": MessageLookupByLibrary.simpleMessage("Стандартный"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "Стандартный режим, переопределение базовой конфигурации, предоставление возможности простого добавления правил",
    ),
    "start": MessageLookupByLibrary.simpleMessage("Старт"),
    "startVpn": MessageLookupByLibrary.simpleMessage("Запуск VPN..."),
    "startup": MessageLookupByLibrary.simpleMessage("Запуск"),
    "status": MessageLookupByLibrary.simpleMessage("Статус"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "Системный DNS будет использоваться при выключении",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Стоп"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Остановка VPN..."),
    "style": MessageLookupByLibrary.simpleMessage("Стиль"),
    "subRule": MessageLookupByLibrary.simpleMessage("Подправило"),
    "subRuleEmpty": MessageLookupByLibrary.simpleMessage("Подправило пусто"),
    "subRuleNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Подправило не может быть пустым",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("Отправить"),
    "suspended": MessageLookupByLibrary.simpleMessage("Приостановлено..."),
    "sync": MessageLookupByLibrary.simpleMessage("Синхронизация"),
    "system": MessageLookupByLibrary.simpleMessage("Система"),
    "systemApp": MessageLookupByLibrary.simpleMessage("Системное приложение"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("Системный прокси"),
    "systemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Прикрепить HTTP-прокси к VpnService",
    ),
    "tab": MessageLookupByLibrary.simpleMessage("Вкладка"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("Анимация вкладок"),
    "tabAnimationDesc": MessageLookupByLibrary.simpleMessage(
      "Действительно только в мобильном виде",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы разрешить",
    ),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP параллелизм"),
    "tcpConcurrentDesc": MessageLookupByLibrary.simpleMessage(
      "Включение позволит использовать параллелизм TCP",
    ),
    "testInterval": MessageLookupByLibrary.simpleMessage(
      "Интервал тестирования",
    ),
    "testUrl": MessageLookupByLibrary.simpleMessage("Тест URL"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage(
      "Тестировать при использовании",
    ),
    "textScale": MessageLookupByLibrary.simpleMessage("Масштабирование текста"),
    "theme": MessageLookupByLibrary.simpleMessage("Тема"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Цвет темы"),
    "themeDesc": MessageLookupByLibrary.simpleMessage(
      "Установить темный режим, настроить цвет",
    ),
    "themeMode": MessageLookupByLibrary.simpleMessage("Режим темы"),
    "tight": MessageLookupByLibrary.simpleMessage("Плотный"),
    "time": MessageLookupByLibrary.simpleMessage("Время"),
    "timeout": MessageLookupByLibrary.simpleMessage("Таймаут"),
    "tip": MessageLookupByLibrary.simpleMessage("подсказка"),
    "toggle": MessageLookupByLibrary.simpleMessage("Переключить"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("Тональный акцент"),
    "tools": MessageLookupByLibrary.simpleMessage("Инструменты"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Tproxy-порт"),
    "traffic": MessageLookupByLibrary.simpleMessage("Трафик"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage(
      "Использование трафика",
    ),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "действительно только в режиме администратора",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("Выключить"),
    "turnOn": MessageLookupByLibrary.simpleMessage("Включить"),
    "undo": MessageLookupByLibrary.simpleMessage("Отменить"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage(
      "Унифицированная задержка",
    ),
    "unifiedDelayDesc": MessageLookupByLibrary.simpleMessage(
      "Убрать дополнительные задержки, такие как рукопожатие",
    ),
    "unknown": MessageLookupByLibrary.simpleMessage("Неизвестно"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "Неизвестная сетевая ошибка",
    ),
    "unnamed": MessageLookupByLibrary.simpleMessage("Без имени"),
    "update": MessageLookupByLibrary.simpleMessage("Обновить"),
    "upload": MessageLookupByLibrary.simpleMessage("Загрузка"),
    "uploadSpeed": MessageLookupByLibrary.simpleMessage("Скорость отдачи"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlDesc": MessageLookupByLibrary.simpleMessage(
      "Получить профиль через URL",
    ),
    "urlTip": m36,
    "useHosts": MessageLookupByLibrary.simpleMessage("Использовать hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage(
      "Использовать системные hosts",
    ),
    "userAgent": MessageLookupByLibrary.simpleMessage("User-Agent"),
    "value": MessageLookupByLibrary.simpleMessage("Значение"),
    "version": MessageLookupByLibrary.simpleMessage("Версия"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("Яркие"),
    "view": MessageLookupByLibrary.simpleMessage("Просмотр"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "Обнаружено изменение конфигурации VPN",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "Автоматически направляет весь системный трафик через VpnService",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage(
      "Изменения вступят в силу после перезапуска VPN",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage(
      "Конфигурация WebDAV",
    ),
    "whitelistMode": MessageLookupByLibrary.simpleMessage(
      "Режим белого списка",
    ),
    "yearsAgo": m37,
    "zh_CN": MessageLookupByLibrary.simpleMessage("Упрощенный китайский"),
  };
}
