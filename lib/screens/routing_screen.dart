import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/glass_panel.dart';
import '../providers/config_provider.dart';
import '../widgets/status_glow.dart';
import '../core/theme/app_theme.dart';

class RoutingScreen extends ConsumerStatefulWidget {
  const RoutingScreen({super.key});

  @override
  ConsumerState<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends ConsumerState<RoutingScreen> {
  List<String> _runningApps = [];
  bool _isLoadingApps = false;

  @override
  void initState() {
    super.initState();
    _fetchRunningApps();
  }

  Future<void> _fetchRunningApps() async {
    setState(() {
      _isLoadingApps = true;
    });

    try {
      if (Platform.isWindows) {
        // Fetch running apps using tasklist
        final result = await Process.run('tasklist', ['/fo', 'csv', '/nh']);
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          final lines = output.split('\n');
          final Set<String> uniqueApps = {};
          
          for (var line in lines) {
            if (line.trim().isEmpty) continue;
            final parts = line.split('","');
            if (parts.isNotEmpty) {
              String appName = parts[0].replaceAll('"', '').trim();
              if (appName.isNotEmpty && appName != 'svchost.exe' && appName != 'System Idle Process' && appName != 'System') {
                uniqueApps.add(appName);
              }
            }
          }
          
          setState(() {
            _runningApps = uniqueApps.toList()..sort();
          });
        }
      } else {
        // Mock data for non-Windows
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _runningApps = ['chrome.exe', 'discord.exe', 'telegram.exe', 'spotify.exe', 'steam.exe'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching apps: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingApps = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final isProxy = config.isProxyMode;

    final isMobile = MediaQuery.of(context).size.width <= 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile) const SizedBox(height: 40),
            // Header
            Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  'Routing (V-Shield)',
                  style: isMobile 
                    ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                    : Theme.of(context).textTheme.headlineMedium,
                ),
                if (isMobile) const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusGlow(
                      animate: true,
                      color: AppTheme.accent,
                      blurRadius: 10,
                      spreadRadius: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('STATUS: PROTECTED', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60, fontSize: 11)),
                    if (!isMobile) ...[
                      const SizedBox(width: 24),
                      const Icon(Symbols.notifications, color: Colors.white60),
                      const SizedBox(width: 12),
                      const Icon(Symbols.sensors, color: Colors.white60),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Symbols.person, size: 20, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Mode Selection
            GlassPanel(
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Symbols.route, color: Colors.white54, size: 24),
                      const SizedBox(width: 12),
                      Text('Режим работы', style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    children: [
                      _ModeCard(
                        title: 'Tunneling (System-wide)',
                        description: 'Весь трафик системы проходит через защищенный туннель.',
                        isSelected: !isProxy,
                        onTap: () => ref.read(configProvider.notifier).setRoutingMode(false),
                        icon: Symbols.vpn_lock,
                        isMobile: isMobile,
                      ),
                      if (isMobile) const SizedBox(height: 16) else const SizedBox(width: 24),
                      _ModeCard(
                        title: 'Proxy (App-specific)',
                        description: 'Только выбранные приложения проходят через прокси.',
                        isSelected: isProxy,
                        onTap: () => ref.read(configProvider.notifier).setRoutingMode(true),
                        icon: Symbols.filter_alt,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Apps List
            GlassPanel(
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Symbols.apps, color: Colors.white54, size: 24),
                          const SizedBox(width: 12),
                          Text(isMobile ? 'Активные прил.' : 'Активные приложения', style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Symbols.refresh, color: Colors.white54),
                        onPressed: _isLoadingApps ? null : _fetchRunningApps,
                        tooltip: 'Обновить список',
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Выберите приложения, которые должны использовать соединение.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_isLoadingApps)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ))
                  else if (_runningApps.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('Нет активных приложений.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _runningApps.map((appName) {
                        final isRouted = config.routedApps.contains(appName);
                        return Container(
                          width: isMobile ? double.infinity : 300,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: isRouted ? 0.4 : 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Symbols.terminal, color: Colors.white54, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  appName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isRouted ? Colors.white : Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Switch(
                                value: isRouted,
                                onChanged: (val) => ref.read(configProvider.notifier).toggleAppRouting(appName),
                                activeThumbColor: Colors.black,
                                activeTrackColor: Colors.white,
                                inactiveThumbColor: Colors.white54,
                                inactiveTrackColor: Colors.white10,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final bool isMobile;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: isMobile ? 24 : 32),
                if (isSelected)
                  Icon(Symbols.check_circle, color: Colors.white, size: isMobile ? 20 : 24),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              title,
              style: (isMobile ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.titleMedium)?.copyWith(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontSize: isMobile ? 10 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

