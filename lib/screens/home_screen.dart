library home_screen;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'encrypt_message_screen.dart';
import 'decrypt_message_screen.dart';
import 'encrypt_image_screen.dart';
import 'decrypt_image_screen.dart';
import 'file_sender_screen.dart';
import 'secure_chat_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;
  final int selectedIndex;
  final Function(int) onTabChanged;

  const HomeScreen({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
    required this.selectedIndex,
    required this.onTabChanged,
  }) : super(key: key);

  List<Widget> get _widgetOptions => <Widget>[
    HomeContent(
      isDarkMode: isDarkMode,
      toggleTheme: toggleTheme,
    ),
    SettingsScreen(
      isDarkMode: isDarkMode,
      toggleTheme: toggleTheme,
    ),
    ProfileScreen(),
    NotificationsScreen(),
    FileSenderScreen(),
    SecureChatScreen(),
  ];

  void _showNotificationsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Notifications'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Notification 1'),
                Text('Notification 2'),
                Text('Notification 3'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('View More'),
              onPressed: () {
                Navigator.of(context).pop();
                onTabChanged(3);
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SCC - Secure - Chat - Crypt'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationsPopup(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => onTabChanged(1),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Log out",
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 36, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: theme.colorScheme.primary),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                onTabChanged(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.primary),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                onTabChanged(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: theme.colorScheme.primary),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                onTabChanged(2);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.primary),
              title: const Text('Log out'),
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_upload),
            label: 'File Sender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Secure Chat',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: onTabChanged,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const HomeContent({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildUserProfileSection(context, user, theme),
          const SizedBox(height: 20),
          _buildQuickActionsSection(context, theme),
          const SizedBox(height: 20),
          _buildRecentActivitiesSection(theme),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context, User? user, ThemeData theme) {
    final String displayName = user?.displayName ?? 'No Name';
    final String email = user?.email ?? 'No Email';
    final String? photoURL = user?.photoURL;

    return Card(
      color: theme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 40,
              backgroundImage: photoURL != null
                  ? NetworkImage(photoURL)
                  : const AssetImage('assets/images/profile_picture.png') as ImageProvider,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Member since: January 2025',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/settings',
                        arguments: {
                          'isDarkMode': isDarkMode,
                          'toggleTheme': toggleTheme,
                        },
                      );
                    },
                    child: const Text('Settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Quick Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _buildQuickActionButton(
                    context,
                    theme,
                    Icons.lock,
                    'Encrypt Message',
                    EncryptMessageScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    theme,
                    Icons.lock_open,
                    'Decrypt Message',
                    DecryptMessageScreen(prefilledEncryptedText: '',),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    theme,
                    Icons.image,
                    'Encrypt Image',
                    EncryptImageScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    theme,
                    Icons.image_search,
                    'Decrypt Image',
                    DecryptImageScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    theme,
                    Icons.file_upload,
                    'File Sender',
                    FileSenderScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    theme,
                    Icons.chat,
                    'Secure Chat',
                    SecureChatScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context, ThemeData theme, IconData icon, String label, Widget screen) {
    return Column(
      children: <Widget>[
        FloatingActionButton(
          heroTag: label,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
          backgroundColor: theme.colorScheme.primary,
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildRecentActivitiesSection(ThemeData theme) {
    final activities = _fetchRecentActivities();
    return Card(
      color: theme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recent Activities',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            ...activities.map((activity) =>
                _buildActivityItem(theme, activity['description']!, activity['timeAgo']!)).toList(),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _fetchRecentActivities() {
    // Mock data - replace with actual data fetching logic
    return [
      {'description': 'Encrypted a message', 'timeAgo': '2 hours ago'},
      {'description': 'Decrypted an image', 'timeAgo': '4 hours ago'},
      {'description': 'Sent a secure file', 'timeAgo': '1 day ago'},
    ];
  }

  Widget _buildActivityItem(ThemeData theme, String activity, String timeAgo) {
    return ListTile(
      leading: Icon(Icons.history, color: theme.colorScheme.primary),
      title: Text(activity, style: theme.textTheme.bodyMedium),
      subtitle: Text(timeAgo, style: theme.textTheme.bodySmall),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text('No new notifications', style: theme.textTheme.titleLarge),
    );
  }
}