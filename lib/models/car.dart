class Car {
  final String id;
  final String marque;
  final String matricule;
  final String energyType;
  final String location;
  final String? photo;
  final String? description;
  final bool cityRestriction;
  final List<String> allowedCities;

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
  });
}
