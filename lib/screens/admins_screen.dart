import 'package:agromotion/components/agro_snackbar.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agromotion/components/glass_container.dart';

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

    return Stack(
      children: [
        // Fundo Gradiente consistente com a HomeScreen
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark
                  ? [const Color(0xFF112211), const Color(0xFF000000)]
                  : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Gestão de Acessos'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campo de Input com Glassmorphism
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Novo e-mail admin',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addEmail,
                          icon: Icon(
                            Icons.person_add_alt_1,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Lista de Admins Autorizados
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final email = docs[index].id;
                          return GlassContainer(
                            child: ListTile(
                              leading: const Icon(Icons.admin_panel_settings),
                              title: Text(email),
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
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
