import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

const _setupState = SetupState(
  profileId: null,
  profileLastUpdateDate: null,
  overwriteType: OverwriteType.standard,
  rules: [],
  proxyGroups: [],
  addedRules: [],
  script: null,
  overrideDns: false,
  dns: Dns(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        currentProfileProvider.overrideWith((_) => null),
        setupStateProvider.overrideWith((_, _) async => _setupState),
        setupActionProvider.overrideWith(_RejectedDnsSetup.new),
        coreActionProvider.overrideWith(_AlreadyRunningCore.new),
        initProvider.overrideWithBuild((_, _) => true),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'rejected DNS never invokes the listener startup callback or caches its hash',
    () async {
      var starts = 0;
      final previousHash = globalState.lastConfigMd5;
      final action = container.read(setupActionProvider.notifier);
      await expectLater(
        action.applyProfile(force: true, preloadInvoke: () => starts++),
        throwsStateError,
      );
      expect(starts, 0);
      expect(globalState.lastConfigMd5, previousHash);
      expect(action.startTime, isNull);
    },
  );

  test('normal start validates DNS before starting listeners', () async {
    final action = container.read(setupActionProvider.notifier);
    await action.updateStatus(true);
    expect(action.startTime, isNull);
    expect(container.read(runTimeProvider), isNull);
  });

  test('invalid profiles are not exported as usable YAML', () async {
    final action = container.read(setupActionProvider.notifier);
    expect(await action.getProfileWithId(1), isEmpty);
  });
}

class _RejectedDnsSetup extends SetupAction {
  @override
  Future<RealProfileResult> getProfile({
    required SetupState setupState,
    required PatchClashConfig patchConfig,
  }) async => const RealProfileResult(
    yaml: 'must never be applied',
    md5: 'must never be cached',
    dnsWarnings: [],
    dnsErrors: ['dns-proxy-target-not-found'],
  );
}

class _AlreadyRunningCore extends CoreAction {
  @override
  Future<bool> tryStartCore([bool start = false]) async => false;
}
