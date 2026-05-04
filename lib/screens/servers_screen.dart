import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/server_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/glass_panel.dart';
import '../widgets/status_glow.dart';
import '../core/theme/app_theme.dart';
import '../core/ping_service.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serverListProvider);
    final config = ref.watch(configProvider);
    final selectedId = config.selectedServerId;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servers', 
                      style: isMobile 
                        ? Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
                        : Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your connection nodes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (isMobile) const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: isMobile ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Symbols.bolt, color: AppTheme.accent),
                      onPressed: () => _pingAllServers(ref, servers),
                      tooltip: 'Ping All Servers',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddServerDialog(context, ref),
                      icon: const Icon(Symbols.add, size: 20),
                      label: const Text('ADD SERVER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            if (servers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 100),
                  child: Column(
                    children: [
                      Icon(Symbols.dns, size: 64, color: Colors.white10),
                      const SizedBox(height: 24),
                      Text('No servers added yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white30)),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 2.5 : 1.4,
                ),
                itemCount: servers.length,
                itemBuilder: (context, index) {
                  final server = servers[index];
                  final isSelected = server.id == selectedId;
                  
                  return _ServerCard(
                    server: server,
                    isSelected: isSelected,
                    onTap: () => ref.read(configProvider.notifier).setSelectedServer(server.id),
                    onDelete: () => ref.read(serverListProvider.notifier).removeServer(server.id),
                  );
                },
              ),
          ],
        ),
      ),
    );

  }

  Future<void> _pingAllServers(WidgetRef ref, List<Server> servers) async {
    for (var server in servers) {
      try {
        final uri = Uri.parse(server.link);
        final ping = await PingService.getTcpPing(uri.host, uri.port);
        ref.read(serverListProvider.notifier).updatePing(server.id, ping);
      } catch (_) {}
    }
  }

  void _showAddServerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add New Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Server Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(labelText: 'VLESS Link'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && linkController.text.isNotEmpty) {
                final newServer = Server(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  link: linkController.text,
                  protocol: ServerProtocol.vless,
                );
                ref.read(serverListProvider.notifier).addServer(newServer);
                Navigator.pop(context);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  final Server server;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ServerCard({
    required this.server,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassPanel(
        highIntensity: isSelected,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusGlow(
                  animate: isSelected,
                  color: isSelected ? AppTheme.accent : Colors.white24,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.delete, size: 18, color: Colors.white24),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              server.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? Colors.white : Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              server.protocol.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  server.ping != null ? '${server.ping} ms' : '-- ms',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: server.ping != null 
                        ? (server.ping! < 150 ? Colors.greenAccent : (server.ping! < 300 ? Colors.orangeAccent : Colors.redAccent))
                        : Colors.white24,
                  ),
                ),
                if (isSelected)
                  const Icon(Symbols.check_circle, color: AppTheme.accent, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
