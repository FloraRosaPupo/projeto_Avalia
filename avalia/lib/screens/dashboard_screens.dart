import 'package:avalia/screens/class_screens.dart';
import 'package:avalia/screens/components/card_dashbord_screens.dart';
import 'package:avalia/screens/components/exams_correction_student.dart';
import 'package:avalia/screens/exams_screens.dart';
import 'package:flutter/material.dart';
import 'package:avalia/screens/components/history_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: Expanded(child: Row(
            children: [
              Container(
                height: 45.0,
                width: 45.0,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(122, 223, 64, 251),
                  
                  borderRadius: BorderRadius.circular(50.0)
                ),
                child: Icon(Icons.school_outlined, size: 20, color: Colors.purple,),
              ),
              SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Olá, Fulano de Tal.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                  Text('fulando@gmail.com', style: TextStyle(fontSize: 12),)
                ],
              )
            ], 
          ),), 
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClassScreens()),
            );
                      },
                      child: CardDashbordScreen(
                      icon: Icons.group_outlined,
                      colorBackground: const Color.fromARGB(97, 255, 253, 124),
                      colorIcon: const Color.fromARGB(255, 190, 187, 0),
                      title: 'Minhas Turmas',
                      number: '100',
                      subtitle: 'Turmas',
                    ),
                  ),
                    ),
                  
                  SizedBox(width: 8.0),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExamsScreens()),
            );
                      },
                      child:  CardDashbordScreen(
                      icon: Icons.article_outlined,
                      colorBackground: const Color.fromARGB(82, 52, 175, 206),
                      colorIcon: const Color.fromARGB(255, 62, 87, 94),
                      title: 'Provas Recentes',
                      number: '100',
                      subtitle: 'Provas',
                    ),
                    )
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              Text(
                'Atividades Recentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index) {
                   return HistoryScreens(
                      icon: Icons.article_outlined,
                      colorBackground: const Color.fromARGB(82, 52, 175, 206),
                      colorIcon: const Color.fromARGB(255, 62, 87, 94),
                      title: 'Prova de Matemática',
                      subtitle: 'Turma 1',
                      datetime: DateTime.now().subtract(Duration(minutes: 500)),
                    ); // Replace with your HistoryScreens widge
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}