import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'encrypt_message_screen.dart';
import 'decrypt_message_screen.dart';
import 'encrypt_image_screen.dart';
import 'decrypt_image_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'chat_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  List<Widget> get _widgetOptions => <Widget>[
    HomeContent(onGotoSettingsTab: () => _onTabChanged(1)),
    SettingsScreen(),
    ProfileScreen(),
    const ChatRoomScreen(),
  ];

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
            icon: const Icon(Icons.settings),
            onPressed: () => _onTabChanged(1),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Log out",
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width < 800
          ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Row(
                children: const [
                  Icon(Icons.lock, size: 36, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
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
                _onTabChanged(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.primary),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _onTabChanged(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: theme.colorScheme.primary),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _onTabChanged(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.group, color: theme.colorScheme.primary),
              title: const Text('Chat Rooms'),
              onTap: () {
                Navigator.pop(context);
                _onTabChanged(3);
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
      )
          : null, // No drawer for large screens
      body: IndexedStack(
        index: selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Chat Rooms'),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onTabChanged,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final VoidCallback onGotoSettingsTab;

  const HomeContent({
    super.key,
    required this.onGotoSettingsTab,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 1200 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: isWide
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Profile + Recent Activities
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildUserProfileSection(context, user, theme, isWide),
                        const SizedBox(height: 20),
                        _buildRecentActivitiesSection(theme, isWide),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right column: Quick Actions
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildQuickActionsSection(context, theme, isWide),
                      ],
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildUserProfileSection(context, user, theme, isWide),
                  const SizedBox(height: 20),
                  _buildQuickActionsSection(context, theme, isWide),
                  const SizedBox(height: 20),
                  _buildRecentActivitiesSection(theme, isWide),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserProfileSection(
      BuildContext context, User? user, ThemeData theme, bool isWide) {
    final String displayName = user?.displayName ?? 'No Name';
    final String email = user?.email ?? 'No Email';
    final String? photoURL = user?.photoURL;

    return Card(
      color: theme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: isWide ? 60 : 40,
              backgroundImage: photoURL != null
                  ? NetworkImage(photoURL)
                  : const AssetImage('assets/images/profile_picture.png')
              as ImageProvider,
            ),
            SizedBox(width: isWide ? 32 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isWide ? 28 : 20,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: isWide ? 18 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Member since: January 2025',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 10),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 32 : 16,
                          vertical: isWide ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: onGotoSettingsTab,
                      child: const Text('Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
      BuildContext context, ThemeData theme, bool isWide) {
    return Card(
      color: theme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Quick Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: isWide ? 22 : 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: isWide ? 30 : 10,
              runSpacing: isWide ? 30 : 10,
              children: <Widget>[
                _buildQuickActionButton(
                  context,
                  theme,
                  Icons.lock,
                  'Encrypt Message',
                  EncryptMessageScreen(),
                  isWide,
                ),
                _buildQuickActionButton(
                  context,
                  theme,
                  Icons.lock_open,
                  'Decrypt Message',
                  DecryptMessageScreen(),
                  isWide,
                ),
                _buildQuickActionButton(
                  context,
                  theme,
                  Icons.image,
                  'Encrypt Image',
                  EncryptImageScreen(),
                  isWide,
                ),
                _buildQuickActionButton(
                  context,
                  theme,
                  Icons.image_search,
                  'Decrypt Image',
                  DecryptImageScreen(),
                  isWide,
                ),
                _buildQuickActionButton(
                  context,
                  theme,
                  Icons.group,
                  'Chat Rooms',
                  const ChatRoomScreen(),
                  isWide,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context,
      ThemeData theme,
      IconData icon,
      String label,
      Widget screen,
      bool isWide,
      ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: label,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            },
            backgroundColor: theme.colorScheme.primary,
            child: Icon(icon, size: isWide ? 36 : 30, color: Colors.white),
            elevation: isWide ? 8 : 4,
          ),
          const SizedBox(height: 5),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: isWide ? 16 : 12)),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(ThemeData theme, bool isWide) {
    final activities = _fetchRecentActivities();
    return Card(
      color: theme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recent Activities',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: isWide ? 22 : 16,
              ),
            ),
            const SizedBox(height: 16),
            ...activities
                .map((activity) => _buildActivityItem(
              theme,
              activity['description']!,
              activity['timeAgo']!,
              isWide,
            ))
                .toList(),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _fetchRecentActivities() {
    return [
      {'description': 'Encrypted a message', 'timeAgo': '2 hours ago'},
      {'description': 'Decrypted an image', 'timeAgo': '4 hours ago'},
      {'description': 'Sent a secure file', 'timeAgo': '1 day ago'},
    ];
  }

  Widget _buildActivityItem(
      ThemeData theme,
      String activity,
      String timeAgo,
      bool isWide,
      ) {
    return ListTile(
      leading: Icon(Icons.history, color: theme.colorScheme.primary, size: isWide ? 32 : 24),
      title: Text(activity,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: isWide ? 18 : 14)),
      subtitle: Text(timeAgo,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: isWide ? 14 : 12)),
      contentPadding: EdgeInsets.symmetric(vertical: isWide ? 12 : 4),
    );
  }
}