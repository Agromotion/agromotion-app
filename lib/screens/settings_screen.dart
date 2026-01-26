import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/theme/theme_provider.dart';
import 'package:agromotion/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../components/glass_container.dart';

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
    try {
      await _authService.logout().timeout(
        const Duration(seconds: 2),
        onTimeout: () =>
            AppLogger.warning("Logout demorou, mas o estado mudará."),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      AppLogger.error("Erro ao sair", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final customColors = theme.extension<AppColorsExtension>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isUserLoggedIn = _authService.currentUser != null;

    final double horizontalPadding = screenWidth > 600
        ? screenWidth * 0.15
        : 20.0;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header com botão de voltar (Estrutura idêntica à NotificationsScreen)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding - 12,
                    20,
                    horizontalPadding,
                    10,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.pop(context),
                          color: theme.colorScheme.onSurface,
                          iconSize: 20,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Definições",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                "Configure a sua plataforma Agromotion",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    50,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Conteúdo das Definições
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildSectionTitle(context, 'Aparência'),
                      GlassContainer(
                        child: ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('Tema'),
                          trailing: DropdownButton<String>(
                            value: themeProvider.themeText,
                            underline: const SizedBox(),
                            dropdownColor: theme.colorScheme.surface,
                            items: const [
                              DropdownMenuItem(
                                value: 'light',
                                child: Text('Claro'),
                              ),
                              DropdownMenuItem(
                                value: 'dark',
                                child: Text('Escuro'),
                              ),
                              DropdownMenuItem(
                                value: 'system',
                                child: Text('Sistema'),
                              ),
                            ],
                            onChanged: (value) =>
                                themeProvider.setThemeMode(value!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle(context, 'Conexão Remota'),
                      GlassContainer(
                        child: Column(
                          children: [
                            const ListTile(
                              leading: Icon(Icons.vpn_key_outlined),
                              title: Text('VPN / Tailscale'),
                              subtitle: Text('100.64.0.5 (Conectado)'),
                              trailing: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const Divider(height: 1, indent: 50),
                            ListTile(
                              leading: const Icon(Icons.cloud_sync_outlined),
                              title: const Text('Firebase Realtime'),
                              subtitle: const Text('Sincronização Ativa'),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      if (isUserLoggedIn)
                        OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sair da Conta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                      // Rodapé informativo
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Text(
                              'Agromotion © $_currentYear',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Versão $_appVersion ($_buildNumber)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 16, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
