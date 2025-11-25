import 'package:flutter/material.dart';

class StudentClassCard extends StatelessWidget {
  const StudentClassCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Card(
      color: Colors.white,
      child: Padding(padding: EdgeInsets.all(16.0), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nome",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600),),
                  SizedBox(height: 5,),
                  Text("Matricula: ",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w400),),
                ],
              ),
              Icon(Icons.arrow_right),
            ],
          ),
          SizedBox(height: 10,),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Média Geral:',),
                  Text('4.5'),
                ]
              ), 
              Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                
                decoration: BoxDecoration(
                  color: const Color.fromARGB(26, 247, 180, 80),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Row(children: [
                    Text("●", style: TextStyle(color: Colors.orange,),),
                    SizedBox(width: 5,),
                    Text('Correção Pendente', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),)
                  ],)
                ),
              )
            ],
          )
        ]
      )),

    );
  }
}
  
  