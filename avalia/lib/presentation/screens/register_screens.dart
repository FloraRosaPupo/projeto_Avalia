import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/state/base_state.dart';
import '../cubit/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  
  bool isObscured = false;
  bool loadingController = false;

  String nome = '';
  String email = '';
  String password = '';

  int qtdControllerSenha = 0;

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  @override
  void dispose() {
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }
  


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: BlocListener<AuthCubit, BaseState>(listener: (context, state) {
        if (state is SuccessState) {
          Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
        }else if (state is ErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao realizar o Cadastro, tente novamente!'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
          loadingController = false;
        }else if (state is LoadingState) {
          loadingController = true;
          //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Carregando...')));
        }else if (state is InitialState) {
          loadingController = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inicializando...')));
        }
      }, 
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Container(
        padding: EdgeInsets.all(32.0),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 90.0,
              width: 90.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.0),
                color: Colors.purple,
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
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Sistem inteligente de correção de provas',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),

            TextField( 
              focusNode: nameFocus,
              decoration: InputDecoration(
                hintText: 'Nome',
                hintStyle: TextStyle(color: Color.fromARGB(99, 158, 158, 158)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: Color.fromARGB(99, 158, 158, 158),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.purple, width: 2.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
              ),
              
              onChanged: (value) {
                nome= value.trim();
              },
            ),
            SizedBox(height: 8.0),

            TextField( 
              focusNode: emailFocus,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(color: Color.fromARGB(99, 158, 158, 158)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: Color.fromARGB(99, 158, 158, 158),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.purple, width: 2.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                email= value.trim();
              },
            ),
            SizedBox(height: 8.0),
            TextField(
              focusNode: passwordFocus,
              obscureText: !isObscured,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                icon: Icon(
                  isObscured ?  Icons.visibility : Icons.visibility_off,
                  color: Colors.purple,
                ),
                onPressed: () {
                  setState(() {
                    isObscured = !isObscured;
                  });
                },
              ),
                hintText: 'Senha',
                hintStyle: TextStyle(color: Color.fromARGB(99, 158, 158, 158)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: const Color.fromARGB(99, 158, 158, 158),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.purple, width: 2.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.visiblePassword,
              onChanged: (value) {
                password = value.trim();
                qtdControllerSenha = value.length;
              },
            ),
           
            SizedBox(height: 8.0),

            BlocBuilder<AuthCubit, BaseState>(
              builder: (context, state) {
                final isLoading = state is LoadingState;
                return Container(
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

                onPressed: isLoading || nome.isEmpty || email.isEmpty || password.isEmpty
                    ? (){}
                    : qtdControllerSenha < 6
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('A senha deve ter no mínimo 6 caracteres')),
                            );
                          }
                        : () {
                            context.read<AuthCubit>().register(
                              name: nome,
                              email: email,
                              password: password,
                            );
                          },
                child: Text(isLoading?'Registrando...':'Registrar', style: TextStyle(color: Colors.white)),
              ),
            );
              }
            ),

            SizedBox(height: 8.0),
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Já tem uma conta? Faça login'),
              ),
            ),
          ],
        ),
      ),
      ),
      )
    ),
    ));
  }
}