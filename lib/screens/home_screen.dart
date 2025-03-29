import 'package:flutter/material.dart';
import 'encrypt_decrypt_message_screen.dart';
import 'encrypt_decrypt_image_screen.dart';
import 'file_sender_screen.dart';
import 'secure_chat_screen.dart';
import 'settings_screen.dart';  // Import SettingsScreen

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const HomeScreen({required this.isDarkMode, required this.toggleTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String currentUser = 'Oso00Luffy';

  static List<Widget> _widgetOptions = <Widget>[
    PlaceholderWidget('Settings'),
    PlaceholderWidget('Profile'),
    NotificationsScreen(),
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

  void _switchUser() {
    setState(() {
      currentUser = currentUser == 'Oso00Luffy' ? 'Moath Hdairis' : 'Oso00Luffy';
    });
  }

  void _showNotificationsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notifications'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Notification 1'),
                Text('Notification 2'),
                Text('Notification 3'),
                // Add more notifications here
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('View More'),
              onPressed: () {
                Navigator.of(context).pop();
                _onItemTapped(2); // Navigate to Notifications Screen
              },
            ),
            TextButton(
              child: Text('Close'),
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
      appBar: AppBar(
        title: Text('SCC - Secure - Chat - Crypt'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              _showNotificationsPopup(context); // Show notifications popup
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/settings',
                arguments: {
                  'isDarkMode': widget.isDarkMode,
                  'toggleTheme': widget.toggleTheme,
                },
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/settings',
                  arguments: {
                    'isDarkMode': widget.isDarkMode,
                    'toggleTheme': widget.toggleTheme,
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.switch_account),
              title: Text('Switch User'),
              onTap: () {
                Navigator.pop(context);
                _switchUser();
              },
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _selectedIndex == 0 ? HomeContent(currentUser: currentUser) : _widgetOptions.elementAt(_selectedIndex - 1),
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final String currentUser;

  const HomeContent({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildUserProfileSection(context, currentUser), // Pass context here
          SizedBox(height: 20),
          _buildQuickActionsSection(context),
          SizedBox(height: 20),
          _buildRecentActivitiesSection(),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context, String currentUser) { // Pass context here
    final userDetails = _getUserDetails(currentUser);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/images/profile_picture.png'), // Replace with user profile image
            ),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  userDetails['name']!,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  userDetails['email']!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 5),
                Text(
                  'Member since: January 2025', // Replace with actual join date
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/settings',
                      arguments: {
                        'isDarkMode': false,
                        'toggleTheme': (value) {},
                      },
                    );
                  },
                  child: Text('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getUserDetails(String currentUser) {
    if (currentUser == 'Oso00Luffy') {
      return {
        'name': 'Oso00Luffy',
        'email': 'osojr2017@gmail.com',
      };
    } else if (currentUser == 'Moath Hdairis') {
      return {
        'name': 'Moath Hdairis',
        'email': 'moath.hdairis@example.com',
      };
    } else {
      return {
        'name': 'Unknown User',
        'email': 'unknown@example.com',
      };
    }
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildQuickActionButton(
                  context,
                  Icons.lock,
                  'Encrypt Message',
                  EncryptDecryptMessageScreen(),
                ),
                _buildQuickActionButton(
                  context,
                  Icons.lock_open,
                  'Decrypt Message',
                  EncryptDecryptMessageScreen(), // Replace with appropriate screen
                ),
                _buildQuickActionButton(
                  context,
                  Icons.image,
                  'Encrypt Image',
                  EncryptDecryptImageScreen(),
                ),
                _buildQuickActionButton(
                  context,
                  Icons.image_search,
                  'Decrypt Image',
                  EncryptDecryptImageScreen(), // Replace with appropriate screen
                ),
              ],
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
          child: Icon(icon, size: 30),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentActivitiesSection() {
    final activities = _fetchRecentActivities();
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...activities.map((activity) => _buildActivityItem(activity['description']!, activity['timeAgo']!)).toList(),
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
      leading: Icon(Icons.history),
      title: Text(activity),
      subtitle: Text(timeAgo),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String text;

  const PlaceholderWidget(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: TextStyle(fontSize: 24)),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No new notifications', style: TextStyle(fontSize: 24)),
    );
  }
}