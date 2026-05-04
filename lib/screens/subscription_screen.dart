import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/subscription_provider.dart';
import '../widgets/glass_panel.dart';
import '../core/theme/app_theme.dart';


class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionProvider);
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
                      'Subscriptions', 
                      style: isMobile 
                        ? Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
                        : Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your external server sources.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (isMobile) const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddSubscriptionDialog(context, ref),
                  icon: const Icon(Symbols.add_link, size: 20),
                  label: const Text('ADD SUBSCRIPTION'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            if (subscriptions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 100),
                  child: Column(
                    children: [
                      Icon(Symbols.rss_feed, size: 64, color: Colors.white10),
                      const SizedBox(height: 24),
                      Text('No subscriptions added yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white30)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subscriptions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  return _SubscriptionCard(subscription: sub, isMobile: isMobile);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name (e.g. My Premium VPN)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Subscription URL'),
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
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                ref.read(subscriptionProvider.notifier).addSubscription(
                  nameController.text,
                  urlController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('ADD & FETCH'),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  final bool isMobile;

  const _SubscriptionCard({required this.subscription, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = subscription.lastUpdated;
    final lastUpdatedStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return GlassPanel(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Symbols.rss_feed, color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 24),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subscription.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subscription.url, 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.white30),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text('Last updated: $lastUpdatedStr', 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.white24),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Symbols.refresh, color: Colors.white54, size: 20),
                onPressed: () => ref.read(subscriptionProvider.notifier).fetchSubscription(subscription.id),
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: Icon(Symbols.delete, color: Colors.redAccent.withValues(alpha: 0.5), size: 20),
                onPressed: () => ref.read(subscriptionProvider.notifier).removeSubscription(subscription.id),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );

  }
}
