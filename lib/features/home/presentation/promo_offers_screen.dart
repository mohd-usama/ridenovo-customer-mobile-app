import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../data/models/promo_model.dart';
import '../data/repositories/ride_repository.dart';
import '../providers/promo_provider.dart';

class PromoOffersScreen extends ConsumerStatefulWidget {
  final double? currentFare;
  final String? vehicleType;
  final ScrollController? scrollController;

  const PromoOffersScreen({super.key, this.currentFare, this.vehicleType, this.scrollController});

  static Future<String?> show(BuildContext context, {double? currentFare, String? vehicleType}) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: PromoOffersScreen(currentFare: currentFare, vehicleType: vehicleType, scrollController: scrollController),
        ),
      ),
    );
  }

  @override
  ConsumerState<PromoOffersScreen> createState() => _PromoOffersScreenState();
}

class _PromoOffersScreenState extends ConsumerState<PromoOffersScreen> {
  final _customCodeController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    _customCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndApply(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty || _isValidating) return;

    setState(() => _isValidating = true);
    final repo = ref.read(rideRepositoryProvider);

    final res = await repo.validatePromoCode(code: cleanCode, fareAmount: widget.currentFare ?? 150.0);

    if (!mounted) return;
    setState(() => _isValidating = false);

    if (res.isSuccess && res.data != null) {
      Navigator.pop(context, cleanCode);
    } else {
      AppSnackBar.showError(
        context,
        title: 'Invalid Coupon',
        message: res.message != null && res.message!.isNotEmpty ? res.message! : 'Promo code is not applicable.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = PromoFilter(fare: widget.currentFare, vehicleType: widget.vehicleType);
    final promosAsync = ref.watch(promosCatalogProvider(filter));

    return Column(
      children: [
        // Drag Handle
        const Gap(12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Apply Promo & Offers',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        const Divider(height: 1),

        // Custom Code Input Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCodeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _validateAndApply,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code (e.g. WELCOME50)',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const Gap(10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 48), // width 0: Row ke andar infinite width crash nahi hoga
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isValidating ? null : () => _validateAndApply(_customCodeController.text),
                child: _isValidating
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Apply',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Promos List using scrollController
        Expanded(
          child: promosAsync.when(
            data: (catalog) => _buildPromosList(context, catalog.promos, widget.scrollController),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading offers: ${err.toString().replaceAll('Exception: ', '')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromosList(BuildContext context, List<PromoItemModel> promos, ScrollController? scrollController) {
    if (promos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            Gap(12),
            Text(
              'No promo codes available right now.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: promos.length,
      itemBuilder: (context, index) {
        final promo = promos[index];
        final isApplicable = promo.isApplicable;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isApplicable ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade200,
              width: isApplicable ? 1.5 : 1,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        promo.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    promo.formattedDiscount,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const Gap(10),
              Text(
                promo.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              const Gap(2),
              Text(promo.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Gap(10),

              // Not applicable reason badge if any
              if (!isApplicable && promo.reasonNotApplicable != null && promo.reasonNotApplicable!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: Colors.red),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          promo.reasonNotApplicable!,
                          style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 16),
              Row(
                children: [
                  // Expanded: lamba text ho toh overflow nahi hoga
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Min. Fare: ${promo.formattedMinFare}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        if (promo.expiryDateFormatted != null)
                          Text('Expires: ${promo.expiryDateFormatted}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Gap(12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApplicable ? AppColors.primary : Colors.grey.shade300,
                      minimumSize: const Size(0, 40), // width 0: Row ke andar infinite width crash nahi hoga
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: (isApplicable && !_isValidating) ? () => _validateAndApply(promo.code) : null,
                    child: Text(
                      isApplicable ? 'Apply' : 'Not Applicable',
                      style: TextStyle(color: isApplicable ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
