import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/staff_model.dart';
import 'staff_controller.dart';

class StaffScreen extends GetView<StaffController> {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('staff'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, size: 32, color: AppColors.primary),
            onPressed: () => _showAddStaffDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.staffList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No staff members added', style: Get.textTheme.titleMedium),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showAddStaffDialog(context),
                  child: const Text('Add Staff Member'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          itemCount: controller.staffList.length,
          itemBuilder: (context, index) {
            final staff = controller.staffList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 30, color: AppColors.primary),
                ),
                title: Text(staff.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.roleStr.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    Text(staff.phone),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: staff.status == StaffStatus.active,
                      onChanged: (val) {
                        controller.updateStaffStatus(
                          staff,
                          val ? StaffStatus.active : StaffStatus.inactive,
                        );
                      },
                    ),
                    Text(staff.statusStr, style: TextStyle(fontSize: 10, color: staff.status == StaffStatus.active ? Colors.green : Colors.red)),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final salaryController = TextEditingController();
    StaffRole selectedRole = StaffRole.deliveryBoy;

    Get.dialog(
      AlertDialog(
        title: const Text('Add Staff Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Monthly Salary'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StaffRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: StaffRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedRole = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                controller.addStaffMember(
                  name: nameController.text,
                  phone: phoneController.text,
                  role: selectedRole,
                  salary: double.tryParse(salaryController.text) ?? 0,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}