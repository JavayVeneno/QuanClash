import 'package:quanclash/common/common.dart';
import 'package:quanclash/views/mobile_v4/mobile_v4_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/widgets.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  Widget _buildDesktopView(BuildContext context) {
    const spacing = 10.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: DashboardPalette.background(context),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 运行概览
                  const ConnectionBar(),
                  const SizedBox(height: spacing),
                  // 2. 可用节点 / 覆盖地区 / 节点更新 / 稳定运行
                  const DashboardStats(),
                  const SizedBox(height: spacing),
                  // 3. 网速 7 : 流量 3
                  if (isWide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: NetworkSpeed()),
                        SizedBox(width: spacing),
                        Expanded(flex: 3, child: TrafficUsage()),
                      ],
                    )
                  else ...[
                    const NetworkSpeed(),
                    const SizedBox(height: spacing),
                    const TrafficUsage(),
                  ],
                  const SizedBox(height: spacing),
                  // 4. 系统代理 / 虚拟网卡 / 出站模式
                  if (isWide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: SystemProxyButton()),
                        SizedBox(width: spacing),
                        Expanded(child: TUNButton()),
                        SizedBox(width: spacing),
                        Expanded(flex: 2, child: OutboundModeV2()),
                      ],
                    )
                  else ...[
                    const SystemProxyButton(),
                    const SizedBox(height: spacing),
                    const TUNButton(),
                    const SizedBox(height: spacing),
                    const OutboundModeV2(),
                  ],
                  const SizedBox(height: spacing),
                  // 5. 网络检测 / 风险指数 / 内存 / 内网 IP
                  if (isWide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: NetworkDetection()),
                        SizedBox(width: spacing),
                        Expanded(child: RiskIndex()),
                        SizedBox(width: spacing),
                        Expanded(child: MemoryInfo()),
                        SizedBox(width: spacing),
                        Expanded(child: IntranetIP()),
                      ],
                    )
                  else ...[
                    const Row(
                      children: [
                        Expanded(child: NetworkDetection()),
                        SizedBox(width: spacing),
                        Expanded(child: RiskIndex()),
                      ],
                    ),
                    const SizedBox(height: spacing),
                    const Row(
                      children: [
                        Expanded(child: MemoryInfo()),
                        SizedBox(width: spacing),
                        Expanded(child: IntranetIP()),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (system.isDesktop) {
      return _buildDesktopView(context);
    }
    return const MobileV4Dashboard();
  }
}

