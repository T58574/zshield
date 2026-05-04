import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_button.dart';
import '../core/theme/app_theme.dart';

class PremiumPlanScreen extends ConsumerWidget {
  const PremiumPlanScreen({super.key});

  Future<void> _launchPayment(BuildContext context, String userId) async {
    // Replace this with your actual Platego.io payment link generation logic
    final url = Uri.parse('https://platego.io/pay/zshield_premium?user_id=$userId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch payment page')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Upgrade to Premium'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                'Unlock All Features',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Get access to high-speed servers and no limits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              GlassPanel(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFeatureItem(Icons.speed, 'Unlimited Speed'),
                    _buildFeatureItem(Icons.public, 'Global Server Access'),
                    _buildFeatureItem(Icons.security, 'Priority Support'),
                    const Divider(color: Colors.white12, height: 32),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('200', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 4),
                        Text('RUB/mo', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (!authState.isAuthenticated)
                      const Text(
                        'Please sign in to buy a subscription',
                        style: TextStyle(color: Colors.redAccent),
                      )
                    else
                      GlassButton(
                        onPressed: () => _launchPayment(context, authState.authUser!.id),
                        isPrimary: true,
                        child: const Text('Get Premium Now'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.accent),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
