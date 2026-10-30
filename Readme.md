# คู่มือเริ่มต้นใช้งานโปรเจกต์

## สิ่งที่ต้องติดตั้งก่อน

- [Git](https://git-scm.com/) สำหรับโคลนโปรเจกต์
- [Node.js และ npm](https://nodejs.org/) สำหรับติดตั้งและรัน backend
- [Flutter SDK](https://docs.flutter.dev/get-started/install) สำหรับติดตั้ง dependencies และรัน frontend
- อุปกรณ์หรือ emulator ที่ Flutter รองรับ หากต้องการรัน frontend

ตรวจสอบว่าเรียกใช้เครื่องมือจาก Terminal ได้:

```powershell
git --version
node --version
npm --version
flutter --version
```

## 1. โคลนโปรเจกต์

เปิด PowerShell หรือ Terminal แล้วโคลนโปรเจกต์:

```powershell
git clone https://github.com/Meawdam/Mobile-Application-Development.git
cd mobile_application_development
```

## 2. ติดตั้งคำสั่ง CLI

รันคำสั่งต่อไปนี้จากโฟลเดอร์หลักของโปรเจกต์:

```powershell
cd cli
npm link
cd ..
```

`npm link` จะลงทะเบียนคำสั่ง `prod` ให้เรียกใช้ได้จาก Terminal หลังติดตั้งแล้ว ให้รันคำสั่ง CLI จากโฟลเดอร์หลักของโปรเจกต์

## 3. ติดตั้ง dependencies

```powershell
prod i
```

หรือใช้คำสั่งแบบเต็ม:

```powershell
prod install
```

CLI จะติดตั้ง dependencies ของ backend ด้วย `npm install` ก่อน จากนั้นติดตั้ง dependencies ของ frontend ด้วย `flutter pub get` หากขั้นตอนใดล้มเหลว คำสั่งจะหยุดและแสดงข้อผิดพลาด

## 4. รัน frontend หรือ backend

```powershell
prod run
```

ใช้ปุ่มลูกศรขึ้น/ลงเพื่อเลือก **Run frontend** หรือ **Run backend** แล้วกด Enter เมนูนี้ต้องใช้ใน Terminal แบบโต้ตอบ

## คำสั่ง CLI

| คำสั่ง | ผลลัพธ์ |
| --- | --- |
| `prod i` | ติดตั้ง dependencies ของ backend และ frontend |
| `prod install` | ทำงานเหมือน `prod i` |
| `prod run` | เปิดเมนูให้เลือกรัน frontend หรือ backend ด้วยปุ่มลูกศร |
| `prod --help` | แสดงวิธีใช้คำสั่ง |

| ตัวเลือกในเมนู `prod run` | คำสั่งที่ CLI ใช้ |
| --- | --- |
| Run frontend | รัน `flutter run` ในโฟลเดอร์ `frontend` |
| Run backend | รัน `nodemon app.js` ผ่าน `npm run dev` ในโฟลเดอร์ `backend` |

> **หมายเหตุ:** การรัน backend ต้องมีไฟล์ `backend/app.js` ก่อน หากยังไม่มีไฟล์นี้ ให้เพิ่ม entry point ของ backend ก่อนเลือก Run backend
