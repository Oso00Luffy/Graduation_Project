import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          : null,
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
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildUserProfileSection(context, user, theme, isWide),
                        const SizedBox(height: 20),
                        _buildAdvancedUserSummarySection(context, user, theme, isWide),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
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
                  _buildAdvancedUserSummarySection(context, user, theme, isWide),
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
              'Features',
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
                  ImageEncryptionScreen(),
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

  Widget _buildAdvancedUserSummarySection(BuildContext context, User? user, ThemeData theme, bool isWide) {
    return Card(
      color: theme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Account & Recent Activity",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: isWide ? 22 : 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildAccountStatus(context, user, theme, isWide),
            const SizedBox(height: 16),
            Text(
              "Recent Chat Activity",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            _RecentActivityList(user: user),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatus(BuildContext context, User? user, ThemeData theme, bool isWide) {
    final bool isVerified = user?.emailVerified ?? false;
    final DateTime? lastSignIn = user?.metadata.lastSignInTime;
    final DateTime? creationTime = user?.metadata.creationTime;
    final bool hasProfilePic = (user?.photoURL != null && user!.photoURL!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            isVerified ? Icons.verified : Icons.mark_email_unread,
            color: isVerified ? Colors.green : Colors.orange,
            size: isWide ? 32 : 24,
          ),
          title: Text(
            isVerified ? "Email Verified" : "Email Not Verified",
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: isWide ? 18 : 14),
          ),
          subtitle: Text(
            isVerified
                ? "Your email is verified"
                : "Verify your email for improved security",
            style: theme.textTheme.bodySmall?.copyWith(fontSize: isWide ? 14 : 12),
          ),
          trailing: !isVerified
              ? TextButton(
            onPressed: () async {
              await user?.sendEmailVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Verification email sent.")),
              );
            },
            child: const Text("Verify Now"),
          )
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: isWide ? 12 : 4),
        ),
        ListTile(
          leading: Icon(Icons.access_time, color: theme.colorScheme.primary, size: isWide ? 32 : 24),
          title: const Text("Last Login"),
          subtitle: Text(
            lastSignIn != null
                ? "${lastSignIn.year}-${lastSignIn.month.toString().padLeft(2, "0")}-${lastSignIn.day.toString().padLeft(2, "0")} ${lastSignIn.hour.toString().padLeft(2, "0")}:${lastSignIn.minute.toString().padLeft(2, "0")}"
                : "Unknown",
            style: theme.textTheme.bodySmall?.copyWith(fontSize: isWide ? 14 : 12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: isWide ? 12 : 4),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today, color: Colors.blueGrey, size: isWide ? 32 : 24),
          title: const Text("Member Since"),
          subtitle: Text(
            creationTime != null
                ? "${creationTime.year}-${creationTime.month.toString().padLeft(2, "0")}-${creationTime.day.toString().padLeft(2, "0")}"
                : "Unknown",
            style: theme.textTheme.bodySmall?.copyWith(fontSize: isWide ? 14 : 12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: isWide ? 12 : 4),
        ),
        ListTile(
          leading: Icon(Icons.person, color: theme.colorScheme.primary, size: isWide ? 32 : 24),
          title: Text(
            hasProfilePic ? "Profile Picture Set" : "No Profile Picture",
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: isWide ? 18 : 14),
          ),
          subtitle: Text(
            hasProfilePic
                ? "Looks good!"
                : "Add a profile picture to personalize your account.",
            style: theme.textTheme.bodySmall?.copyWith(fontSize: isWide ? 14 : 12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: isWide ? 12 : 4),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final User? user;
  const _RecentActivityList({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Text('No user data');
    }

    // Show most recent 5 messages the user sent in any chat room
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('senderUid', isEqualTo: user!.uid)
          .orderBy('sentAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              "No recent chat activity yet.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final text = data['text'] ?? '';
            final sentAt = data['sentAt'];
            final dateStr = _formatTimestamp(sentAt);
            final roomId = doc.reference.parent.parent?.id ?? 'Room';

            return ListTile(
              leading: Icon(Icons.message, color: Theme.of(context).colorScheme.primary),
              title: Text(
                text.length > 40 ? "${text.substring(0, 40)}..." : text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("Room: $roomId • $dateStr"),
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        );
      },
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "";
  }
}