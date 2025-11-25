import 'package:avalia/presentation/screens/class/class_detail_screens.dart';
import 'package:avalia/presentation/screens/class/class_card_screens.dart';
import 'package:avalia/presentation/screens/class/class_created_modal.dart';
import 'package:flutter/material.dart';
class ClassScreens extends StatelessWidget {
  const ClassScreens({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: Text('Turmas'),
        
      ),  
      body:Padding(padding: EdgeInsets.all(16.0), child: Container(
        child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) => SizedBox(height: 8),
          itemCount: 10,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index){
            return InkWell(
              onTap: (){
                Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClassDetailScreens()),
            );
              },
              child: TestScreens(title:  'Turma 1',subtitle: 'Matematica', counterStudent: 0, icon: Icons.book,),
            );
            
          },
        ),
      )), 
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return Center(
                child: ModalCreatedClass(),
              );
            },
          );
          
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}