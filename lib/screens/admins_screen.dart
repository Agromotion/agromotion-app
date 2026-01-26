import 'dart:ui';
import 'package:agromotion/components/agro_appbar.dart';
import 'package:agromotion/components/agro_snackbar.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agromotion/components/glass_container.dart';
import '../theme/app_theme.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      AgroSnackbar.show(
        context,
        message: 'Introduza um e-mail válido.',
        isError: true,
      );
      return;
    }

    try {
      await _firestore.collection('authorized_emails').doc(email).set({
        'createdAt': FieldValue.serverTimestamp(),
        'createdByEmail': AuthService().currentUser?.email ?? 'Desconhecido',
      });
      _emailController.clear();
      if (mounted) {
        AgroSnackbar.show(context, message: 'E-mail autorizado com sucesso.');
      }
    } catch (e) {
      debugPrint('Erro ao adicionar e-mail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorsExtension>()!;

    final double horizontalPadding = context.horizontalPadding;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // AppBar Compacta
              const AgroAppBar(title: 'Acessos'),

              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Campo de Input com Glassmorphism
                    Text(
                      'AUTORIZAR NOVO UTILIZADOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.primary.withAlpha(80),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'exemplo@email.com',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    30,
                                  ),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _addEmail,
                            icon: Icon(
                              Icons.person_add_alt_1_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'ADMINISTRADORES ATIVOS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.primary.withAlpha(80),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // StreamBuilder integrado na lista de Slivers
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('authorized_emails')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Erro ao carregar dados'),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return Column(
                          children: docs.map((doc) {
                            final email = doc.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassContainer(
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withAlpha(10),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _firestore
                                        .collection('authorized_emails')
                                        .doc(email)
                                        .delete(),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 120), // Espaço para a NavBar
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
