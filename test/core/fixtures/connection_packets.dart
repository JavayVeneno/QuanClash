import 'dart:convert';

import 'package:quanclash/core/connection_updates.dart';

String inspectionId(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';
String inspectionCursor(int n) => n.toRadixString(16).padLeft(32, '0');

Map<String, dynamic> inspectionRecord(
  int n, {
  int upload = 1,
  int download = 2,
}) => {
  'id': inspectionId(n),
  'upload': upload,
  'download': download,
  'start': '2026-10-30T12:30:01.123456789+08:00',
  'chains': ['DIRECT'],
  'providerChains': null,
  'rule': 'Match',
  'rulePayload': '',
  'metadata': {
    'network': 'tcp',
    'type': 'Socks5',
    'sourceIP': '127.0.0.1',
    'destinationIP': '::1',
    'sourcePort': '1234',
    'destinationPort': '443',
    'inboundIP': '',
    'inboundPort': '0',
    'sourceIPASN': '',
    'destinationIPASN': '',
    'inboundName': '',
    'inboundUser': '',
    'rematchName': '',
    'host': 'fixture.invalid',
    'dnsMode': 'normal',
    'uid': 0,
    'dscp': 0,
    'process': 'fixture',
    'processPath': 'C:/fixture.exe',
    'specialProxy': '',
    'specialRules': '',
    'remoteDestination': '',
    'sniffHost': '',
    'sourceGeoIP': null,
    'destinationGeoIP': <String>[],
  },
};

Map<String, dynamic> inspectionCounts(
  int n, {
  int upload = 10,
  int download = 20,
}) => {'id': inspectionId(n), 'upload': upload, 'download': download};

Map<String, dynamic> inspectionWire({
  bool full = true,
  int base = 1,
  int cursor = 2,
  String status = 'ready',
  List<Map<String, dynamic>> upserted = const [],
  List<Map<String, dynamic>> updated = const [],
  List<Map<String, dynamic>> removed = const [],
}) => {
  'schemaVersion': 1,
  'status': status,
  'full': full,
  'baseCursor': status == 'ready' && !full ? inspectionCursor(base) : '',
  'cursor': status == 'ready' ? inspectionCursor(cursor) : '',
  'sampledAt': '2026-10-30T04:31:02.987654321Z',
  'uploadTotal': status == 'inactive' ? 0 : 100,
  'downloadTotal': status == 'inactive' ? 0 : 200,
  'upserted': upserted,
  'updated': updated,
  'removed': removed,
};

ConnectionUpdatePacket inspectionPacket(Map<String, dynamic> value) =>
    ConnectionUpdatePacket.fromJson(jsonDecode(jsonEncode(value)));
