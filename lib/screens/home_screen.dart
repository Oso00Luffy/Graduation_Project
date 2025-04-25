/// Home screen for Secure Chat Crypt application.
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

// Define your aqua blue color
const Color aquaBlue = Color(0xFF1ECBE1);

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const HomeScreen({Key? key, required this.isDarkMode, required this.toggleTheme}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Widget> get _widgetOptions => <Widget>[
    HomeContent(
      isDarkMode: widget.isDarkMode,
      toggleTheme: widget.toggleTheme,
    ),
    SettingsScreen(
      isDarkMode: widget.isDarkMode,
      toggleTheme: widget.toggleTheme,
    ),
    ProfileScreen(),
    NotificationsScreen(),
    FileSenderScreen(),
    SecureChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _showNotificationsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                _onItemTapped(3);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0FBFD),
      appBar: AppBar(
        title: const Text('SCC - Secure - Chat - Crypt'),
        backgroundColor: aquaBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationsPopup(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _onItemTapped(1),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: aquaBlue),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 36, color: Colors.white),
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
              leading: const Icon(Icons.home, color: aquaBlue),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: aquaBlue),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: aquaBlue),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(2);
              },
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _widgetOptions.elementAt(_selectedIndex),
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
        currentIndex: _selectedIndex,
        selectedItemColor: aquaBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildUserProfileSection(context, user),
          const SizedBox(height: 20),
          _buildQuickActionsSection(context),
          const SizedBox(height: 20),
          _buildRecentActivitiesSection(),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context, User? user) {
    final String displayName = user?.displayName ?? 'No Name';
    final String email = user?.email ?? 'No Email';
    final String? photoURL = user?.photoURL;

    return Card(
      color: Colors.white,
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: aquaBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Member since: January 2025',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aquaBlue,
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

  Widget _buildQuickActionsSection(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: aquaBlue),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _buildQuickActionButton(
                    context,
                    Icons.lock,
                    'Encrypt Message',
                    EncryptMessageScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.lock_open,
                    'Decrypt Message',
                    DecryptMessageScreen(prefilledEncryptedText: '',),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.image,
                    'Encrypt Image',
                    EncryptImageScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.image_search,
                    'Decrypt Image',
                    DecryptImageScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.file_upload,
                    'File Sender',
                    FileSenderScreen(),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
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
      BuildContext context, IconData icon, String label, Widget screen) {
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
          backgroundColor: aquaBlue,
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentActivitiesSection() {
    final activities = _fetchRecentActivities();
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: aquaBlue),
            ),
            const SizedBox(height: 10),
            ...activities.map((activity) =>
                _buildActivityItem(activity['description']!, activity['timeAgo']!)).toList(),
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

  Widget _buildActivityItem(String activity, String timeAgo) {
    return ListTile(
      leading: Icon(Icons.history, color: aquaBlue),
      title: Text(activity),
      subtitle: Text(timeAgo),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No new notifications', style: TextStyle(fontSize: 24)),
    );
  }
}