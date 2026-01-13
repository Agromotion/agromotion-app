import 'package:agromotion/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedTheme = 'system';
  bool notificationsEnabled = true;
  bool soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _buildSectionTitle(context, 'Aparência'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema'),
              trailing: DropdownButton<String>(
                value: themeProvider.themeText,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'light', child: Text('Claro')),
                  DropdownMenuItem(value: 'dark', child: Text('Escuro')),
                  DropdownMenuItem(value: 'system', child: Text('Sistema')),
                ],
                onChanged: (value) =>
                    setState(() => themeProvider.setThemeMode(value!)),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Conexão Remota'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: const Text('VPN / Tailscale'),
                  subtitle: const Text('100.64.0.5 (Conectado)'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Firebase Realtime'),
                  subtitle: const Text('Sincronização Ativa'),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair da Conta'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
