import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:campusapp/models/faculty.dart';

import '../../widgets/auth_widgets/button.dart';
import '../../widgets/auth_widgets/textfield.dart';
import '../../../models/account.dart';
import '../../service/user_service.dart';
// import '../../providers/auth_provider.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  List<FacultyModel> _faculties = [];
  // final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _lastName = TextEditingController();
  final _group = TextEditingController();
  DateTime? _birthDate;
  Year _selectedYear = Year.year1;
  int? _selectedFacultyId;

  @override
  void initState() {
    super.initState();
    fetchFaculties();
  }

  Future<void> fetchFaculties() async {
    final uri = Uri.parse('${dotenv.env['API_BASE_URL']}/api/faculty');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _faculties = data.map((e) => FacultyModel.fromJson(e)).toList();
        if (_faculties.isNotEmpty) _selectedFacultyId = _faculties.first.id;
      });
    } else {
      Fluttertoast.showToast(msg: "โหลดคณะล้มเหลว");
    }
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
                        controller: _username,
                        decoration: const InputDecoration(
                          hintText: "กรุณากรอกชื่อผู้ใช้",
                          labelText: "ชื่อผู้ใช้",
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
                            return 'กรุณากรอกชื่อผู้ใช้';
                          }
                          if (value.length < 3) {
                            return 'ชื่อผู้ใช้ต้องยาวอย่างน้อย 3 ตัวอักษร';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
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
                      _faculties.isEmpty
                          ? const Text('กำลังโหลดคณะ...')
                          : CustomDropdownField<int>(
                            label: 'คณะ',
                            value: _selectedFacultyId!,
                            items:
                                _faculties
                                    .map(
                                      (f) => DropdownMenuItem<int>(
                                        value: f.id,
                                        child: Text(f.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() => _selectedFacultyId = value);
                            },
                          ),
                      const SizedBox(height: 20),
                      // วันเกิด
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(
                              now.year - 18,
                              now.month,
                              now.day,
                            ),
                            firstDate: DateTime(1900),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setState(() => _birthDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'วันเดือนปีเกิด',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 10,
                            ),
                          ),
                          child: Text(
                            _birthDate == null
                                ? 'แตะเพื่อเลือกวันเกิด'
                                : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
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

    if (_birthDate == null) {
      Fluttertoast.showToast(
        msg: 'กรุณาเลือกวันเดือนปีเกิด',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    final userService = UserService();
    final navigator = Navigator.of(context); // จับไว้ก่อน await

    final userModel = User(
      email: _email.text,
      password: _password.text,
      firstName: _firstName.text,
      lastName: _lastName.text,
      year: _selectedYear,
      group: _group.text,
      faculty: Faculty.other,
    );

    try {
      final ok = await userService.signup(
        userModel,
        username: _username.text,
        birthDate: _birthDate!,
        facultyId: _selectedFacultyId,
        roleId: 2,
      );
      if (ok) {
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
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (e is ApiException) {
        message = e.detail ?? e.body;
      }

      Fluttertoast.showToast(
        msg: message,
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
