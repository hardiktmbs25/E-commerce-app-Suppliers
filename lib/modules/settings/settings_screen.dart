// lib/modules/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import 'settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance
          _SectionLabel('Appearance'),
          Obx(() => _SwitchTile(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            subtitle: 'Switch between light and dark theme',
            value: controller.isDarkMode.value,
            onChanged: controller.toggleDarkMode,
          )),
          const SizedBox(height: 20),

          // Notifications
          _SectionLabel('Notifications'),
          Obx(() => _SwitchTile(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery Reminders',
            subtitle: 'Get alerted before your delivery window',
            value: controller.deliveryReminders.value,
            onChanged: controller.toggleDeliveryReminders,
          )),
          const SizedBox(height: 8),
          Obx(() => _SwitchTile(
            icon: Icons.payments_outlined,
            label: 'Payment Reminders',
            subtitle: 'Remind customers about pending dues',
            value: controller.paymentReminders.value,
            onChanged: controller.togglePaymentReminders,
          )),
          const SizedBox(height: 8),
          Obx(() => _SwitchTile(
            icon: Icons.summarize_outlined,
            label: 'Daily Summary',
            subtitle: 'Receive end-of-day delivery summary',
            value: controller.dailySummaryNotification.value,
            onChanged: controller.toggleDailySummary,
          )),
          const SizedBox(height: 8),
          // Reminder time
          Obx(() => _TapTile(
            icon: Icons.schedule_rounded,
            label: 'Reminder Time',
            subtitle: controller.reminderTime.value,
            onTap: () => _showTimePicker(context),
          )),
          const SizedBox(height: 20),

          // Data & Storage
          _SectionLabel('Data & Storage'),
          _TapTile(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear Local Cache',
            subtitle: 'Free up space — data will re-sync from server',
            onTap: () async {
              final confirm = await showConfirmDialog(
                title: 'Clear Cache',
                message:
                'This will clear locally cached data. All data remains safe on the server.',
                confirmLabel: 'Clear',
                isDangerous: false,
              );
              if (confirm == true) controller.clearCache();
            },
          ),
          const SizedBox(height: 20),

          // About
          _SectionLabel('About'),
          _InfoTile(
              icon: Icons.info_outline_rounded,
              label: 'App Version',
              value: '1.0.0'),
          _InfoTile(
              icon: Icons.business_rounded,
              label: 'Product',
              value: 'VendorTrack'),
          _InfoTile(
              icon: Icons.support_outlined,
              label: 'Support',
              value: 'support@vendortrack.app'),
          const SizedBox(height: 32),

          // Firebase note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Offline-First Mode Active',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'Poppins')),
                      SizedBox(height: 2),
                      Text(
                        'All changes sync automatically when connected.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked != null && context.mounted) {
      final formatted =
      picked.format(context); // e.g. "06:00 AM"
      controller.setReminderTime(formatted);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 0.8,
            fontFamily: 'Poppins'),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins')),
            Text(subtitle,
                style: const TextStyle(fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins')),
          ],
        )),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ]),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TapTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins')),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
            ],
          )),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.textHint, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary,
                fontFamily: 'Poppins')),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
      ]),
    );
  }
}
