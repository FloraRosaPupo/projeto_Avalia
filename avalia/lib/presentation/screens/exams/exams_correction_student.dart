import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class ExamsCorrectionStudent extends StatelessWidget {
  const ExamsCorrectionStudent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 4,),
          Text('Upload do Gabarito do Aluno', style: TextStyle(fontSize: 14,)),
          SizedBox(height: 16,),
          Container(
            width: double.infinity,
            height: 300,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration( 
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color.fromARGB(86, 190, 189, 189),
                width: 2
              )
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Arraste e solte o arquivo aqui', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                  SizedBox(height: 16,),
                  //Icon(Icons.upload, size: 48, color: Colors.grey,),
                  SizedBox(height: 16,),
                  Text('Formato aceito: JPG e PNG', style: TextStyle(color: Colors.grey),),
                  SizedBox(height: 16,),
                  ElevatedButton(
                    onPressed: (){},
                    child: Text('Selecionar Arquivo'),
                  )
                ]
              ),
            ),
          ), 

          SizedBox(height: 16,),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              minimumSize: Size(double.infinity, 50)
            ),
            onPressed: (){},
            icon: Icon(FontAwesomeIcons.robot, color: Colors.white,),
            label: Text('Corrigir', style: TextStyle(color: Colors.white),),
          ),
        ]
      )
    );
  }
}