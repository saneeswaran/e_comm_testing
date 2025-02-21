import 'package:flutter/material.dart';
import 'package:nexara_cart/screen/auth_screen/components/square_tile.dart';
import 'package:nexara_cart/utility/constants.dart';
import 'package:provider/provider.dart';

import 'provider/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return provider.notifications.isEmpty
              ? Center(
                  child: Container(
                  height: 300,
                  width: 500,
                  decoration: const BoxDecoration(
                      image:
                          DecorationImage(image: AssetImage(noNotifications))),
                ))
              : ListView.builder(
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return Card(
                      child: ListTile(
                        title: Text(notification.title ?? "No title"),
                        subtitle:
                            Text(notification.description ?? "No description"),
                        trailing: notification.imageUrl != null
                            ? Image.network(notification.imageUrl!,
                                width: 50, height: 50)
                            : null,
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
