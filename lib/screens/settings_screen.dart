import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/glass_panel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/config_provider.dart';
import 'dart:io';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String localIp = 'Unknown';

  @override
  void initState() {
    super.initState();
    _fetchLocalIp();
  }

  Future<void> _fetchLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      if (interfaces.isNotEmpty) {
        setState(() {
          localIp = interfaces.first.addresses.first.address;
        });
      }
    } catch (e) {
      debugPrint("Error fetching IP: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final notifier = ref.read(configProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Настройки (V-Shield)', style: Theme.of(context).textTheme.headlineMedium),
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white, blurRadius: 10, spreadRadius: 2)])),
                  const SizedBox(width: 8),
                  Text('STATUS: PROTECTED', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60, fontSize: 11)),
                  const SizedBox(width: 24),
                  const Icon(Symbols.notifications, color: Colors.white60),
                  const SizedBox(width: 12),
                  const Icon(Symbols.sensors, color: Colors.white60),
                  const SizedBox(width: 12),
                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: const Icon(Symbols.person, size: 20, color: Colors.white)),
                ]),
              ],
            ),
            const SizedBox(height: 40),
            GlassPanel(
              padding: const EdgeInsets.all(32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Symbols.security, color: Colors.white54, size: 24), const SizedBox(width: 12), Text('Уровень защиты (Security Guard)', style: Theme.of(context).textTheme.titleSmall)]),
                const SizedBox(height: 32),
                GridView.count(crossAxisCount: 2, crossAxisSpacing: 48, mainAxisSpacing: 32, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 4, children: [
                  _buildToggleItem(context, 'System Kill Switch', 'Блокирует весь трафик при разрыве соединения.', config.killSwitch, (val) => notifier.updateSettings(killSwitch: val)),
                  _buildToggleItem(context, 'Auto-Connect', 'Автоматическое подключение при запуске системы.', config.autoConnect, (val) => notifier.updateSettings(autoConnect: val)),
                  _buildToggleItem(context, 'LAN Visibility', 'Доступ к локальным устройствам (принтеры, NAS).', config.lanVisibility, (val) => notifier.updateSettings(lanVisibility: val)),
                  _buildToggleItem(context, 'Custom DNS', 'Использование зашифрованных DNS-серверов.', config.customDns, (val) => notifier.updateSettings(customDns: val)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 16, children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  _buildNetworkStat(context, 'LOCAL IP', localIp),
                  _buildDivider(),
                  _buildNetworkStat(context, 'PORT', '10808'),
                  _buildDivider(),
                  _buildNetworkStat(context, 'MTU', '1500'),
                ]),
                OutlinedButton(
                  onPressed: () => notifier.resetSettings(),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  child: Text('Сбросить настройки', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white60)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 24));

  Widget _buildNetworkStat(BuildContext context, String title, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 18, color: Colors.white)),
    ]);
  }

  Widget _buildToggleItem(BuildContext context, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.white54)),
      ])),
      const SizedBox(width: 16),
      Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.black, activeTrackColor: Colors.white, inactiveThumbColor: Colors.white54, inactiveTrackColor: Colors.white10),
    ]);
  }
}
