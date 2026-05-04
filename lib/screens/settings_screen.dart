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
    final isMobile = MediaQuery.of(context).size.width <= 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile) const SizedBox(height: 40),
            Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  'Настройки (V-Shield)', 
                  style: isMobile 
                    ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                    : Theme.of(context).textTheme.headlineMedium,
                ),
                if (isMobile) const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white, blurRadius: 10, spreadRadius: 2)])),
                    const SizedBox(width: 8),
                    Text('STATUS: PROTECTED', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60, fontSize: 11)),
                    if (!isMobile) ...[
                      const SizedBox(width: 24),
                      const Icon(Symbols.notifications, color: Colors.white60),
                      const SizedBox(width: 12),
                      const Icon(Symbols.sensors, color: Colors.white60),
                      const SizedBox(width: 12),
                      Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: const Icon(Symbols.person, size: 20, color: Colors.white)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            GlassPanel(
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Symbols.security, color: Colors.white54, size: 24), const SizedBox(width: 12), Text('Уровень защиты', style: Theme.of(context).textTheme.titleSmall)]),
                const SizedBox(height: 32),
                GridView.count(
                  crossAxisCount: isMobile ? 1 : 2, 
                  crossAxisSpacing: 48, 
                  mainAxisSpacing: 32, 
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  childAspectRatio: isMobile ? 3.5 : 4, 
                  children: [
                    _buildToggleItem(context, 'System Kill Switch', 'Блокирует весь трафик при разрыве.', config.killSwitch, (val) => notifier.updateSettings(killSwitch: val)),
                    _buildToggleItem(context, 'Auto-Connect', 'Авто-подключение при запуске.', config.autoConnect, (val) => notifier.updateSettings(autoConnect: val)),
                    _buildToggleItem(context, 'LAN Visibility', 'Доступ к локальным устройствам.', config.lanVisibility, (val) => notifier.updateSettings(lanVisibility: val)),
                    _buildToggleItem(context, 'Custom DNS', 'Зашифрованные DNS-серверы.', config.customDns, (val) => notifier.updateSettings(customDns: val)),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center, 
                    spacing: isMobile ? 12 : 24,
                    runSpacing: 16,
                    children: [
                      _buildNetworkStat(context, 'LOCAL IP', localIp, isMobile: isMobile),
                      if (!isMobile) _buildDivider(),
                      _buildNetworkStat(context, 'PORT', '10808', isMobile: isMobile),
                      if (!isMobile) _buildDivider(),
                      _buildNetworkStat(context, 'MTU', '1500', isMobile: isMobile),
                    ],
                  ),
                  if (isMobile) const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => notifier.resetSettings(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      minimumSize: isMobile ? const Size(double.infinity, 50) : null,
                    ),
                    child: Text('Сбросить настройки', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white60)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDivider() => Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 24));

  Widget _buildNetworkStat(BuildContext context, String title, String value, {bool isMobile = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: isMobile ? 10 : 11)),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: isMobile ? 14 : 18, color: Colors.white)),
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
