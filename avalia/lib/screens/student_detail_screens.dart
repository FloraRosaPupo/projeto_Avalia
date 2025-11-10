import 'package:avalia/screens/components/card_student_class.dart';
import 'package:avalia/screens/details_exams_student_screens.dart';
import 'package:flutter/material.dart';
import 'package:avalia/screens/components/card_exams_screens.dart';
import 'package:avalia/screens/components/exams_correction_student.dart';

class StudentDetailScreens extends StatelessWidget {
  const StudentDetailScreens({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
          
          Container(
            height: 30,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                
                decoration: BoxDecoration(
                  color: const Color.fromARGB(26, 247, 180, 80),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Row(children: [
                    Text("●", style: TextStyle(color: Colors.orange, fontSize: 15),),
                    SizedBox(width: 5,),
                    Text('Correção Pendente', style: TextStyle(color: Colors.orange, fontSize:14 ,fontWeight: FontWeight.bold),)
                  ],)
                ),
              )
        ]),
        
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text('Perfil do Aluno', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nome',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Matricula:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child:  Padding(
                    
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Média Geral:',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '4,5',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  )
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                    
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Média Geral:',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '4,5',
                          style: TextStyle(
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
            SizedBox(height: 24),
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: 'Resumo'),
                        Tab(text: 'Provas'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Resumo tab
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(height: 16),
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(Icons.show_chart, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text('Média Geral'),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('4,5', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                            Text('/10.0'),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text('Acima da media da turma (7.8)', style: TextStyle(color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(Icons.check_circle_outline, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text('Provas Corrigidas'),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text('4,5', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text('de 6 provas aplicadas', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(Icons.more_horiz, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text('Média Geral', style: TextStyle(color: Colors.orange)),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text('2', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text('Aguardando correção do gabarito', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Provas tab
                          ListView.separated(
                            itemCount: 5,
                            separatorBuilder: (context, index) => SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                      return Container(
                                        height: 450,
                                        child: ExamsCorrectionStudent(),
                                      );
                                    },
                                  );
                                },
                                child: InkWell(
                                  onTap: () {
                                    
                                    Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailsExamsStudentScreens()),
            );
                                  },
                                  child: CardExamsScreens(
                                  title: 'Prova $index',
                                  status: 'Concluido',
                                  colorBorder: Colors.green,
                                  colorBackground: const Color.fromARGB(19, 121, 197, 121),
                                  icon: Icons.check_circle_outline,
                                ),
                                )
                              );
                            },
                          ),
                        ],
                      ),
                    )
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