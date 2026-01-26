import 'dart:io';
import 'package:agromotion/components/settings/section_title.dart';
import 'package:agromotion/components/settings/settings_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/theme/theme_provider.dart';
import 'package:agromotion/utils/app_logger.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:agromotion/services/storage_service.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/components/agro_snackbar.dart';
import 'package:agromotion/components/settings/settings_header.dart';
import 'package:agromotion/components/settings/settings_footer.dart';
import 'package:agromotion/components/settings/connection_info_card.dart';
import 'package:agromotion/components/settings/logout_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  String _appVersion = '0.0.0';
  String _buildNumber = '0';
  String _currentStoragePath = "A carregar...";

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadStoragePath();
  }

  /// Carrega informações da build do pacote
  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      AppLogger.error("Erro ao carregar info do pacote", e);
    }
  }

  /// Carrega o caminho atual de armazenamento de capturas
  Future<void> _loadStoragePath() async {
    final path = await _storageService.getSavePath();
    setState(() => _currentStoragePath = path);
  }

  /// Abre o seletor de pastas e atualiza o estado
  Future<void> _handlePickPath() async {
    final newPath = await _storageService.pickCustomPath();
    if (newPath != null) {
      setState(() => _currentStoragePath = newPath);
      if (mounted) {
        AgroSnackbar.show(
          context,
          message: "Local de armazenamento atualizado!",
        );
      }
    }
  }

  /// Realiza o logout e volta para o ecrã de login
  Future<void> _handleLogout() async {
    try {
      await _authService.logout().timeout(
        const Duration(seconds: 2),
        onTimeout: () => AppLogger.warning("Logout forçado por timeout."),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      AppLogger.error("Erro ao sair da conta", e);
      if (mounted) {
        AgroSnackbar.show(context, message: "Erro ao sair.", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final customColors = theme.extension<AppColorsExtension>()!;
    final bool isUserLoggedIn = _authService.currentUser != null;

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
                const SettingsHeader(),

                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),

                      const SectionTitle(title: 'Aparência'),
                      _buildThemeTile(theme, themeProvider),

                      const SizedBox(height: 32),

                      const SectionTitle(title: 'Armazenamento & Capturas'),
                      _buildStorageTile(),

                      const SizedBox(height: 32),

                      const SectionTitle(title: 'Conexão Remota'),
                      const ConnectionInfoCard(),

                      const SizedBox(height: 40),

                      if (isUserLoggedIn)
                        LogoutButton(onPressed: _handleLogout),

                      SettingsFooter(
                        appVersion: _appVersion,
                        buildNumber: _buildNumber,
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

  Widget _buildThemeTile(ThemeData theme, ThemeProvider provider) {
    return SettingsTile(
      icon: Icons.palette_outlined,
      title: 'Tema',
      trailing: DropdownButton<String>(
        value: provider.themeText,
        underline: const SizedBox(),
        dropdownColor: theme.colorScheme.surface,
        items: const [
          DropdownMenuItem(value: 'light', child: Text('Claro')),
          DropdownMenuItem(value: 'dark', child: Text('Escuro')),
          DropdownMenuItem(value: 'system', child: Text('Sistema')),
        ],
        onChanged: (value) => provider.setThemeMode(value!),
      ),
    );
  }

  /// Constrói a informação de armazenamento (Diferencia Web de Desktop/Mobile)
  Widget _buildStorageTile() {
    final bool canChange = !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

    return SettingsTile(
      icon: kIsWeb ? Icons.download_rounded : Icons.folder_special_outlined,
      title: 'Local das Capturas',
      subtitle: Text(
        kIsWeb ? 'Gerido pelo navegador' : _currentStoragePath,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: canChange
          ? IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: _handlePickPath,
            )
          : null,
    );
  }
}
