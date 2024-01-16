import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onTapDashboard;
  final VoidCallback onTapProfile;
  final VoidCallback onTapLogout;
  final VoidCallback onTapLocation;

  const Sidebar({
    required this.onTapDashboard,
    required this.onTapProfile,
    required this.onTapLogout,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Dashboard Sidebar'),
          ),
          ListTile(
            title: const Text('Dashboard'),
            onTap: onTapDashboard,
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: onTapProfile,
          ),
          ListTile(
            title: const Text('Location'),
            onTap: onTapLocation,
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: onTapLogout,
          ),
        ],
      ),
    );
  }
}
