import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/security/app_session.dart';

final appSessionProvider = Provider<AppSession>((ref) => AppSession());
