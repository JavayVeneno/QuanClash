import 'package:quanclash/common/context.dart';
import 'package:quanclash/views/config/general.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ConfigView extends StatelessWidget {
  const ConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: context.appLocalizations.basicConfig,
      body: generateListView(generalItems),
    );
  }
}
