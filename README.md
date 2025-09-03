# 🏫 Campus Life Hub - Group 01

แอปพลิเคชัน Flutter สำหรับจัดการชีวิตนักศึกษา เช่น บัญชีผู้ใช้, การเข้าใช้งาน, และข้อมูลเบื้องต้นของแอป  
พัฒนาโดยทีม **Group 01** ในโปรเจกต์ Campus Life Hub

---

## 📦 Repository

🔗 **Main Repository (GitHub):**  
[👉 campus_life_hub01 - Group 01](https://github.com/krahyor/campus_life_hub01)

---

## 🎨 UI/UX Design (Figma)

🔗 **Figma Design:**  
[👉 Splash Screen & Onboarding (Figma)](https://www.figma.com/design/drA0RgHq00Qnel0PVu8CyY/Campus_life_hub_01?m=auto&t=Vn0Y6iKUI2J9B3a5-1)

---

## 📁 Session 01 Resources

🔗 **Google Drive Folder:**  
[👉 Drive Link](https://drive.google.com/drive/folders/1vMi7lpKKdgaSfGteFcaVJSakuMO7krmj?usp=drive_link)

ภายในประกอบด้วย:

- ✅ Wireframe (หน้าตาคร่าว ๆ ของแอป)
- ✅ Dart Programming Basic Summary (สรุปพื้นฐานภาษา Dart)
- ✅ Project Link (ลิงก์โปรเจกต์เวอร์ชันแรก)
- ✅ Figma: Splash Screen และ Onboarding

---

## 🧱 โครงสร้างโฟลเดอร์ (Project Structure)



## Architecture
```base 
|__lib/
   |_core/
   | |_routes.dart
   |_models/
   | |_account.dart
   |_ui/ 
   | |_providers/
   | |  |_auth_provider.dart
   | |  |_profile_provider.dart
   | |_screens/
   | |  |_account_screen/
   | |     |_login_screen.dart
   | |     |_signup_screen.dart
   | |_service/
   | |     |_user_service.dart
   | |_widgets/
   |       |_auth_widgets/
   |          |_button.dart
   |          |_textfield.dart
   |_main.dart
```
# 📱 Flutter App Structure

สถาปัตยกรรมของแอปพลิเคชัน Flutter ที่ออกแบบให้แยกส่วนชัดเจน เพื่อความง่ายในการพัฒนา ดูแล และขยายระบบในอนาคต

---

## 📁 lib/main.dart
ไฟล์หลักที่รันเป็นอันดับแรกเมื่อเปิดแอป  
- ทำหน้าที่กำหนดการเริ่มต้นของแอป เช่น:
  - เรียก `runApp()`
  - ตั้งค่า `MaterialApp`
  - กำหนดธีม และ initial route

---

## 📁 core/routes.dart
จัดการเรื่อง **Routing** ของแอป  
- รวมรายชื่อ route ทั้งหมด
- สร้างและควบคุมการนำทางระหว่างหน้า
- ใช้ร่วมกับ `RouteNames`, `RouteGenerator` หรือ `onGenerateRoute`

---

## 📁 models/account.dart
กำหนด **โครงสร้างข้อมูลของ Account**  
- ใช้เป็น data model สำหรับบัญชีผู้ใช้
- ตัวอย่าง field: `email`, `name`, `uid`, เป็นต้น

---

## 📁 ui/
โฟลเดอร์หลักที่เกี่ยวข้องกับ **User Interface และการเชื่อมต่อกับ logic/backend**  
- จัดกลุ่มตามหน้าที่ เช่น state management, UI, services และ widgets

---

## 📁 providers/
จัดการ **State Management** ด้วย `Provider`, `ChangeNotifier`, หรือ `Riverpod`  
- `auth_provider.dart`: จัดการการ login/logout และตรวจสอบสถานะผู้ใช้
- `profile_provider.dart`: จัดการข้อมูลโปรไฟล์ เช่น แก้ไขชื่อ หรืออัปโหลดรูป

---

## 📁 screens/account_screen/
รวมหน้าจอ UI ที่เกี่ยวข้องกับ **บัญชีผู้ใช้**

- `login_screen.dart`: หน้าล็อกอินของผู้ใช้  
- `signup_screen.dart`: หน้าสมัครสมาชิก  

> ทั้งสองไฟล์เรียกใช้งาน provider เพื่อจัดการ logic การยืนยันตัวตน

---

## 📁 service/
เก็บ **service layer** หรือ **business logic** ที่ไม่เกี่ยวข้องกับ UI โดยตรง  
- `user_service.dart`: 
  - ติดต่อ Firebase หรือ API ภายนอก  
  - ดึง/บันทึกข้อมูลผู้ใช้  
  - ถูกเรียกใช้โดย provider เพื่อแยก logic ออกจาก UI

---

## 📁 widgets/auth_widgets/
รวม **Custom Widgets ที่ใช้ซ้ำได้** ภายใต้ระบบ Authentication

- `button.dart`: ปุ่ม login/signup แบบ custom  
- `textfield.dart`: ช่องกรอกข้อมูลที่ปรับแต่ง style ได้เอง  

> ช่วยให้โค้ดดูสะอาด และสามารถนำกลับมาใช้ซ้ำได้ง่าย

---

🧠 **แนวทางการจัดโครงสร้างนี้ช่วยให้:**
- แยกความรับผิดชอบของแต่ละส่วนชัดเจน (Separation of Concerns)
- เพิ่มความสามารถในการดูแลโค้ดระยะยาว
- พัฒนาและทดสอบแยกแต่ละ module ได้สะดวก

---
