class BookingModel {
  final String id;
  final String userId;
  final String carId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? contractUrl;
  final String? preRentalImage;
  final String? nfcKey;
  final DateTime? keyExpiresAt;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? car;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.carId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.pickupLocation,
    this.dropoffLocation,
    this.contractUrl,
    this.preRentalImage,
    this.nfcKey,
    this.keyExpiresAt,
    this.payment,
    this.car,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      carId: json['carId'] ?? '',
      status: json['status'] ?? 'PENDING',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      pickupLocation: json['pickupLocation'] as String?,
      dropoffLocation: json['dropoffLocation'] as String?,
      contractUrl: json['contractUrl'] as String?,
      preRentalImage: json['preRentalImage'] as String?,
      nfcKey: json['current_Key_car'] ?? json['currentNfcKey'] as String?,
      keyExpiresAt: json['keyExpiresAt'] != null
          ? DateTime.parse(json['keyExpiresAt'])
          : null,
      payment: json['payment'] as Map<String, dynamic>?,
      car: json['car'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'carId': carId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'contractUrl': contractUrl,
      'preRentalImage': preRentalImage,
      'currentNfcKey': nfcKey,
      'keyExpiresAt': keyExpiresAt?.toIso8601String(),
      'payment': payment,
      'car': car,
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? carId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? pickupLocation,
    String? dropoffLocation,
    String? contractUrl,
    String? preRentalImage,
    String? nfcKey,
    DateTime? keyExpiresAt,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? car,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      contractUrl: contractUrl ?? this.contractUrl,
      preRentalImage: preRentalImage ?? this.preRentalImage,
      nfcKey: nfcKey ?? this.nfcKey,
      keyExpiresAt: keyExpiresAt ?? this.keyExpiresAt,
      payment: payment ?? this.payment,
      car: car ?? this.car,
    );
  }
}
