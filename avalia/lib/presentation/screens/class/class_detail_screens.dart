import 'package:avalia/screens/components/card_exams_screens.dart';
import 'package:avalia/screens/student_detail_screens.dart';
import 'package:flutter/material.dart';
import 'package:avalia/screens/components/card_student_class.dart';
import 'package:avalia/screens/components/cretead_student_modal.dart';
class ClassDetailScreens extends StatelessWidget {
  const ClassDetailScreens({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        
        actions: [
          Row(
            children: [
              Icon(Icons.edit_outlined,color: Colors.purple, size: 20,),
              SizedBox(width: 2,),
              Text('Editar', style: TextStyle(color: Colors.purple),),
              SizedBox(width: 16,),
            ],
          )
        ],
      ),

      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          
          children: [
            Text('Turma 1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
            SizedBox(height:8,),
            Row(
              children: [
                Expanded(child: Text('Materia:')),
                Expanded(child: Text('Alunos: ')),
              ],
            ), 
            SizedBox(height: 16,),
            Row(children: [
              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), onPressed: (){
                showDialog(
                  context: context,
                  builder: (context) =>  ModalCreatedStudent(),
                  
                );
              }, icon: Icon(Icons.person_add, color: Colors.white,), label: Text('Adicionar Aluno',style: TextStyle(color: Colors.white),)),),
              SizedBox(width: 16,),
              Expanded(child: ElevatedButton.icon(onPressed: (){}, icon: Icon(Icons.import_export), label: Text('Importar Alunos')),),
            ],), 
            SizedBox(height: 16,),
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: 'Alunos'),
                        Tab(text: 'Provas'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Lista simulada de Alunos
                          ListView.separated(
                            itemCount: 5,
                            separatorBuilder: (context, index) => SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: (){
                                  Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StudentDetailScreens()),
            );
                                },
                                child: StudentClassCard(),
                              );
                            },
                          ),
                          // Lista simulada de Provas
                          ListView.separated(
                            separatorBuilder: (context, index) => SizedBox(height: 8),
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              return CardExamsScreens(title: 'Prova', status:   'Concluido', colorBorder: Colors.indigo, colorBackground:  const Color.fromARGB(19, 63, 81, 181), icon: Icons.article);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        )
      ),
    );
  }
}