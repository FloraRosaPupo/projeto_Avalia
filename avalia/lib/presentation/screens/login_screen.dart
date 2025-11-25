import 'package:avalia/presentation/screens/dashboard/dashboard_screens.dart';
import 'package:avalia/presentation/screens/register_screens.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.all(32.0),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 90.0,
              width: 90.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.0),
                color:Colors.purple,
              ),
              child: Icon(
              Icons.school_outlined,
              size: 50.0,
              color: Colors.white,
            ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Avalia!',
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
                color: Colors.black
              ),
            ),
            SizedBox(height: 8.0),
            Text('Sistem inteligente de correção de provas', style: TextStyle(fontSize: 16),),
            SizedBox(height: 8.0),
           
            TextField(
              focusNode: FocusNode()..addListener(() {}),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(
                  color: Color.fromARGB(99, 158, 158, 158)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Color.fromARGB(99, 158, 158, 158)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.purple, width: 2.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                //Do something with the user input.
              }
              
            ),
            SizedBox(height: 8.0),
            TextField(
              focusNode: FocusNode()..addListener(() {}),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Senha',
                hintStyle: TextStyle(
                  color:Color.fromARGB(99, 158, 158, 158)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: const Color.fromARGB(99, 158, 158, 158)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.purple, width: 2.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none
                ),
              ),
              keyboardType: TextInputType.visiblePassword,
              onChanged: (value) {
                //Do something with the user input.
              }

            ),
            
              
            SizedBox(height: 2.0),
           Align( 
             alignment: Alignment.centerRight,
             child:  InkWell(
              onTap: () {
                //Go to registration screen.
              },
              child: Text('Esqueci minha senha'),
            ),
           ),
            SizedBox(height: 8.0),

            Container(
              height: 45,
              width: double.infinity,
              child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shadowColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
              ),
              
              onPressed: () {
                Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
              },
              child: Text('Entrar', style: TextStyle(color: Colors.white),),
            ),
            ),
            
            
            SizedBox(height: 4.0),
            Center(
              child: InkWell(
              onTap: () {
                Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterScreen()),
            );
              },
              child: Text('Criar conta' ),
            ),
            )



          ]
        ),

      )
    );
  }
}