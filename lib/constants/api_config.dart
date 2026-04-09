// lib/constants/api_config.dart

const String baseApiUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.5:5000',
);

// Gateway-exposed routes:
const String authEndpoint         = "$baseApiUrl/auth";
const String userEndpoint         = "$baseApiUrl/users";
const String bookingEndpoint      = "$baseApiUrl/bookings";
const String carEndpoint          = "$baseApiUrl/cars";
const String reclamationEndpoint  = "$baseApiUrl/reclamations";
const String adminEndpoint        = "$baseApiUrl/admins";
const String deviceEndpoint       = "$baseApiUrl/devices";
const String notificationEndpoint = "$baseApiUrl/notifications";

// Pricing API (separate service)
const String pricingApiUrl              = "http://85.214.12.71:8000";
const String pricingEstimateEndpoint    = "$pricingApiUrl/estimate";
const String pricingVehiclesEndpoint    = "$pricingApiUrl/vehicles";
const String pricingLocationsEndpoint   = "$pricingApiUrl/locations";
