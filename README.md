# LIFT

แอปบันทึกและติดตามการออกกำลังกายแบบยกน้ำหนัก (weightlifting tracker) พัฒนาด้วย Flutter รองรับทั้ง Android, iOS, Web และ Windows

## ฟีเจอร์

- **หน้าหลัก** — เริ่ม/บันทึกเซสชันการออกกำลังกาย เพิ่มท่าออกกำลังกายและเซ็ต พร้อมตัวจับเวลาพัก (rest timer) และตัวช่วยคำนวณแผ่นน้ำหนัก (plate calculator)
- **ประวัติ** — ดูรายการเซสชันที่ผ่านมาและรายละเอียดของแต่ละเซสชัน
- **สถิติ** — กราฟและสรุปข้อมูลความก้าวหน้า (fl_chart)
- บันทึกข้อมูลลงเครื่องด้วย SQLite (ใช้งานได้ทั้งแบบ native และบนเว็บ)
- ตั้งค่าหน่วยน้ำหนัก (กก./ปอนด์)

## เทคโนโลยีที่ใช้

- [Flutter](https://flutter.dev) / Dart (SDK `^3.9.2`)
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) — state management
- [go_router](https://pub.dev/packages/go_router) — routing
- [sqflite](https://pub.dev/packages/sqflite) / [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) — ฐานข้อมูลในเครื่อง
- [fl_chart](https://pub.dev/packages/fl_chart) — กราฟสถิติ
- [google_fonts](https://pub.dev/packages/google_fonts) — ฟอนต์ (Space Grotesk / Inter)
- [shared_preferences](https://pub.dev/packages/shared_preferences) — เก็บค่าตั้งค่า
- Firebase Hosting — สำหรับ deploy เวอร์ชันเว็บ

## เริ่มต้นใช้งาน

ต้องติดตั้ง [Flutter SDK](https://docs.flutter.dev/get-started/install) ก่อน

```bash
# ติดตั้ง dependencies
flutter pub get

# รันแอป (เลือกอุปกรณ์/emulator ที่เชื่อมต่ออยู่)
flutter run

# รันบนเว็บโดยเฉพาะ
flutter run -d chrome
```

## คำสั่งที่ใช้บ่อย

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `flutter analyze` | ตรวจสอบโค้ดตามกฎ lint |
| `dart format .` | จัดรูปแบบโค้ด |
| `flutter test` | รันเทส |
| `flutter build web` | build เวอร์ชันเว็บ |
| `firebase deploy --only hosting` | deploy เวอร์ชันเว็บขึ้น Firebase Hosting |

## โครงสร้างโปรเจกต์

```
lib/
  main.dart            entry point
  app.dart              MaterialApp, ธีม, bottom navigation
  core/
    database/           การเชื่อมต่อฐานข้อมูลและ DAO
    models/              โมเดลข้อมูล (exercise, session, workout_set, exercise_config)
    providers/            provider ที่ใช้ร่วมกันหลายฟีเจอร์
    widgets/               widget ที่ใช้ร่วมกัน
  features/
    home/                หน้าหลัก / เซสชันปัจจุบัน
    workout/             บันทึกการออกกำลังกาย, เซ็ต, ตัวจับเวลาพัก
    history/              ประวัติเซสชัน
    stats/                 สถิติและกราฟ
```

แต่ละฟีเจอร์แยกไฟล์ `*_provider.dart` (state/logic) และ `*_screen.dart` (UI) ออกจากกัน
