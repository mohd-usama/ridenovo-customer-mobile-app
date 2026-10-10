/// Model representing a saved favorite address (Max 5 limit enforced by backend)
class SavedAddressModel {
  final String id;
  final String label; // "Home", "Work", "Gym", "Other"
  final String addressText;
  final double lat;
  final double lng;
  final bool isDefault;

  SavedAddressModel({
    required this.id,
    required this.label,
    required this.addressText,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    return SavedAddressModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Other',
      addressText: json['addressText']?.toString() ?? json['address']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 28.6139,
      lng: (json['lng'] as num?)?.toDouble() ?? 77.2090,
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'addressText': addressText, 'lat': lat, 'lng': lng, 'isDefault': isDefault};
}
