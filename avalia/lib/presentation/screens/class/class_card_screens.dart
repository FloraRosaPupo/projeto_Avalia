import 'package:flutter/material.dart';
class TestScreens extends StatelessWidget {
  const TestScreens({Key? key, required this.title, required this.subtitle, required this.counterStudent, required this.icon}) : super(key: key);

  final String title;
  final String subtitle;
  final int counterStudent;
  
  final IconData icon;


  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
              padding: EdgeInsets.all(8.0),
              child:  Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                             Icon(icon),
                          SizedBox(width: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          
                            Text(title),
                            Text(subtitle),
                          ],),
                          ]),
                         
                         
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text('${counterStudent} ${counterStudent > 1 ? 'alunos' : 'aluno'}', style: TextStyle(color: Colors.white)),
                          )
                        ],
                         
                        )
                  
                )
                ),
    );
            
  }
}


