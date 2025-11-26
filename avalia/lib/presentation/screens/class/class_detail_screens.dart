import 'package:avalia/presentation/screens/exams/exams_card_screens.dart';
import 'package:avalia/presentation/screens/student/student_detail_screens.dart';
import 'package:flutter/material.dart';
import 'package:avalia/presentation/screens/student/student_card_class.dart';
import 'package:avalia/presentation/screens/student/student_cretead_modal.dart';

class ClassDetailScreens extends StatelessWidget {
  final int classId;
  final String className;

  const ClassDetailScreens({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        actions: [
          Row(
            children: const [
              Icon(Icons.edit_outlined, color: Colors.purple, size: 20),
              SizedBox(width: 2),
              Text('Editar', style: TextStyle(color: Colors.purple)),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              className,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: Text('Materia:')),
                Expanded(child: Text('Alunos: ')),
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
                        builder: (context) => const ModalCreatedStudent(),
                      );
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
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
                          // Lista simulada de Alunos
                          ListView.separated(
                            itemCount: 5,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const StudentDetailScreens(),
                                    ),
                                  );
                                },
                                child: const StudentClassCard(),
                              );
                            },
                          ),
                          // Lista simulada de Provas
                          ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              return const CardExamsScreens(
                                title: 'Prova',
                                status: 'Concluido',
                                colorBorder: Colors.indigo,
                                colorBackground: Color.fromARGB(
                                  19,
                                  63,
                                  81,
                                  181,
                                ),
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
      ),
    );
  }
}
