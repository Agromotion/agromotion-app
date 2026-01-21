import 'package:agromotion/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  String _appVersion = '0.0.0';
  String _buildNumber = '0';
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao sair da conta.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Verifica se existe um utilizador logado
    final bool isUserLoggedIn = _authService.currentUser != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
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
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('Sistema'),
                        ),
                      ],
                      onChanged: (value) => themeProvider.setThemeMode(value!),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Conexão Remota'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.vpn_key_outlined),
                        title: Text('VPN / Tailscale'),
                        subtitle: Text('100.64.0.5 (Conectado)'),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
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

                // Só mostra o botão de Logout se o utilizador estiver autenticado
                if (isUserLoggedIn)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da Conta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Rodapé
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: Column(
              children: [
                Text(
                  'Agromotion © $_currentYear',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versão $_appVersion ($_buildNumber)',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
              ],
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
