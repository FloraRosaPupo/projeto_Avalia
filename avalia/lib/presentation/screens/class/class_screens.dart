import 'package:avalia/presentation/screens/class/class_detail_screens.dart';
import 'package:avalia/presentation/screens/class/class_card_screens.dart';
import 'package:avalia/presentation/screens/class/class_created_modal.dart';
import 'package:avalia/presentation/cubit/class_cubit.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/class_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassScreens extends StatefulWidget {
  const ClassScreens({Key? key}) : super(key: key);

  @override
  State<ClassScreens> createState() => _ClassScreensState();
}

class _ClassScreensState extends State<ClassScreens> {
  String? userId;

  @override
  void initState() {
    super.initState();
    // Obtém o ID do usuário autenticado
    final user = Supabase.instance.client.auth.currentUser;
    userId = user?.id;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClassCubit()..getClassesByUserId(userId: userId!),
      child: BlocConsumer<ClassCubit, BaseState>(
        listener: (context, state) {
          if (state is ErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro: ${state.message}')));
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 1,
              title: const Text('Turmas'),
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext dialogContext) {
                    return Center(child: ModalCreatedClass());
                  },
                ).then((_) {
                  // Recarrega a lista após fechar o modal
                  context.read<ClassCubit>().getClassesByUserId(
                    userId: userId!,
                  );
                });
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BaseState state) {
    // Estado de carregamento
    if (state is LoadingState) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de sucesso
    if (state is SuccessState<ClassListResponse>) {
      final classes = state.data.classes;

      if (classes.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Nenhuma turma encontrada.\nClique no botão + para criar uma nova turma.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 8),
          itemCount: classes.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            final turma = classes[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassDetailScreens(classId: turma.id),
                  ),
                );
              },
              child: TestScreens(
                title: turma.nome,
                subtitle: turma.descricao ?? 'Sem descrição',
                counterStudent: turma.numeroAlunos ?? 0,
                icon: Icons.book,
              ),
            );
          },
        ),
      );
    }

    // Estado inicial ou erro
    return const Center(child: Text('Carregando turmas...'));
  }
}
