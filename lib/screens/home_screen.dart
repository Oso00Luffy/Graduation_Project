import 'package:flutter/material.dart';
import 'encrypt_message_screen.dart';
import 'decrypt_message_screen.dart';
import 'encrypt_image_screen.dart';
import 'decrypt_image_screen.dart';
import 'file_sender_screen.dart';
import 'secure_chat_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';  // Import ProfileScreen

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
  String currentUser = 'Osama Jaradat';

  List<Widget> get _widgetOptions => <Widget>[
    HomeContent(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme, currentUser: currentUser),
    SettingsScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme),
    ProfileScreen(userName: currentUser, email: _getUserEmail(currentUser), profileImagePath: 'assets/images/profile_picture.png'),
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

  void _switchUser() {
    setState(() {
      currentUser = currentUser == 'Osama Jaradat' ? 'Moath Hdairis' : 'Osama Jaradat';
      print('Switched user to: $currentUser'); // Debug log
    });
  }

  String _getUserEmail(String userName) {
    if (userName == 'Osama Jaradat') {
      return 'osojr2017@gmail.com';
    } else if (userName == 'Moath Hdairis') {
      return 'moath.hdairis@example.com';
    } else {
      return 'unknown@example.com';
    }
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
                _onItemTapped(3); // Navigate to Notifications Screen
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
              _onItemTapped(1); // Navigate to Settings Screen
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
                _onItemTapped(1);
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
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;
  final String currentUser;

  const HomeContent({required this.isDarkMode, required this.toggleTheme, required this.currentUser});

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
            Expanded( // Use Expanded or Flexible to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    userDetails['name']!,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                  SizedBox(height: 5),
                  Text(
                    userDetails['email']!,
                    style: TextStyle(color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis, // Prevent overflow
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
                          'isDarkMode': isDarkMode,
                          'toggleTheme': toggleTheme,
                        },
                      );
                    },
                    child: Text('Settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getUserDetails(String currentUser) {
    if (currentUser == 'Osama Jaradat') {
      return {
        'name': 'Osama Jaradat',
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
                  SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.lock_open,
                    'Decrypt Message',
                    DecryptMessageScreen(),
                  ),
                  SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.image,
                    'Encrypt Image',
                    EncryptImageScreen(),
                  ),
                  SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.image_search,
                    'Decrypt Image',
                    DecryptImageScreen(),
                  ),
                  SizedBox(width: 10),
                  _buildQuickActionButton(
                    context,
                    Icons.file_upload,
                    'File Sender',
                    FileSenderScreen(),
                  ),
                  SizedBox(width: 10),
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