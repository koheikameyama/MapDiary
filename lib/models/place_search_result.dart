class PlaceSearchResult {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceSearchResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? json['formatted_address'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: (location['lat'] ?? 0).toDouble(),
      longitude: (location['lng'] ?? 0).toDouble(),
    );
  }
}
