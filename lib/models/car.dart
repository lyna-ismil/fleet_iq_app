import 'package:latlong2/latlong.dart';

class Car {
  final String id;
  final String marque;
  final String matricule;
  final String energyType;
  final dynamic location; // Can be String or Map
  final String? photo;
  final String? description;
  final bool cityRestriction;
  final List<String> allowedCities;
  final String? deviceId;
  final String healthStatus;
  final LatLng? lastKnownLocation;
  final String availabilityStatus;

  // Transient field set after distance calculation
  double? calculatedDistance;

  Car({
    required this.id,
    required this.marque,
    required this.matricule,
    required this.energyType,
    required this.location,
    this.photo,
    this.description,
    this.cityRestriction = false,
    this.allowedCities = const [],
    this.deviceId,
    this.healthStatus = "OK",
    this.lastKnownLocation,
    this.availabilityStatus = "AVAILABLE",
    this.calculatedDistance,
  });

  bool get isPaired => deviceId != null;
  bool get isAvailable => availabilityStatus == "AVAILABLE" && isPaired;

  factory Car.fromJson(Map<String, dynamic> json) {
    LatLng? location;
    if (json['lastKnownLocation'] != null && json['lastKnownLocation'] is Map) {
      final loc = json['lastKnownLocation'];
      if (loc['lat'] != null && loc['lng'] != null) {
        location = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
      }
    }

    return Car(
      id: json['_id'] ?? json['id'] ?? '',
      marque: json['marque'] ?? '',
      matricule: json['matricule'] ?? '',
      energyType: json['energyType'] ?? '',
      location: json['location'],
      photo: json['photo'] as String?,
      description: json['description'] as String?,
      cityRestriction: json['cityRestriction'] ?? false,
      allowedCities: json['allowedCities'] != null
          ? List<String>.from(json['allowedCities'])
          : [],
      deviceId: json['deviceId'] as String?,
      healthStatus: json['healthStatus'] ?? "OK",
      lastKnownLocation: location,
      availabilityStatus: (json['availability'] != null && json['availability'] is Map)
          ? json['availability']['status'] ?? "AVAILABLE"
          : json['availabilityStatus'] ?? "AVAILABLE",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'marque': marque,
      'matricule': matricule,
      'energyType': energyType,
      'location': location,
      'photo': photo,
      'description': description,
      'cityRestriction': cityRestriction,
      'allowedCities': allowedCities,
      'deviceId': deviceId,
      'healthStatus': healthStatus,
      'lastKnownLocation': lastKnownLocation != null
          ? {'lat': lastKnownLocation!.latitude, 'lng': lastKnownLocation!.longitude}
          : null,
      'availabilityStatus': availabilityStatus,
    };
  }

  bool get isMapReady => isPaired && location != null;
  bool get isWorking => true;
}
