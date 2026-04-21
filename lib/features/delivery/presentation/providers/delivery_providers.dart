import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/features/delivery/data/data_sources/delivery_service.dart'
    as delivery;

final deliveryServiceProvider = Provider<delivery.ApiService>((ref) {
  return delivery.ApiService();
});
