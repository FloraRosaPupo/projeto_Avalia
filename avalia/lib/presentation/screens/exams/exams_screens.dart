import 'package:avalia/presentation/screens/exams/exams_card_screens.dart';
import 'package:flutter/material.dart';
import 'package:avalia/presentation/screens/exams/exams_created_modal.dart';

class ExamsScreens extends StatelessWidget {
  const ExamsScreens({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: Text('Provas'),
        
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: (){
            showModalBottomSheet(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
              backgroundColor: Colors.white,
              context: context,
              builder: (BuildContext context) {
                return ModalCreatedExams();
              },
            );
          },),
        ]
      ),  
      body:Padding(padding: EdgeInsets.all(16.0), 
      child: Container(
        child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) => SizedBox(height: 8),
          itemCount: 10,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index){
            return InkWell(
              onTap: (){},
              child: CardExamsScreens(title:  'Turma 1',status: 'Concluido', colorBorder: const Color.fromARGB(255, 201, 21, 192), colorBackground: const Color.fromARGB(80, 201, 21, 192), icon: Icons.book,),
            );
            
          },
        ),
      )), 

    );
  }
}