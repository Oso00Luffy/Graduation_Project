import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/recent_keys_service.dart';

class ProfileKeysSection extends StatelessWidget {
  const ProfileKeysSection({super.key});

  Future<void> _deleteKey(BuildContext context, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_keys')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete key: $e')),
      );
    }
  }

  Widget scrollableValueCard(BuildContext context, String title, String value) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: SelectableText(
                value,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 90),
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: RecentKeysService.recentKeysStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  "No keys yet.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final docId = docs[i].id;

            final type = data['type'] ?? '';
            final label = data['label'] ?? '';
            final key = data['key'] ?? '';
            final message = data['message'] ?? '';
            final encryptedMessage = data['encrypted_message'] ?? '';

            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF232529)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.06),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Encryption Method: $type",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: "Delete key",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Key'),
                                content: const Text('Are you sure you want to delete this key?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              _deleteKey(context, docId);
                            }
                          },
                        ),
                      ],
                    ),
                    if (label.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(label,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    const Divider(height: 22),
                    if (message.isNotEmpty) ...[
                      const Text(
                        "Message to Encrypt:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      scrollableValueCard(context, "Message to Encrypt", message),
                    ],
                    if (key.isNotEmpty) ...[
                      const Text(
                        "Algorithm Key:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      scrollableValueCard(context, "Algorithm Key", key),
                    ],
                    if (encryptedMessage.isNotEmpty) ...[
                      const Text(
                        "Encrypted Message:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      scrollableValueCard(context, "Encrypted Message", encryptedMessage),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}