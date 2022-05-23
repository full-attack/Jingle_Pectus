import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatting/allConstants/all_constants.dart';
import 'package:chatting/providers/auth_provider.dart';
import 'package:chatting/screens/home_page.dart';
import 'package:chatting/screens/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      checkSignedIn();
    });
  }

  void checkSignedIn() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();
    if (isLoggedIn) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
      return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Рады приветствовать в Jingle Pectus",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: Sizes.dimen_18, fontFamily: 'Palanquin', color: Colors.white),
            ),
            Image.asset(
              'assets/images/splash_jp.png',
              width: 500,
              height: 500,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Вы будете поражены",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: Sizes.dimen_18, color: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            const CircularProgressIndicator(
              color: AppColors.white
            ),
          ],
        ),
      ),
    );
  }
}
