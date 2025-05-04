import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import '../services/recent_keys_service.dart';

class ProfileKeysSection extends StatefulWidget {
  @override
  _ProfileKeysSectionState createState() => _ProfileKeysSectionState();
}

class _ProfileKeysSectionState extends State<ProfileKeysSection> {
  List<bool> _isExpanded = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: RecentKeysService.recentKeysStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No keys yet.'));
        }

        final docs = snapshot.data!.docs;

        // Synchronize the expansion state list with the number of documents
        if (_isExpanded.length != docs.length) {
          _isExpanded = List<bool>.filled(docs.length, false);
        }

        return SingleChildScrollView(
          child: Column(
            children: List.generate(docs.length, (index) {
              final data = docs[index].data();
              final keyId = docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ExpansionPanelList(
                  elevation: 1,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isExpanded[index] = !isExpanded;
                    });
                  },
                  children: [
                    ExpansionPanel(
                      isExpanded: _isExpanded[index],
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          title: Text('${data['type']} key'),
                          subtitle: Text(
                            'Created At: ${data['created_at'] != null ? data['created_at'].toDate().toString() : 'N/A'}',
                          ),
                        );
                      },
                      body: Column(
                        children: [
                          ListTile(
                            title: Text(data['key']),
                            subtitle: Text(data['label'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: data['key']));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Key copied to clipboard!')),
                                );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _deleteKey(context, keyId),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> _deleteKey(BuildContext context, String keyId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Key'),
        content: const Text('Are you sure you want to delete this key?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("No user logged in");

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('recent_keys')
            .doc(keyId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Key successfully deleted')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete key: $error')),
        );
      }
    }
  }
}