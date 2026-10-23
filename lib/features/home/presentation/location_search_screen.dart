import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../data/models/ride_models.dart';
import '../data/repositories/ride_repository.dart';
import '../providers/ride_provider.dart';
import 'widgets/book_for_someone_else_sheet.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

  // Track which textfield is currently active for map pinning or search selection ('pickup' or 'drop')
  String _activeField = 'drop';

  List<LocationSuggestionModel> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final rideState = ref.read(rideProvider);
    _pickupController.text = rideState.pickupAddress ?? 'Current Location (Wazirabad, New Delhi)';
    _dropController.text = rideState.dropAddress ?? '';

    // Load initial recommendations/recent history
    _fetchSuggestions('New Delhi');
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final repo = ref.read(rideRepositoryProvider);
    final request = SearchLocationRequest(query: query);
    final response = await repo.searchLocations(request);

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        _suggestions = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSelectSuggestion(LocationSuggestionModel suggestion) {
    setState(() {
      final fullAddress = '${suggestion.title}, ${suggestion.subtitle}';
      if (_activeField == 'pickup') {
        _pickupController.text = suggestion.title;
        ref.read(rideProvider.notifier).setPickupLocation(LatLng(suggestion.latitude ?? 28.6139, suggestion.longitude ?? 77.2090), fullAddress);
        _activeField = 'drop';
        _suggestions = [];
      } else {
        _dropController.text = suggestion.title;
        ref.read(rideProvider.notifier).setDropLocation(LatLng(suggestion.latitude ?? 28.6139, suggestion.longitude ?? 77.2090), fullAddress);

        final place = RecentPlaceModel(
          id: '',
          placeId: suggestion.placeId,
          title: suggestion.title,
          subtitle: suggestion.subtitle,
          lat: suggestion.latitude ?? 28.6139,
          lng: suggestion.longitude ?? 77.2090,
          isFavorite: false,
        );
        ref.read(rideRepositoryProvider).addRecentPlace(place);
        ref.invalidate(recentPlacesProvider);

        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final isForSomeoneElse = rideState.isBookingForSomeoneElse;
    final passengerLabel = isForSomeoneElse ? (rideState.passengerName ?? 'Someone else') : 'For me';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // "For me" booking dropdown
          GestureDetector(
            onTap: () {
              BookForSomeoneElseSheet.show(context);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isForSomeoneElse ? AppColors.primary : Colors.grey.shade300, width: isForSomeoneElse ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Icon(
                    isForSomeoneElse ? Icons.people : Icons.person,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const Gap(6),
                  Text(
                    passengerLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Input Section (Pickup & Drop)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Indicator dots & line
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                            ),
                          ),
                          Container(width: 2, height: 32, color: Colors.grey.shade300),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                            ),
                          ),
                        ],
                      ),
                      const Gap(14),

                      // Textfields
                      Expanded(
                        child: Column(
                          children: [
                            // Pickup Field
                            GestureDetector(
                              onTap: () => setState(() => _activeField = 'pickup'),
                              child: AbsorbPointer(
                                absorbing: _activeField != 'pickup',
                                child: TextField(
                                  controller: _pickupController,
                                  onChanged: (val) => _fetchSuggestions(val),
                                  decoration: InputDecoration(
                                    hintText: 'Pickup location',
                                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                                    filled: true,
                                    fillColor: _activeField == 'pickup' ? AppColors.background : Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Gap(10),

                            // Drop Field
                            GestureDetector(
                              onTap: () => setState(() => _activeField = 'drop'),
                              child: AbsorbPointer(
                                absorbing: _activeField != 'drop',
                                child: TextField(
                                  controller: _dropController,
                                  autofocus: true,
                                  onChanged: (val) => _fetchSuggestions(val),
                                  decoration: InputDecoration(
                                    hintText: 'Drop location',
                                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                                    filled: true,
                                    fillColor: _activeField == 'drop' ? AppColors.background : Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),

                      // Add Stop Button (+)
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 22),
                        onPressed: () {
                          AppSnackBar.showSuccess(context, title: 'Multi-Stop', message: 'Add stop feature enabled');
                        },
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Map Picker Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.background,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                      label: const Text('Map', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        AppSnackBar.showSuccess(context, title: 'Map Picker', message: 'Pin location from map for $_activeField');
                        // Simulate selecting a pinned location from map
                        if (_activeField == 'pickup') {
                          _pickupController.text = 'Connaught Place, New Delhi';
                        } else {
                          _dropController.text = 'IGI Airport Terminal 3, New Delhi';
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Search Results List (API Autocomplete)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _suggestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 48, color: Colors.grey.shade400),
                          const Gap(12),
                          const Text(
                            'Search for locations above',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                            child: const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
                          ),
                          title: Text(
                            suggestion.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            suggestion.subtitle,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite_border, color: AppColors.textSecondary, size: 20),
                            onPressed: () {
                              AppSnackBar.showSuccess(context, title: 'Favourite', message: '${suggestion.title} added to favourites');
                            },
                          ),
                          onTap: () {
                            _onSelectSuggestion(suggestion);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
