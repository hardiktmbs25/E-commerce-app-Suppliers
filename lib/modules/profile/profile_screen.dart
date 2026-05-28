// lib/modules/profile/profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        actions: [
          Obx(
                () => TextButton(
              onPressed: controller.toggleEdit,
              child: Text(
                controller.isEditing.value ? 'Cancel' : 'Edit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),

      // ONLY one main Obx
      body: Obx(() {
        final vendor = controller.vendor.value;
        final isEditing = controller.isEditing.value;
        final isSaving = controller.isSaving.value;
        final newImage = controller.newImage.value;

        return Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Avatar ───────────────────────────────────────────────
                GestureDetector(
                  onTap: isEditing ? controller.pickImage : null,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                        AppColors.primary.withOpacity(0.1),
                        backgroundImage: newImage != null
                            ? FileImage(newImage) as ImageProvider
                            : vendor?.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                          vendor!.profileImageUrl!,
                        )
                            : null,
                        child: newImage == null &&
                            vendor?.profileImageUrl == null
                            ? Text(
                          vendor?.name.isNotEmpty == true
                              ? vendor!.name[0].toUpperCase()
                              : 'V',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontFamily: 'Poppins',
                          ),
                        )
                            : null,
                      ),

                      if (isEditing)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  vendor?.businessName ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),

                Text(
                  vendor?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 16),

                // ── Status Banner ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (vendor?.isActive ?? true)
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (vendor?.isActive ?? true) ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (vendor?.isActive ?? true)
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: (vendor?.isActive ?? true) ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (vendor?.isActive ?? true) ? 'Active' : 'Deactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (vendor?.isActive ?? true) ? Colors.green : Colors.red,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: 8),
                        const VerticalDivider(width: 20),
                        GestureDetector(
                          onTap: controller.toggleStatus,
                          child: Text(
                            (vendor?.isActive ?? true) ? 'Deactivate' : 'Activate',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Form Fields ─────────────────────────────────────────
                AbsorbPointer(
                  absorbing: !isEditing,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Full Name',
                        controller: controller.nameCtrl,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Name is required'
                            : null,
                        prefix: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),
                      
                      const SizedBox(height: 14),

                      // Plan Name
                      AppTextField(
                        label: 'Plan Name',
                        controller: controller.planNameCtrl,
                        prefix: const Icon(
                          Icons.card_membership_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),

                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Business Name',
                        controller: controller.businessCtrl,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Business name is required'
                            : null,
                        prefix: const Icon(
                          Icons.storefront_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),

                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Mobile Number',
                        controller: controller.phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefix: const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),

                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'City',
                        controller: controller.cityCtrl,
                        prefix: const Icon(
                          Icons.location_city_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),

                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Address',
                        controller: controller.addressCtrl,
                        maxLines: 2,
                        prefix: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Menu Items ─────────────────────────────────────────
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.subscriptions_outlined,
                  label: 'Subscriptions',
                  onTap: () => Get.toNamed(Routes.subscriptions),
                ),

                // ── Plan Module (Areas & Time Slots) ────────────────────
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Service Plan & Reach',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Areas
                _ExpandableConfigSection(
                  title: 'Service Areas',
                  items: controller.areasList,
                  isEditing: isEditing,
                  addCtrl: controller.areaCtrl,
                  onAdd: controller.addArea,
                  onRemove: controller.removeArea,
                  hint: 'Add area (e.g. Andheri West)',
                  icon: Icons.map_outlined,
                ),

                const SizedBox(height: 12),

                // Time Slots
                _ExpandableConfigSection(
                  title: 'Time Slots',
                  items: controller.timeSlotsList,
                  isEditing: isEditing,
                  addCtrl: controller.timeSlotCtrl,
                  onAdd: controller.addTimeSlot,
                  onRemove: controller.removeTimeSlot,
                  hint: 'Add slot (e.g. 06:00 AM)',
                  icon: Icons.access_time_rounded,
                ),

                const SizedBox(height: 24),

                _MenuTile(
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  onTap: () => Get.toNamed(Routes.analytics),
                ),

                _MenuTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => Get.toNamed(Routes.notifications),
                ),

                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => Get.toNamed(Routes.settings),
                ),

                const SizedBox(height: 8),

                _MenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: AppColors.error,
                  onTap: controller.logout,
                ),

                const SizedBox(height: 24),

                // ── Save Button ────────────────────────────────────────
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 20),
                    child: PrimaryButton(
                      label: 'Save Changes',
                      onTap: controller.save,
                      isLoading: isSaving,
                      icon: Icons.check_rounded,
                    ),
                  ),

                const SizedBox(height: 32),

                // ── Version ────────────────────────────────────────────
                const Text(
                  'VendorTrack v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ExpandableConfigSection extends StatelessWidget {
  final String title;
  final RxList<String> items;
  final bool isEditing;
  final TextEditingController addCtrl;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final String hint;
  final IconData icon;

  const _ExpandableConfigSection({
    required this.title,
    required this.items,
    required this.isEditing,
    required this.addCtrl,
    required this.onAdd,
    required this.onRemove,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (index) {
              return Chip(
                label: Text(
                  items[index],
                  style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                ),
                backgroundColor: AppColors.background,
                deleteIcon: isEditing ? const Icon(Icons.close, size: 14) : null,
                onDeleted: isEditing ? () => onRemove(index) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
              );
            }),
          )),
          if (isEditing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: '',
                    hint: hint,
                    controller: addCtrl,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
