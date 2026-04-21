import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/invoices/data/data_sources/invoice_service.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
