import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/exam_model.dart';
import 'package:avalia/presentation/cubit/exams_cubit.dart';
import 'package:avalia/presentation/screens/exams/exams_card_screens.dart';
import 'package:avalia/presentation/screens/exams/exams_created_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExamsScreens extends StatefulWidget {
  const ExamsScreens({Key? key}) : super(key: key);

  @override
  State<ExamsScreens> createState() => _ExamsScreensState();
}

class _ExamsScreensState extends State<ExamsScreens> {
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = Supabase.instance.client.auth.currentUser?.id;
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.purple;
    try {
      // Tenta parsear se for hex (ex: #FF0000 ou FF0000)
      final buffer = StringBuffer();
      if (colorString.length == 6 || colorString.length == 7)
        buffer.write('ff');
      buffer.write(colorString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.purple;
    }
  }

  void _openExamModal(BuildContext context, [ExamModel? exam]) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true, // Importante para modais com input
      builder: (BuildContext context) {
        return ModalCreatedExams(exam: exam);
      },
    ).then((result) {
      if (result == true && userId != null) {
        // Recarrega a lista se houve alteração
        context.read<ExamsCubit>().getExamsByUserId(userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = ExamsCubit();
        if (userId != null) {
          cubit.getExamsByUserId(userId!);
        }
        return cubit;
      },
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 1,
              title: const Text('Provas'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _openExamModal(context),
                ),
              ],
            ),
            body: BlocConsumer<ExamsCubit, BaseState>(
              listener: (context, state) {
                if (state is ErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${state.message}')),
                  );
                }
              },
              builder: (context, state) {
                if (state is LoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SuccessState<List<ExamModel>>) {
                  final exams = state.data;

                  if (exams.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma prova encontrada.'),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: 8),
                      itemCount: exams.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final exam = exams[index];
                        final color = _parseColor(exam.cor);

                        return InkWell(
                          onTap: () => _openExamModal(context, exam),
                          child: CardExamsScreens(
                            title: exam.nome ?? 'Prova ${exam.id}',
                            status: exam.status ?? 'Pendente',
                            colorBorder: color,
                            colorBackground: color.withOpacity(0.2),
                            icon: Icons.article,
                          ),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: Text('Carregando provas...'));
              },
            ),
          );
        },
      ),
    );
  }
}
