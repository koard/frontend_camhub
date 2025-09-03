import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

import '../../widgets/auth_widgets/button.dart';
import '../../widgets/auth_widgets/textfield.dart';
import '../../../models/account.dart';
import '../../service/user_service.dart';
import '../../providers/auth_provider.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _lastName = TextEditingController();
  final _group = TextEditingController();
  final _age = TextEditingController();
  Year _selectedYear = Year.year1;
  Faculty _selectedFaculty = Faculty.computerEngineering;

  @override
  void dispose() {
    super.dispose();
    _firstName.dispose();
    _email.dispose();
    _password.dispose();
    _lastName.dispose();
    _group.dispose();
    _age.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Life Hub'),
        backgroundColor: const Color(0xFF113F67),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "สร้างบัญชีผู้ใช้",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 17, 63, 103),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16), // ระยะขอบด้านในกรอบ
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade400,
                    ), // สีเส้นขอบ
                    borderRadius: BorderRadius.circular(8), // มุมโค้งมน
                    color: Colors.white, // สีพื้นหลังกรอบ (ถ้าต้องการ)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ข้อมูลผู้ใช้",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกรหัสผ่าน';
                          }
                          if (value.length < 6) {
                            return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ข้อมูลนักศึกษา",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomDropdownField<Year>(
                        label: 'ปีการศึกษา',
                        value: _selectedYear,
                        items:
                            Year.values.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(
                                  'ปี ${Year.values.indexOf(year) + 1}',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomDropdownField<Faculty>(
                        label: 'คณะ',
                        value: _selectedFaculty,
                        items:
                            Faculty.values.map((faculty) {
                              return DropdownMenuItem(
                                value: faculty,
                                child: Text(faculty.title),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFaculty = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(
                          hintText: "กรุณากรอกชื่อ",
                          labelText: "ชื่อ",
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
                            return 'กรุณากรอกชื่อ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          hintText: "กรุณากรอกนามสกุล",
                          labelText: "นามสกุล",
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
                            return 'กรุณากรอกนามสกุล';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "กรุณากรอกอายุ",
                          labelText: "อายุ",
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
                            return 'กรุณากรอกอายุ';
                          }
                          final age = int.tryParse(value);
                          if (age == null) {
                            return 'กรุณากรอกอายุเป็นตัวเลข';
                          }
                          if (age < 15 || age > 100) {
                            return 'อายุต้องอยู่ระหว่าง 15-100 ปี';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _group,
                        decoration: const InputDecoration(
                          hintText: "กรุณากรอกเทอม",
                          labelText: "เทอม",
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
                            return 'กรุณากรอกเทอม';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Align(
                  child: CustomButton(
                    label: "สมัครสมาชิก",
                    onPressed: _signup,
                    bttncolor: Color.fromARGB(255, 52, 105, 154),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("คุณมีบัญชีผู้ใช้แล้ว? "),
                    InkWell(
                      onTap: () => goToLogin(context),
                      child: const Text(
                        "เข้าสู่ระบบ",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  goToLogin(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );

  _signup() async {
    // ตรวจสอบ form validation ก่อน
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userService = UserService();
    final navigator = Navigator.of(context); // จับไว้ก่อน await

    // ตรวจสอบอีเมลซ้ำ
    final isEmailExists = await _auth.isEmailExists(_email.text);
    if (!mounted) return;
    if (isEmailExists) {
      Fluttertoast.showToast(
        msg: "อีเมลนี้ถูกใช้ไปแล้ว",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    final userModel = User(
      email: _email.text,
      password: _password.text,
      firstName: _firstName.text,
      lastName: _lastName.text,
      year: _selectedYear,
      group: _group.text,
      age: int.tryParse(_age.text) ?? 18,
      faculty: _selectedFaculty,
    );

    final user = await _auth.createUserWithEmailAndPassword(
      _email.text,
      _password.text,
    );

    if (user != null) {
      await userService.saveUser(user.uid, userModel);
      if (!mounted) return;

      Fluttertoast.showToast(
        msg: "สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      navigator.push(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
