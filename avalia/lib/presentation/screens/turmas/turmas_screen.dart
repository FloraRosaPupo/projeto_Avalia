import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/state/base_state.dart';
import '../../../data/models/turma_model.dart';
import '../../cubit/turmas_cubit.dart';

/// Tela para exibir a lista de turmas.
class TurmasScreen extends StatelessWidget {
  const TurmasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turmas')),
      // Fornece o TurmasCubit para a árvore de widgets
      body: BlocProvider(
        create: (context) => TurmasCubit()..fetchTurmas(),
        child: BlocBuilder<TurmasCubit, BaseState>(
          builder: (context, state) {
            // Verifica o estado atual e renderiza a UI apropriada
            if (state is LoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ErrorState) {
              return Center(child: Text('Erro: ${state.message}'));
            } else if (state is SuccessState<List<Turma>>) {
              final turmas = state.data;
              if (turmas.isEmpty) {
                return const Center(child: Text('Nenhuma turma encontrada.'));
              }
              return ListView.builder(
                itemCount: turmas.length,
                itemBuilder: (context, index) {
                  final turma = turmas[index];
                  return ListTile(
                    title: Text(turma.nome),
                    subtitle: Text('ID: ${turma.id}'),
                  );
                },
              );
            }
            // Estado inicial ou desconhecido
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
