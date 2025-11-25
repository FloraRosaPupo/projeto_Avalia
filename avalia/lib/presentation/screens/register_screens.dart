import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.lock,
              size: 100.0,
              color: Colors.grey[800]
            ),

            TextField(
              decoration: InputDecoration(hintText: 'Nome'),
              textAlign: TextAlign.center,
             
              onChanged: (value) {
                //Do something with the user input.
              }
            ),


           
            TextField(
              decoration: InputDecoration(hintText: 'Email'),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                //Do something with the user input.
              }
            ),

            TextField(
              decoration: InputDecoration(hintText: 'Senha'),
              textAlign: TextAlign.center,
              obscureText: true,
              onChanged: (value) {
                //Do something with the user input.
              }
            ),

            ElevatedButton(
              onPressed: () {
                //Go to the login screen.
              },
              child: Text('Cadastrar'),
            ),

            
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              child: Text('Voltar' ),
            ),



          ]
        ),
      )
    );
  }
}