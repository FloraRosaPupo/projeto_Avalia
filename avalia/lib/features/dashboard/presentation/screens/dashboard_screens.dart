import 'package:avalia/features/classes/presentation/screens/class_screens.dart';
import 'package:avalia/features/dashboard/presentation/screens/dashboard_card_value_screens.dart';
import 'package:avalia/features/exams/presentation/screens/exams_screens.dart';
import 'package:flutter/material.dart';
import 'package:avalia/features/dashboard/presentation/screens/dashboard_card_history_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avalia/features/auth/presentation/screens/login_screen.dart';
import 'package:avalia/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avalia/core/navigation/app_route_observer.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/features/dashboard/data/models/dashboard_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState
    extends AutoRefreshRouteAwareState<DashboardScreen> {
  String? nome;
  String? email;
  String? userId;

  DashboardCubit? _cubit;

  @override
  void initState() {
    super.initState();

    // pega dados do usuário ao iniciar a tela (mais seguro que ler no construtor do widget)
    final user = Supabase.instance.client.auth.currentUser;
    nome = user?.userMetadata?['full_name'] as String?;
    email = user?.email;
    userId = user?.id;
    // OBS: não chamamos o Cubit aqui, chamamos na criação do BlocProvider no build
  }

  @override
  Future<void> refreshData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = _cubit;
      final id = userId;
      if (cubit == null || id == null) return;
      cubit.getRecentActivities(userId: id, limit: 10, isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = DashboardCubit();
        _cubit = cubit;
        if (userId != null) {
          cubit.getRecentActivities(userId: userId!, limit: 10);
        } else {
          // Se não há userId, emite erro
          cubit.emit(
            ErrorState('Usuário não autenticado. Faça login novamente.'),
          );
        }
        return cubit;
      },
      child: BlocConsumer<DashboardCubit, BaseState>(
        listener: (context, state) {
          if (state is ErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro: ${state.message}')));
          }
        },
        builder: (context, state) {
          // LOADING
          if (state is LoadingState) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // SUCCESS
          if (state is SuccessState<DashboardResponse>) {
            final data = state.data;

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                shadowColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 1,
                leading: Padding(
                  padding: EdgeInsetsGeometry.directional(
                    start: 8,
                    bottom: 8,
                    top: 8,
                  ),
                  child: Container(
                    height: 40.0,
                    width: 40.0,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      Supabase.instance.client.auth.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ],
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${nome ?? 'Usuário'}.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${email ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              body: _buildBodyWithData(context, data),
            );
          }

          // ESTADO INICIAL / OUTROS
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBodyWithData(BuildContext context, DashboardResponse? data) {
    final recent = data?.recentActivities ?? <Activity>[];
    final cubit = context.read<DashboardCubit>();

    return RefreshIndicator(
      onRefresh: () async {
        if (userId != null) {
          await cubit.getRecentActivities(
            userId: userId!,
            limit: 10,
            isRefresh: true,
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // cards superiores (exemplo simples)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClassScreens(),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao navegar: $e'),
                            ),
                          );
                        }
                      },
                      child: CardDashbordScreen(
                        icon: Icons.group_outlined,
                        colorBackground: const Color.fromARGB(
                          97,
                          255,
                          253,
                          124,
                        ),
                        colorIcon: const Color.fromARGB(255, 190, 187, 0),
                        title: 'Minhas Turmas',
                        number: data?.turmaCount.toString() ?? '—',
                        subtitle: 'Turmas',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExamsScreens(),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao navegar: $e'),
                            ),
                          );
                        }
                      },
                      child: CardDashbordScreen(
                        icon: Icons.article_outlined,
                        colorBackground: const Color.fromARGB(82, 52, 175, 206),
                        colorIcon: const Color.fromARGB(255, 62, 87, 94),
                        title: 'Provas Recentes',
                        number: data?.provaCount.toString() ?? '—',
                        subtitle: 'Provas',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Atividades Recentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              recent.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Nenhuma atividade encontrada.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      itemBuilder: (context, index) {
                        final act = recent[index];
                        final style = getActivityStyle(
                          act.action,
                          act.resource,
                        );
                        return HistoryScreens(
                          icon: style.icon,
                          colorBackground: style.color.withValues(alpha: 0.2),
                          colorIcon: style.color,
                          title: act.title ?? 'Sem título',
                          subtitle: act.resource,
                          datetime: act.createdAt == null
                              ? DateTime.now()
                              : act.createdAt!,
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityStyle {
  final IconData icon;
  final Color color;

  ActivityStyle({required this.icon, required this.color});
}

ActivityStyle getActivityStyle(String action, String resource) {
  // Prioridade por ACTION
  switch (action) {
    case 'create':
      return ActivityStyle(icon: Icons.add_circle, color: Colors.green);
    case 'update':
      return ActivityStyle(icon: Icons.edit, color: Colors.blue);
    case 'delete':
      return ActivityStyle(icon: Icons.delete, color: Colors.red);
  }

  // Prioridade por RESOURCE (opcional)
  switch (resource) {
    case 'professores':
      return ActivityStyle(icon: Icons.person, color: Colors.deepPurple);
    case 'turmas':
      return ActivityStyle(icon: Icons.groups, color: Colors.orange);
    case 'provas':
      return ActivityStyle(icon: Icons.description, color: Colors.teal);
    case 'submissoes':
      return ActivityStyle(icon: Icons.check_circle, color: Colors.indigo);
  }

  // fallback
  return ActivityStyle(icon: Icons.history, color: Colors.grey);
}
