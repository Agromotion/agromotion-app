import 'package:flutter/material.dart';
import '../glass_container.dart';

class ConnectionInfoCard extends StatelessWidget {
  const ConnectionInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.vpn_key_outlined),
            title: Text('VPN / Tailscale'),
            subtitle: Text('100.64.0.5 (Ativo)'),
            trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
          ),
          Divider(height: 1, indent: 50),
          ListTile(
            leading: Icon(Icons.cloud_sync_outlined),
            title: Text('Firebase Realtime'),
            subtitle: Text('Sincronização OK'),
          ),
        ],
      ),
    );
  }
}
