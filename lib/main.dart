import 'dart:developer';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cart/cart.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nexara_cart/screen/auth_screen/login_screen.dart';
import 'package:nexara_cart/screen/home_screen.dart';
import 'package:nexara_cart/utility/constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:onesignal_flutter/src/user.dart';
import 'package:provider/provider.dart';

import 'core/data/data_provider.dart';
import 'models/user.dart';
import 'screen/auth_screen/provider/user_provider.dart';
import 'screen/notification_screen/provider/notification_provider.dart';
import 'screen/product_by_category_screen/provider/product_by_category_provider.dart';
import 'screen/product_cart_screen/provider/cart_provider.dart';
import 'screen/product_details_screen/provider/product_detail_provider.dart';
import 'screen/product_favorite_screen/provider/favorite_provider.dart';
import 'screen/profile_screen/provider/profile_provider.dart';
import 'utility/app_theme.dart';
import 'utility/extensions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await GetStorage.init();
  var cart = FlutterCart();

  // Initialize OneSignal
  OneSignal.initialize(ONESIGNAL_APP_ID);

  // Request notification permissions
  OneSignal.Notifications.requestPermission(true);

  // Get Player ID and send to backend
  OneSignal.User.addObserver((event) async {
    if (event.current.id != null) {
      log("OneSignal Player ID: ${event.current.id}");
      await sendPlayerIdToBackend(event.current.id ?? "");
    }
  });

  // Handle notifications when received in foreground
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    log("Notification received in foreground: ${event.notification.jsonRepresentation()}");
  });

  // Handle notification click event
  OneSignal.Notifications.addClickListener((event) {
    log("Notification clicked: ${event.notification.jsonRepresentation()}");
  });

  await cart.initializeCart(isPersistenceSupportEnabled: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DataProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(context.dataProvider),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(context.dataProvider),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductByCategoryProvider(context.dataProvider),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductDetailProvider(context.dataProvider),
        ),
        ChangeNotifierProvider(
          create: (context) => CartProvider(context.userProvider),
        ),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (context) => FavoriteProvider(context.dataProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

extension on OSUserState {
  get id => null;
}

// Function to send Player ID to backend
Future<void> sendPlayerIdToBackend(String playerId) async {
  final box = GetStorage();
  String? userId = box.read("user_id"); // Retrieve user ID from local storage

  if (userId == null) return;

  try {
    var response = await http.post(
      Uri.parse("$SERVER_URL/users/update-player-id"),
      body: {
        "userId": userId,
        "playerId": playerId,
      },
    );

    if (response.statusCode == 200) {
      log("Player ID successfully updated on backend");
    } else {
      log("Failed to update Player ID: ${response.body}");
    }
  } catch (e) {
    log("Error sending Player ID: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    User? loginUser = context.userProvider.getLoginUsr();

    return GetMaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
        },
      ),
      debugShowCheckedModeBanner: false,
      home: loginUser?.sId == null ? const LoginScreen() : const HomeScreen(),
      theme: AppTheme.lightAppTheme,
    );
  }
}
