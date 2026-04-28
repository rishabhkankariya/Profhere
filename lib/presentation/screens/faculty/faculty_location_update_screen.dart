import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/faculty_location_provider.dart';
import '../../providers/auth_provider.dart';

/// Screen for faculty to manually update their location
/// In production, this would be done automatically by NodeMCU
class FacultyLocationUpdateScreen extends ConsumerStatefulWidget {
  const FacultyLocationUpdateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FacultyLocationUpdateScreen> createState() =>
      _FacultyLocationUpdateScreenState();
}

class _FacultyLocationUpdateScreenState
    extends ConsumerState<FacultyLocationUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _building = 'IT Building';
  String _floor = 'Ground Floor';
  String _zone = 'South Block';
  String _cabinId = 'S-920';
  String _nodeMcuIp = '192.168.1.33';
  bool _isPresent = true;
  bool _isUpdating = false;

  final List<String> _buildings = [
    'IT Building',
    'Main Building',
    'Library Building',
    'Admin Block',
  ];

  final List<String> _floors = [
    'Ground Floor',
    'First Floor',
    'Second Floor',
    'Third Floor',
    'Fourth Floor',
  ];

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _isUpdating = true);

    await ref.read(facultyLocationNotifierProvider.notifier).updateLocation(
          facultyId: user.id,
          building: _building,
          floor: _floor,
          zone: _zone,
          cabinId: _cabinId,
          nodeMcuIp: _nodeMcuIp,
          isPresent: _isPresent,
        );

    setState(() => _isUpdating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPresent
              ? 'Location updated successfully!'
              : 'Marked as absent'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _markAbsent() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _isUpdating = true);

    await ref
        .read(facultyLocationNotifierProvider.notifier)
        .markAbsent(user.id);

    setState(() {
      _isUpdating = false;
      _isPresent = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as absent'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update My Location'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This simulates NodeMCU updating your location. In production, NodeMCU will do this automatically every 10-15 minutes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Current location display
              if (user != null)
                ref.watch(facultyLocationProvider(user.id)).when(
                      data: (location) {
                        if (location != null) {
                          return _buildCurrentLocation(location);
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

              const SizedBox(height: 24),

              // Presence toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPresent
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _isPresent ? AppColors.success : AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I am currently present',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isPresent,
                      onChanged: (value) => setState(() => _isPresent = value),
                      activeColor: AppColors.success,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Building dropdown
              _buildDropdown(
                label: 'Building',
                value: _building,
                items: _buildings,
                onChanged: (value) => setState(() => _building = value!),
              ),

              const SizedBox(height: 16),

              // Floor dropdown
              _buildDropdown(
                label: 'Floor',
                value: _floor,
                items: _floors,
                onChanged: (value) => setState(() => _floor = value!),
              ),

              const SizedBox(height: 16),

              // Zone text field
              TextFormField(
                initialValue: _zone,
                decoration: const InputDecoration(
                  labelText: 'Zone / Area',
                  hintText: 'e.g., South Block, North Wing',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
                onSaved: (value) => _zone = value ?? '',
              ),

              const SizedBox(height: 16),

              // Cabin ID text field
              TextFormField(
                initialValue: _cabinId,
                decoration: const InputDecoration(
                  labelText: 'Cabin / Room',
                  hintText: 'e.g., S-920',
                  prefixIcon: Icon(Icons.meeting_room_rounded),
                ),
                onSaved: (value) => _cabinId = value ?? '',
              ),

              const SizedBox(height: 16),

              // NodeMCU IP text field
              TextFormField(
                initialValue: _nodeMcuIp,
                decoration: const InputDecoration(
                  labelText: 'NodeMCU IP Address',
                  hintText: 'e.g., 192.168.1.33',
                  prefixIcon: Icon(Icons.router_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter NodeMCU IP';
                  }
                  return null;
                },
                onSaved: (value) => _nodeMcuIp = value ?? '',
              ),

              const SizedBox(height: 32),

              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _updateLocation,
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.update_rounded),
                  label: Text(_isUpdating ? 'Updating...' : 'Update Location'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Mark absent button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _markAbsent,
                  icon: const Icon(Icons.person_off_rounded),
                  label: const Text('Mark as Absent'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocation(dynamic location) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: location.isPresent
            ? AppColors.successBg
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: location.isPresent
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                location.isPresent
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                color: location.isPresent
                    ? AppColors.success
                    : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: location.isPresent
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      'Updated ${location.timeAgo}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (location.isPresent) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow('Building', location.building),
            _infoRow('Floor', location.floor),
            if (location.zone != null) _infoRow('Zone', location.zone!),
            if (location.cabinId != null) _infoRow('Cabin', location.cabinId!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_rounded),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
