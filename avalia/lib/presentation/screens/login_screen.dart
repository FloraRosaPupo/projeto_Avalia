import 'package:avalia/presentation/cubit/auth_cubit.dart';
import 'package:avalia/presentation/screens/dashboard/dashboard_screens.dart';
import 'package:avalia/presentation/screens/register_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/state/base_state.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '';
  String password = '';

  bool isObscured = false;
  bool loadingController = false;
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  @override
  void dispose() {
    
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
          loadingController = false;
          Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
        }else if (state is ErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Senha ou email incorreto, valide os campos e tente novamente')));
          loadingController = false;
        }else if (state is LoadingState) {
          //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Carregando...')));
          loadingController = true;
        }else if (state is InitialState) {
          loadingController = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inicializando...')));
        }
      }, 
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Container(
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
                onPressed: isLoading || email.isEmpty || password.isEmpty
                          ? (){}
                          : () {
                              context.read<AuthCubit>().login(
                                email: email,
                                password: password,
                              );
                            },
                child: Text(loadingController? 'Carregando...':'Entrar', style: TextStyle(color: Colors.white)),
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
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text('Criar conta'),
              ),
            ),
          ],
        ),
      ),
    ),
    ));
  }
}
