class GeoValidationResponse {
  final bool? success;
  final String? message;
  final GeoValidationData? data;

  GeoValidationResponse({
    this.success,
    this.message,
    this.data,
  });

  factory GeoValidationResponse.fromJson(Map<String, dynamic> json) {
    return GeoValidationResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? GeoValidationData.fromJson(json['data'])
          : null,
    );
  }
}

class GeoValidationData {
  final String? state;
  final bool? isOperational;
  final String? formattedAddress;
  final GeoCoordinates? coordinates;

  GeoValidationData({
    this.state,
    this.isOperational,
    this.formattedAddress,
    this.coordinates,
  });

  factory GeoValidationData.fromJson(Map<String, dynamic> json) {
    return GeoValidationData(
      state: json['state'],
      isOperational: json['isOperational'],
      formattedAddress: json['formattedAddress'],
      coordinates: json['coordinates'] != null
          ? GeoCoordinates.fromJson(json['coordinates'])
          : null,
    );
  }
}

class GeoCoordinates {
  final double? lat;
  final double? lng;

  GeoCoordinates({
    this.lat,
    this.lng,
  });

  factory GeoCoordinates.fromJson(Map<String, dynamic> json) {
    return GeoCoordinates(
      lat: (json['lat'] is num) ? (json['lat'] as num).toDouble() : null,
      lng: (json['lng'] is num) ? (json['lng'] as num).toDouble() : null,
    );
  }
}

class StateListResponse {
  final bool? success;
  final String? message;
  final List<OperationalState>? data;

  StateListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory StateListResponse.fromJson(Map<String, dynamic> json) {
    return StateListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<OperationalState>.from(
              json['data'].map((item) => OperationalState.fromJson(item)))
          : null,
    );
  }
}

class OperationalState {
  final String? id;
  final String? name;
  final bool? active;

  OperationalState({
    this.id,
    this.name,
    this.active,
  });

  factory OperationalState.fromJson(Map<String, dynamic> json) {
    return OperationalState(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      active: json['active'],
    );
  }
}

class StateActionResponse {
  final bool? success;
  final String? message;
  final OperationalState? data;

  StateActionResponse({
    this.success,
    this.message,
    this.data,
  });

  factory StateActionResponse.fromJson(Map<String, dynamic> json) {
    return StateActionResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? OperationalState.fromJson(json['data'])
          : null,
    );
  }
}
