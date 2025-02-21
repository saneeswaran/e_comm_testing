import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';

import '../../../models/notification_model.dart';
import '../../../utility/constants.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  Future<void> sendPlayerIdToServer(String email, String password) async {
    // Get OneSignal Player ID
    String? playerId = await OneSignal.User.pushSubscription.id;

    if (playerId != null) {
      // Send Player ID to backend
      var response = await http.post(
        Uri.parse("${SERVER_URL}:3000/users/"),
        body: jsonEncode({
          "email": email,
          "password": password,
          "playerId": playerId,
        }),
        headers: {"Content-Type": "application/json"},
      );

      log("Response: ${response.body}");
    } else {
      log("OneSignal Player ID not found");
    }
  }

  Future<void> fetchNotifications() async {
    final response = await http
        .get(Uri.parse('${SERVER_URL}/notification/all-notifications'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _notifications = (data['data'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
      notifyListeners();
    }
  }
}
