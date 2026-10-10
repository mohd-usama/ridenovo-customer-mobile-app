import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../data/models/saved_address_model.dart';
import 'location_search_screen.dart';

class AddEditSavedPlaceScreen extends ConsumerStatefulWidget {
  const AddEditSavedPlaceScreen({super.key});

  @override
  ConsumerState<AddEditSavedPlaceScreen> createState() => _AddEditSavedPlaceScreenState();
}

class _AddEditSavedPlaceScreenState extends ConsumerState<AddEditSavedPlaceScreen> {
  String _selectedCategory = 'Home';
  String _addressText = 'Fetching location...';
  LatLng _currentLatLng = const LatLng(20.2961, 85.8245);
  GoogleMapController? _mapController;
  bool _isMapDragging = false;

  final List<String> _categories = ['Home', 'Work', 'Gym', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialLocation();
    });
  }

  Future<void> _fetchInitialLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();
    if (position != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      _currentLatLng = latLng;
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 16.5)));
      _reverseGeocode(latLng);
    } else {
      _reverseGeocode(_currentLatLng);
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() {
      _currentLatLng = location;
    });
    try {
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> addressComponents = [];

        if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
          addressComponents.add(place.street!);
        } else if (place.name != null && place.name!.isNotEmpty) {
          addressComponents.add(place.name!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty && !addressComponents.contains(place.subLocality)) {
          addressComponents.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty && !addressComponents.contains(place.locality)) {
          addressComponents.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty &&
            !addressComponents.contains(place.subAdministrativeArea)) {
          addressComponents.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty && !addressComponents.contains(place.administrativeArea)) {
          addressComponents.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressComponents.add(place.postalCode!);
        }

        final fullAddress = addressComponents.isNotEmpty
            ? addressComponents.join(', ')
            : '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

        if (mounted) {
          setState(() {
            _addressText = fullAddress;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addressText = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentLatLng = position.target;
    if (!_isMapDragging) {
      setState(() {
        _isMapDragging = true;
      });
    }
  }

  void _onCameraIdle() {
    if (_isMapDragging) {
      setState(() {
        _isMapDragging = false;
      });
    }
    _reverseGeocode(_currentLatLng);
  }

  Future<void> _openSearchScreen() async {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
  }

  void _savePlace() {
    if (_addressText.trim().isEmpty || _addressText == 'Fetching location...') {
      AppSnackBar.showError(context, title: 'Error', message: 'Please select a valid address.');
      return;
    }

    final newPlace = SavedAddressModel(
      id: '',
      label: _selectedCategory,
      addressText: _addressText,
      lat: _currentLatLng.latitude,
      lng: _currentLatLng.longitude,
      isDefault: _selectedCategory == 'Home',
    );
    Navigator.of(context).pop(newPlace);
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
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
      body: Stack(
        children: [
          // 1. Google Map Background
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentLatLng, zoom: 15.5),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),

          // 2. Central Pin ("Saving this location")
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 180),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _isMapDragging ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isMapDragging) ...[
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const Gap(8),
                          ],
                          Text(
                            _isMapDragging ? 'Locating...' : 'Saving this location',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(4),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                  Container(width: 4, height: 20, color: Colors.blue.shade700),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          ),

          // 3. Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          // 4. Bottom Sheet: Add to Favourites
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 3)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header & Search button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add to favourites',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.search, size: 18, color: AppColors.primary),
                        label: const Text('Search'),
                        onPressed: _openSearchScreen,
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Selected Address Preview Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.success, size: 22),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            _addressText,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // SAVE LOCATION AS section
                  const Text(
                    'SAVE LOCATION AS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
                  ),
                  const Gap(12),

                  // Category Chips ("Home", "Work", "Gym", "Other")
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getIconForCategory(category), size: 16, color: isSelected ? Colors.white : AppColors.textPrimary),
                            const Gap(6),
                            Text(category),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.secondary,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? AppColors.secondary : Colors.grey.shade300),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Gap(24),

                  // Add to favourite button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _savePlace,
                      child: const Text('Add to favourite', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
