import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/student_performance_model.dart';
import 'package:avalia/presentation/cubit/student_performance_cubit.dart';
import 'package:avalia/presentation/screens/student/student_details_exams_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avalia/presentation/screens/exams/exams_card_screens.dart';
import 'package:avalia/presentation/screens/exams/exams_correction_student.dart';

class StudentDetailScreens extends StatefulWidget {
  final int studentId;

  const StudentDetailScreens({Key? key, required this.studentId})
    : super(key: key);

  @override
  State<StudentDetailScreens> createState() => _StudentDetailScreensState();
}

class _StudentDetailScreensState extends State<StudentDetailScreens> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StudentPerformanceCubit()..getStudentPerformance(widget.studentId),
      child: BlocBuilder<StudentPerformanceCubit, BaseState>(
        builder: (context, state) {
          StudentPerformanceModel? performance;
          if (state is SuccessState<StudentPerformanceModel>) {
            performance = state.data;
          }

          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            appBar: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 1,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (performance != null && performance.correcaoPendente)
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(26, 247, 180, 80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Row(
                          children: const [
                            Text(
                              "●",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Correção Pendente',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            body: Builder(
              builder: (context) {
                if (state is LoadingState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ErrorState) {
                  return Center(child: Text('Erro: ${state.message}'));
                } else if (performance != null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Perfil do Aluno',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              performance.alunoNome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Matricula: ${performance.matricula}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Média Geral:',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        performance.mediaAluno.toStringAsFixed(
                                          1,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Card(
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Média Turma:',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        performance.mediaTurma.toStringAsFixed(
                                          1,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        DefaultTabController(
                          length: 2,
                          child: Expanded(
                            child: Column(
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(text: 'Resumo'),
                                    Tab(text: 'Provas'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      // Resumo tab
                                      SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 16),
                                            Card(
                                              color: Colors.white,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: const [
                                                        Icon(
                                                          Icons.show_chart,
                                                          color: Colors.grey,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Média Geral'),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          performance.mediaAluno
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        const Text('/10.0'),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      performance.acimaDaMedia
                                                          ? 'Acima da média da turma (${performance.mediaTurma.toStringAsFixed(1)})'
                                                          : 'Abaixo da média da turma (${performance.mediaTurma.toStringAsFixed(1)})',
                                                      style: TextStyle(
                                                        color:
                                                            performance
                                                                .acimaDaMedia
                                                            ? Colors.blue
                                                            : Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Card(
                                              color: Colors.white,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: const [
                                                        Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                          color: Colors.grey,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Provas Corrigidas',
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '${performance.provasCorrigidas}',
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'de ${performance.provasAplicadas} provas aplicadas',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      ),
                                      // Provas tab
                                      ListView.separated(
                                        itemCount: 5,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder: (BuildContext context) {
                                                  return SizedBox(
                                                    height: 450,
                                                    child:
                                                        const ExamsCorrectionStudent(),
                                                  );
                                                },
                                              );
                                            },
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DetailsExamsStudentScreens(
                                                          provaId:
                                                              'prova_$index', // TODO: usar ID real da prova
                                                          alunoId: widget
                                                              .studentId
                                                              .toString(),
                                                          provaNome:
                                                              'Prova $index',
                                                          provaData:
                                                              '12/05/2023',
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: CardExamsScreens(
                                                title: 'Prova $index',
                                                status: 'Concluido',
                                                colorBorder: Colors.green,
                                                colorBackground:
                                                    const Color.fromARGB(
                                                      19,
                                                      121,
                                                      197,
                                                      121,
                                                    ),
                                                icon:
                                                    Icons.check_circle_outline,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}
