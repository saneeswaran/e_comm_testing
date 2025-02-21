import 'dart:developer';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nexara_cart/utility/snack_bar_helper.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../../core/data/data_provider.dart';
import '../../../models/api_response.dart';
import '../../../models/user.dart';
import '../../../services/http_services.dart';
import '../../../utility/constants.dart';
import '../../../utility/functions.dart';
import '../login_screen.dart';

class UserProvider extends ChangeNotifier {
  HttpService service = HttpService();
  final DataProvider _dataProvider;
  final box = GetStorage();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordController2 = TextEditingController();

  String? _playerId; // Store OneSignal Player ID

  UserProvider(this._dataProvider) {
    _initializeOneSignal();
  }

  /// Initialize OneSignal and get the player ID
  Future<void> _initializeOneSignal() async {
    OneSignal.initialize(ONESIGNAL_APP_ID);
    OneSignal.Notifications.requestPermission(true);

    String? id = await OneSignal.User.pushSubscription.id;
    if (id != null) {
      _playerId = id;
      log("✅ OneSignal Player ID: $_playerId");
    } else {
      log("❌ Failed to fetch OneSignal Player ID");
    }
  }

  /// Login user and send playerId
  Future<String?> login() async {
    String email = emailController.text.trim().toLowerCase();
    String pass = passwordController.text;

    log("🔵 Sending Login Request: email=$email, password=$pass"); // ADD THIS

    String? validate = _isEmailPasswordValid(email, pass);
    if (validate != null) {
      return validate;
    }

    try {
      Map<String, dynamic> user = {
        'name': email,
        'password': pass
      }; // FIXED 'name' to 'email'
      log("🟢 Sending data to server: $user"); // LOG DATA BEING SENT

      final response =
          await service.addItem(endpointUrl: 'users/login', itemData: user);

      log("🔴 Server Response: ${response.body}"); // LOG SERVER RESPONSE

      if (response.isOk) {
        final ApiResponse<User> apiResponse = ApiResponse<User>.fromJson(
            response.body,
            (json) => User.fromJson(json as Map<String, dynamic>));

        if (apiResponse.success == true) {
          User? user = apiResponse.data;
          saveLoginInfo(user);
          log('✅ Login success');
          return null;
        } else {
          return '⚠ Failed to login: ${apiResponse.message}';
        }
      } else {
        return '❌ Error: ${response.body?['message'] ?? response.statusText}';
      }
    } catch (e) {
      log("⚠ Exception: $e");
      return 'An error occurred: $e';
    }
  }

  /// Register user and send playerId
  Future<String?> register() async {
    String email = emailController.text.trim().toLowerCase();
    String pass = passwordController.text;
    String pass2 = passwordController2.text;

    String? validate = _isEmailPasswordValid(email, pass);
    if (validate != null) {
      return validate;
    } else if (pass2.isEmpty) {
      return 'Confirm password to proceed.';
    } else if (pass != pass2) {
      return 'Passwords do not match!';
    }

    try {
      Map<String, dynamic> user = {
        'name': email,
        'password': pass,
        'playerId': _playerId ?? "", // Send OneSignal Player ID
      };

      final response =
          await service.addItem(endpointUrl: 'users/register', itemData: user);

      if (response.isOk) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.body, null);

        if (apiResponse.success == true) {
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          log('✅ Registration successful, Player ID saved!');
          return null;
        } else {
          return 'Failed to register: ${apiResponse.message}';
        }
      } else {
        return 'Error: ${response.body?['message'] ?? response.statusText}';
      }
    } catch (e) {
      log(e.toString());
      return 'An error occurred: $e';
    }
  }

  /// Save login info
  Future<void> saveLoginInfo(User? loginUser) async {
    await box.write(USER_INFO_BOX, loginUser?.toJson());
    log("ℹ️ User login info saved.");
  }

  /// Get logged-in user
  User? getLoginUsr() {
    Map<String, dynamic>? userJson = box.read(USER_INFO_BOX);
    User? userLogged = User.fromJson(userJson ?? {});
    return userLogged;
  }

  /// Logout user
  logOutUser() {
    box.remove(USER_INFO_BOX);
    Get.offAll(const LoginScreen());
  }

  /// Validate email and password
  String? _isEmailPasswordValid(String email, String password) {
    bool isEmailEmpty = email.trim().toLowerCase().isEmpty;
    bool isPasswordEmpty = password.isEmpty;
    bool isValidEmail = EmailValidator.validate(email.trim().toLowerCase());
    bool isStrongPassword = validatePassword(password);

    if (isEmailEmpty || isPasswordEmpty || !isValidEmail || !isStrongPassword) {
      if (isEmailEmpty && isPasswordEmpty) {
        return 'Email and password cannot be empty!';
      } else if (isEmailEmpty) {
        return 'Email cannot be empty!';
      } else if (isPasswordEmpty) {
        return 'Password cannot be empty!';
      } else if (!isValidEmail) {
        return 'Email is not valid!';
      } else if (!isStrongPassword) {
        return 'Please use a strong password!';
      }
    }
    return null;
  }
}
