import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retilda/Views/Delivery/model/deliverymodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  
  final String baseUrl = "https://retilda-fintech.vercel.app";

  Future<String?> _getToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      return userData['data']['token'];
    }
    return null;
  }

  Future<DuePaymentResponse> getAllDuePayments() async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("No token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/Api/getAllDuePaymentCompleted"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      print(response.body);
      return DuePaymentResponse.fromJson(jsonResponse);
    } else {
      throw Exception("Failed to load due payments: ${response.statusCode}");
    }
  }
}
