import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../main_screen/main_screen.dart';
import '../../widgets/auth_widgets/button.dart';

import '../../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF113F67),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // const Spacer(),
                const SizedBox(height: 140),
                const Text(
                  "Campus Life Hub",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 17, 63, 103),
                  ),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft, // Align text to the left
                  child: const Text(
                    "เข้าสู่ระบบ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                ),

                const SizedBox(height: 15),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    hintText: "กรุณากรอกอีเมล",
                    labelText: "อีเมล",
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกอีเมล';
                    }
                    if (!value.contains('@')) {
                      return 'รูปแบบอีเมลไม่ถูกต้อง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "กรุณากรอกรหัสผ่าน",
                    labelText: "รหัสผ่าน",
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: "เข้าสู่ระบบ",
                  onPressed: _login,
                  bttncolor: Color.fromARGB(255, 52, 105, 154),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("คุณยังไม่มีบัญชีผู้ใช้? "),
                    InkWell(
                      onTap: () => goToSignup(context),
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  goToSignup(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SignupScreen()),
  );

  goToMainHomeScreen(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => MainHomeScreen()),
  );

  _login() async {
    // ตรวจสอบ form validation ก่อน
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await _auth.loginUserWithEmailAndPassword(
      _email.text,
      _password.text,
    );

    if (user == null) {
      log("เข้าสู่ระบบล้มเหลว: ${_email.text}");
      Fluttertoast.showToast(
        msg: "เข้าสู่ระบบล้มเหลว กรุณาลองใหม่",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if (!mounted) return;
    Fluttertoast.showToast(
      msg: "เข้าสู่ระบบสำเร็จ",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    goToMainHomeScreen(context);
  }
}
