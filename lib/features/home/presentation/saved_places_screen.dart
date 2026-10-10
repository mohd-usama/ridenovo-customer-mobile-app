import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../data/models/saved_address_model.dart';
import '../data/repositories/ride_repository.dart';
import 'add_edit_saved_place_screen.dart';

class SavedPlacesScreen extends ConsumerStatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen> {
  List<SavedAddressModel> _savedPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final repo = ref.read(rideRepositoryProvider);
      final response = await repo.getSavedAddresses();
      if (!mounted) return;
      if (response.isSuccess && response.data != null) {
        setState(() {
          _savedPlaces = response.data!;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
        _savedPlaces = [];
      });
    }
  }

  Future<void> _navigateToAddPlace() async {
    if (_savedPlaces.length >= 5) {
      AppSnackBar.showError(
        context,
        title: 'Limit Reached',
        message: 'Maximum limit of 5 saved addresses reached. Delete an existing address to add a new one.',
      );
      return;
    }

    final result = await Navigator.of(context).push<SavedAddressModel>(MaterialPageRoute(builder: (_) => const AddEditSavedPlaceScreen()));

    if (result != null && mounted) {
      final repo = ref.read(rideRepositoryProvider);
      final response = await repo.addAddress(result);

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _savedPlaces.add(response.data!);
        });
        AppSnackBar.showSuccess(context, title: 'Saved', message: '${result.label} added to favourites successfully!');
      } else {
        AppSnackBar.showError(
          context,
          title: 'Failed',
          message: response.message ?? 'Maximum limit of 5 saved addresses reached. Delete an existing address to add a new one.',
        );
      }
    }
  }

  Future<void> _deletePlace(String id) async {
    final repo = ref.read(rideRepositoryProvider);
    final response = await repo.deleteAddress(id);

    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _savedPlaces.removeWhere((p) => p.id == id);
      });
      AppSnackBar.showSuccess(context, title: 'Deleted', message: 'Saved address removed from favourites.');
    } else {
      AppSnackBar.showError(context, title: 'Error', message: response.message ?? 'Failed to delete address.');
    }
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      case 'gym':
        return Icons.fitness_center_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Favourites',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Max 5 limit counter badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Addresses (${_savedPlaces.length}/5)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      if (_savedPlaces.length >= 5)
                        const Text(
                          'Limit Reached',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                    ],
                  ),
                  const Gap(16),

                  if (_savedPlaces.isEmpty) ...[
                    const Gap(60),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.bookmark_border_rounded, size: 64, color: AppColors.primary),
                          ),
                          const Gap(20),
                          const Text(
                            'No address saved yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Gap(8),
                          const Text(
                            'Add your favorite places like Home, Work or Gym\nfor quick and easy ride booking.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Gap(60),
                  ] else ...[
                    // List of Saved Places
                    ..._savedPlaces.map(
                      (place) => Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(_getIconForLabel(place.label), color: AppColors.primary, size: 22),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        place.label,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      if (place.isDefault) ...[
                                        const Gap(8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'DEFAULT',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const Gap(4),
                                  Text(place.addressText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
                                ],
                              ),
                            ),
                            const Gap(8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 20),
                                  onPressed: () {
                                    AppSnackBar.showSuccess(context, title: 'Edit', message: 'Editing ${place.label}');
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  onPressed: () => _deletePlace(place.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Gap(10),

                  // Add More Button (hidden if max 5 limit reached)
                  if (_savedPlaces.length < 5)
                    GestureDetector(
                      onTap: _navigateToAddPlace,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.add, color: AppColors.textPrimary, size: 22),
                          ),
                          const Gap(16),
                          const Text(
                            'Add More',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'Maximum limit of 5 saved addresses reached. Delete an existing address to add a new one.',
                        style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
