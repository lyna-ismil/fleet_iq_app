import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car.dart';
import '../services/api_service.dart';

/// Fetches device-paired, available cars for the map.
/// Use ref.invalidate(pairedCarsProvider) to force a refresh.
final pairedCarsProvider = FutureProvider.autoDispose<List<Car>>((ref) async {
  final rawCars = await ApiService.getPairedAvailableCars();
  return rawCars.map((json) => Car.fromJson(json)).toList();
});
