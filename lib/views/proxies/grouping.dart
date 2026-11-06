import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

/// 代理页的一个分区（地区、最近使用、常用节点、供应商信息等）。
class ProxySection {
  const ProxySection({
    required this.id,
    required this.proxies,
    this.title,
    this.flag,
    this.collapsible = false,
    this.expandedByDefault = true,
  });

  final String id;
  final List<Proxy> proxies;

  /// 为空表示平铺模式，不绘制标题。
  final String? title;
  final String? flag;
  final bool collapsible;
  final bool expandedByDefault;
}

class ProxyRegion {
  const ProxyRegion({
    required this.id,
    required this.label,
    required this.flag,
    required this.aliases,
  });

  final String id;
  final String label;
  final String flag;
  final List<String> aliases;
}

/// 常见机场节点地区。顺序有意义：包含关系的地区排在前面。
const _regions = <ProxyRegion>[
  ProxyRegion(
    id: 'hk',
    label: '香港',
    flag: '🇭🇰',
    aliases: ['香港', '港区', 'hong kong', 'hongkong', 'hk', 'hkg'],
  ),
  ProxyRegion(
    id: 'tw',
    label: '台湾',
    flag: '🇹🇼',
    aliases: ['台湾', '臺灣', '台北', 'taiwan', 'tw', 'tpe'],
  ),
  ProxyRegion(
    id: 'mo',
    label: '澳门',
    flag: '🇲🇴',
    aliases: ['澳门', '澳門', 'macao', 'macau', 'mo', 'mfm'],
  ),
  ProxyRegion(
    id: 'sg',
    label: '新加坡',
    flag: '🇸🇬',
    aliases: ['新加坡', '狮城', 'singapore', 'sg', 'sin'],
  ),
  ProxyRegion(
    id: 'jp',
    label: '日本',
    flag: '🇯🇵',
    aliases: ['日本', '东京', '東京', '大阪', 'japan', 'jp', 'tokyo', 'osaka', 'nrt'],
  ),
  ProxyRegion(
    id: 'kr',
    label: '韩国',
    flag: '🇰🇷',
    aliases: ['韩国', '韓國', '首尔', 'korea', 'kr', 'seoul', 'icn'],
  ),
  ProxyRegion(
    id: 'us',
    label: '美国',
    flag: '🇺🇸',
    aliases: [
      '美国',
      '美國',
      '洛杉矶',
      '圣何塞',
      '西雅图',
      '纽约',
      '达拉斯',
      '芝加哥',
      '硅谷',
      'united states',
      'usa',
      'america',
      'us',
      'lax',
      'sjc',
      'sea',
      'nyc',
    ],
  ),
  ProxyRegion(
    id: 'gb',
    label: '英国',
    flag: '🇬🇧',
    aliases: ['英国', '英國', '伦敦', 'united kingdom', 'britain', 'england', 'uk', 'gb', 'london', 'lon'],
  ),
  ProxyRegion(
    id: 'de',
    label: '德国',
    flag: '🇩🇪',
    aliases: ['德国', '德國', '法兰克福', 'germany', 'de', 'frankfurt', 'fra'],
  ),
  ProxyRegion(
    id: 'fr',
    label: '法国',
    flag: '🇫🇷',
    aliases: ['法国', '法國', '巴黎', 'france', 'fr', 'paris', 'cdg'],
  ),
  ProxyRegion(
    id: 'nl',
    label: '荷兰',
    flag: '🇳🇱',
    aliases: ['荷兰', '荷蘭', '阿姆斯特丹', 'netherlands', 'nl', 'amsterdam', 'ams'],
  ),
  ProxyRegion(
    id: 'ru',
    label: '俄罗斯',
    flag: '🇷🇺',
    aliases: ['俄罗斯', '俄羅斯', '莫斯科', 'russia', 'ru', 'moscow'],
  ),
  ProxyRegion(
    id: 'ca',
    label: '加拿大',
    flag: '🇨🇦',
    aliases: ['加拿大', '多伦多', '温哥华', 'canada', 'ca', 'toronto', 'yvr'],
  ),
  ProxyRegion(
    id: 'au',
    label: '澳大利亚',
    flag: '🇦🇺',
    aliases: ['澳大利亚', '澳洲', '悉尼', 'australia', 'au', 'sydney', 'syd'],
  ),
  ProxyRegion(
    id: 'id',
    label: '印尼',
    flag: '🇮🇩',
    aliases: ['印度尼西亚', '印尼', 'indonesia', 'id', 'jakarta'],
  ),
  ProxyRegion(
    id: 'in',
    label: '印度',
    flag: '🇮🇳',
    aliases: ['印度', 'india', 'in', 'mumbai'],
  ),
  ProxyRegion(
    id: 'my',
    label: '马来西亚',
    flag: '🇲🇾',
    aliases: ['马来西亚', '馬來西亞', '马来', 'malaysia', 'my', 'kuala lumpur'],
  ),
  ProxyRegion(
    id: 'th',
    label: '泰国',
    flag: '🇹🇭',
    aliases: ['泰国', '泰國', '曼谷', 'thailand', 'th', 'bangkok'],
  ),
  ProxyRegion(
    id: 'vn',
    label: '越南',
    flag: '🇻🇳',
    aliases: ['越南', 'vietnam', 'vn', 'hanoi'],
  ),
  ProxyRegion(
    id: 'ph',
    label: '菲律宾',
    flag: '🇵🇭',
    aliases: ['菲律宾', '菲律賓', 'philippines', 'ph', 'manila'],
  ),
  ProxyRegion(
    id: 'tr',
    label: '土耳其',
    flag: '🇹🇷',
    aliases: ['土耳其', 'turkey', 'tr', 'istanbul'],
  ),
  ProxyRegion(
    id: 'ae',
    label: '阿联酋',
    flag: '🇦🇪',
    aliases: ['阿联酋', '迪拜', 'emirates', 'uae', 'dubai', 'ae'],
  ),
  ProxyRegion(
    id: 'br',
    label: '巴西',
    flag: '🇧🇷',
    aliases: ['巴西', 'brazil', 'br', 'sao paulo'],
  ),
  ProxyRegion(
    id: 'ar',
    label: '阿根廷',
    flag: '🇦🇷',
    aliases: ['阿根廷', 'argentina', 'ar', 'buenos aires'],
  ),
  ProxyRegion(
    id: 'ch',
    label: '瑞士',
    flag: '🇨🇭',
    aliases: ['瑞士', 'switzerland', 'ch', 'zurich'],
  ),
  ProxyRegion(
    id: 'se',
    label: '瑞典',
    flag: '🇸🇪',
    aliases: ['瑞典', 'sweden', 'se', 'stockholm'],
  ),
  ProxyRegion(
    id: 'fi',
    label: '芬兰',
    flag: '🇫🇮',
    aliases: ['芬兰', '芬蘭', 'finland', 'fi', 'helsinki'],
  ),
  ProxyRegion(
    id: 'pl',
    label: '波兰',
    flag: '🇵🇱',
    aliases: ['波兰', '波蘭', 'poland', 'pl', 'warsaw'],
  ),
  ProxyRegion(
    id: 'ua',
    label: '乌克兰',
    flag: '🇺🇦',
    aliases: ['乌克兰', '烏克蘭', 'ukraine', 'ua', 'kyiv'],
  ),
  ProxyRegion(
    id: 'cn',
    label: '中国',
    flag: '🇨🇳',
    aliases: ['中国', '中國', '回国', '回國', 'china', 'cn', 'beijing', 'shanghai'],
  ),
];

const _providerInfoKeywords = <String>[
  '官网',
  '官網',
  '网址',
  '網址',
  '地址',
  '邮箱',
  '郵箱',
  '邮件',
  '郵件',
  '联系',
  '聯繫',
  '客服',
  '到期',
  '过期',
  '過期',
  '剩余',
  '剩餘',
  '流量',
  '套餐',
  '续费',
  '續費',
  '购买',
  '購買',
  '订阅',
  '訂閱',
  '更新',
  '重置',
  '公告',
  '通知',
  '交流群',
  '群组',
  '群組',
  '机场',
  '機場',
  '入口',
  '备用',
  '備用',
  '试用',
  '試用',
  'website',
  'expire',
  'traffic',
  'email',
  'support',
  'telegram',
  'renew',
  'subscribe',
];

final _flagPattern = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);

final _urlPattern = RegExp(
  r'https?://|www\.|t\.me/|\.(com|net|org|cn|io|me|us|xyz|top|cc)\b',
  caseSensitive: false,
);

final _ipv4Pattern = RegExp(r'\b\d{1,3}(?:\.\d{1,3}){3}\b');

final _pseudoNames = <String>{
  'DIRECT',
  'REJECT',
  'GLOBAL',
  'PASS',
  'COMPATIBLE',
};

/// 组引用节点（如「国外流量」指向另一个策略组）不是供应商公告。
bool _isGroupReference(Proxy proxy) {
  return GroupType.values.any(
    (type) => type.name == proxy.type || type.value == proxy.type,
  );
}

/// 判断节点名是否更像订阅商附带的公告 / 客服信息，而不是真正的代理节点。
///
/// 只是展示层的归类：被归入「供应商信息」的节点仍可正常选择和使用。
bool isProviderInfoProxyName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (_pseudoNames.contains(trimmed.toUpperCase())) {
    return false;
  }
  final lower = trimmed.toLowerCase();
  if (_providerInfoKeywords.any(lower.contains)) {
    return true;
  }
  if (_urlPattern.hasMatch(lower) || _ipv4Pattern.hasMatch(trimmed)) {
    return true;
  }
  return false;
}

bool _aliasMatches(String name, String lower, String alias) {
  if (_isAscii(alias)) {
    if (alias.length <= 2) {
      // 两字母国家代码只在独立词边界上匹配，避免 Russia / Australia 误判。
      final pattern = RegExp(
        '(^|[^a-z])${RegExp.escape(alias)}([^a-z]|\$)',
      );
      return pattern.hasMatch(lower);
    }
    return lower.contains(alias);
  }
  return name.contains(alias);
}

bool _isAscii(String value) {
  return value.codeUnits.every((unit) => unit < 128);
}

/// 从节点名推断地区。无法识别时返回 null。
ProxyRegion? regionOfProxyName(String name) {
  final flagMatch = _flagPattern.firstMatch(name);
  final flag = flagMatch?.group(0);
  final lower = name.toLowerCase();
  for (final region in _regions) {
    if (flag != null && region.flag == flag) {
      return region;
    }
    for (final alias in region.aliases) {
      if (_aliasMatches(name, lower, alias)) {
        return region;
      }
    }
  }
  if (flag != null) {
    return ProxyRegion(id: 'flag:$flag', label: flag, flag: flag, aliases: const []);
  }
  return null;
}

/// 把节点名转成稳定的地区 key，供分区排序使用。
String regionKeyOfProxyName(String name) {
  return regionOfProxyName(name)?.id ?? 'other';
}

List<ProxySection> buildProxySections({
  required List<Proxy> proxies,
  required ProxiesGroupMode mode,
  required Map<String, NodeUsageEntry> usage,
  required String otherRegionLabel,
  required String recentLabel,
  required String frequentLabel,
  required String providerInfoLabel,
  DateTime? now,
}) {
  if (mode == ProxiesGroupMode.all || proxies.isEmpty) {
    return [
      ProxySection(id: 'all', proxies: proxies),
    ];
  }
  final current = now ?? DateTime.now();
  final real = <Proxy>[];
  final providerInfo = <Proxy>[];
  for (final proxy in proxies) {
    if (!_isGroupReference(proxy) &&
        isProviderInfoProxyName(proxy.name)) {
      providerInfo.add(proxy);
    } else {
      real.add(proxy);
    }
  }

  final recentThreshold = current.subtract(const Duration(days: 7));
  final recent = real.where((proxy) {
    final entry = usage[proxy.name];
    return entry != null && entry.lastUsed.isAfter(recentThreshold);
  }).toList()..sort((a, b) {
    final aTime = usage[a.name]?.lastUsed;
    final bTime = usage[b.name]?.lastUsed;
    if (aTime == null || bTime == null) {
      return 0;
    }
    return bTime.compareTo(aTime);
  });
  final recentNodes = recent.take(4).toList();
  final recentNames = recentNodes.map((proxy) => proxy.name).toSet();

  final frequent = real.where((proxy) {
    final entry = usage[proxy.name];
    return entry != null && entry.count >= 2 && !recentNames.contains(proxy.name);
  }).toList()..sort((a, b) {
    final aEntry = usage[a.name];
    final bEntry = usage[b.name];
    if (aEntry == null || bEntry == null) {
      return 0;
    }
    final byCount = bEntry.count.compareTo(aEntry.count);
    if (byCount != 0) {
      return byCount;
    }
    return bEntry.lastUsed.compareTo(aEntry.lastUsed);
  });
  final frequentNodes = frequent.take(4).toList();

  final buckets = <String, List<Proxy>>{};
  final regions = <String, ProxyRegion?>{};
  for (final proxy in real) {
    final region = regionOfProxyName(proxy.name);
    final key = region?.id ?? 'other';
    regions[key] = region;
    buckets.putIfAbsent(key, () => []).add(proxy);
  }
  final regionSections = buckets.entries.map((entry) {
    final region = regions[entry.key];
    return ProxySection(
      id: 'region:${entry.key}',
      title: region?.label.isNotEmpty == true ? region!.label : otherRegionLabel,
      flag: region?.flag,
      proxies: entry.value,
    );
  }).toList()..sort((a, b) {
    final byCount = b.proxies.length.compareTo(a.proxies.length);
    if (byCount != 0) {
      return byCount;
    }
    return (a.title ?? '').compareTo(b.title ?? '');
  });

  return [
    if (recentNodes.isNotEmpty)
      ProxySection(
        id: 'recent',
        title: recentLabel,
        proxies: recentNodes,
      ),
    if (frequentNodes.isNotEmpty)
      ProxySection(
        id: 'frequent',
        title: frequentLabel,
        proxies: frequentNodes,
      ),
    ...regionSections,
    if (providerInfo.isNotEmpty)
      ProxySection(
        id: 'provider-info',
        title: providerInfoLabel,
        proxies: providerInfo,
        collapsible: true,
        expandedByDefault: false,
      ),
  ];
}
