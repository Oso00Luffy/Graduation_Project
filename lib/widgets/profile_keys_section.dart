import 'package:flutter/material.dart';
import '../services/recent_keys_service.dart';

class ProfileKeysSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: RecentKeysService.recentKeysStream(),
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final docs = snapshot.data.docs;
        if (docs.isEmpty) return Text("No keys yet.");
        return ListView.builder(
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            return ListTile(
              title: Text('${data['type']} key'),
              subtitle: Text(data['key']),
              trailing: Text(data['label'] ?? ''),
            );
          },
        );
      },
    );
  }
}