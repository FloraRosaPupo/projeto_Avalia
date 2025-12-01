import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/class_detail_model.dart';
import 'package:avalia/presentation/cubit/class_cubit.dart';
import 'package:avalia/presentation/screens/exams/exams_card_screens.dart';
import 'package:avalia/presentation/screens/student/student_detail_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avalia/presentation/screens/student/student_card_class.dart';
import 'package:avalia/presentation/screens/student/student_cretead_modal.dart';
import 'package:avalia/presentation/screens/class/class_created_modal.dart';

class ClassDetailScreens extends StatefulWidget {
  final int classId;

  const ClassDetailScreens({Key? key, required this.classId}) : super(key: key);

  @override
  State<ClassDetailScreens> createState() => _ClassDetailScreensState();
}

class _ClassDetailScreensState extends State<ClassDetailScreens> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ClassCubit()..getClassDetails(classId: widget.classId),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          actions: [
            BlocBuilder<ClassCubit, BaseState>(
              builder: (context, state) {
                if (state is SuccessState<ClassDetailModel>) {
                  final classDetail = state.data;
                  return InkWell(
                    onTap: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => ModalCreatedClass(
                          classId: widget.classId,
                          className: classDetail.turma.nome,
                          subject: classDetail.turma.descricao,
                        ),
                      );
                      if (result == true) {
                        if (mounted) {
                          context.read<ClassCubit>().getClassDetails(
                            classId: widget.classId,
                          );
                        }
                      }
                    },
                    child: Row(
                      children: const [
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.purple,
                          size: 20,
                        ),
                        SizedBox(width: 2),
                        Text('Editar', style: TextStyle(color: Colors.purple)),
                        SizedBox(width: 16),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<ClassCubit, BaseState>(
          builder: (context, state) {
            if (state is LoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ErrorState) {
              return Center(child: Text('Erro: ${state.message}'));
            } else if (state is SuccessState<ClassDetailModel>) {
              final classDetail = state.data;
              return Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classDetail.turma.nome,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Descrição: ${classDetail.turma.descricao}',
                          ),
                        ),
                        Expanded(
                          child: Text('Alunos: ${classDetail.numeroAlunos}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    const ModalCreatedStudent(),
                              );
                            },
                            icon: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Adicionar Aluno',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.import_export),
                            label: const Text('Importar Alunos'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DefaultTabController(
                      length: 2,
                      child: Expanded(
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'Alunos'),
                                Tab(text: 'Provas'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Lista de Alunos
                                  classDetail.alunos.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Nenhum aluno cadastrado',
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: classDetail.alunos.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final aluno =
                                                classDetail.alunos[index];
                                            return InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        StudentDetailScreens(
                                                          studentId: aluno.id,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: StudentClassCard(
                                                name: aluno.nome,
                                                matricula: aluno.matricula,
                                                average: aluno.media,
                                                pendingCorrection:
                                                    aluno.correcaoPendente,
                                              ),
                                            );
                                          },
                                        ),
                                  // Lista de Provas
                                  classDetail.provas.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Nenhuma prova cadastrada',
                                          ),
                                        )
                                      : ListView.separated(
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 8),
                                          itemCount: classDetail.provas.length,
                                          itemBuilder: (context, index) {
                                            final prova =
                                                classDetail.provas[index];
                                            return CardExamsScreens(
                                              title: prova.nome,
                                              status: prova.status,
                                              colorBorder: HexColor(
                                                prova.cor,
                                              ), // Assuming HexColor helper exists or I need to parse it.
                                              // Wait, HexColor is likely not defined. I should check or use a helper.
                                              // The user didn't provide HexColor. I'll use a simple parser or just Colors.indigo if it fails.
                                              // Actually, let's assume the color string is like "#RRGGBB".
                                              colorBackground: Color.fromARGB(
                                                19,
                                                63,
                                                81,
                                                181,
                                              ), // Keeping static for now or deriving from colorBorder
                                              icon: Icons.article,
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
      ),
    );
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
