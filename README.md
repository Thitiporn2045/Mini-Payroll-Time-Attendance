# Mini Payroll & Time Attendance

โปรเจกต์นี้เป็นระบบ Mini Payroll & Time Attendance ที่พัฒนาด้วย Ruby on Rails โดยใช้ PostgreSQL เป็นฐานข้อมูล สำหรับจัดการข้อมูลพนักงาน บันทึกเวลาเข้าออกงาน และคำนวณสรุปเงินเดือนรายเดือน

## ภาพรวมระบบ

ระบบนี้ครอบคลุม 3 ส่วนหลักตามโจทย์:

1. Employee Management
2. Time Attendance
3. Payroll Calculation

หน้า UI ใช้ Tailwind CSS และออกแบบให้เน้นความอ่านง่ายและใช้งานจริง

## ขอบเขตที่ทำตาม Requirement

### 1. Employee Management
- แสดงรายการพนักงาน
- เพิ่มพนักงาน
- แก้ไขข้อมูลพนักงาน
- ดูรายละเอียดพนักงาน
- ลบพนักงาน
- ค้นหาพนักงานตามชื่อ
- กรองพนักงานตามตำแหน่ง

ข้อมูลพนักงานที่รองรับ:
- ชื่อ
- เงินเดือน
- ตำแหน่ง

### 2. Time Attendance
- พนักงาน 1 คนมี attendance ได้หลายรายการ
- พนักงาน 1 คนมี attendance ได้เพียง 1 รายการต่อวันทำงาน
- `check_out` ต้องเกิดหลัง `check_in`
- ถ้าทำงานเกิน 8 ชั่วโมง ส่วนที่เกินจะถือเป็น OT
- สามารถเพิ่มและแก้ไข attendance ได้จาก:
  - หน้า employee detail
  - หน้า workspace attendance รวม
- สามารถกรอง attendance ตามสถานะ
- สามารถกรอง attendance ตามชื่อพนักงานในหน้า workspace
- สามารถกรอง attendance ตามเดือนในหน้า employee detail

### 3. Payroll Calculation
ในหน้า Employee Show จะแสดงข้อมูล:
- เงินเดือนพื้นฐานรายเดือน
- จำนวนวันทำงาน
- จำนวน OT hours
- OT Pay
- Tax
- Net Pay

สูตรที่ใช้:

`OT Pay = OT hours x (salary / 30 / 8)`

Tax แบบขั้นบันได:
- เงินได้ไม่เกิน 30,000 บาท = 0%
- เงินได้ 30,001 - 50,000 บาท = 5%
- เงินได้ส่วนที่เกิน 50,000 บาท = 10%

หมายเหตุ: สำหรับ mini project นี้ ภาษีถูกคำนวณจาก `base_salary` เท่านั้น

## สิ่งที่ทำเพิ่มจาก Requirement

- Turbo-powered filtering และ partial update
- หน้า workspace สำหรับจัดการ attendance ของพนักงานทุกคน
- การ normalize ชื่อตำแหน่งเพื่อป้องกัน duplicate แบบต่างตัวพิมพ์/มีช่องว่าง
- test coverage ฝั่ง model, controller, service
- localized validation messages ภาษาไทย
- การคง filter context หลัง submit บาง flow เช่น employee detail และ attendance workspace

## Tech Stack

- Ruby on Rails
- PostgreSQL
- Tailwind CSS
- Turbo / Stimulus
- Minitest

## การเตรียมเครื่อง

ควรมีเครื่องมือดังนี้:
- Ruby 3.x
- Bundler
- Docker
- Node.js

## การตั้งค่า Environment

โปรเจกต์นี้อ่านค่าฐานข้อมูลจาก environment variables ใน `config/database.yml`

ให้ copy ไฟล์ตัวอย่างก่อน:

```bash
cp .env.example .env
```

จากนั้นแก้ค่าตามเครื่องของตัวเองหากต้องการ

## Database ผ่าน Docker

แนวทางหลักของโปรเจกต์นี้คือรัน PostgreSQL ผ่าน Docker

ตัวอย่างคำสั่ง:

```bash
docker run --name mini-payroll-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=mini_payroll_and_attendance_development \
  -p 5432:5432 \
  -d postgres:16
```

เนื่องจาก test database ใช้คนละชื่อกับ development database ให้สร้างเพิ่มอีก 1 database ภายหลัง หรือปล่อยให้ Rails จัดการตอน `db:create` ตามค่าที่อยู่ใน `.env`

## ขั้นตอนติดตั้งโปรเจกต์

1. ติดตั้ง gem

```bash
bundle install
```

2. เตรียมไฟล์ environment

```bash
cp .env.example .env
```

3. สร้างฐานข้อมูล, migrate และ seed

```bash
bin/rails db:drop db:create db:migrate db:seed
```

## วิธีรันโปรเจกต์

```bash
bin/rails server
```

จากนั้นเปิด:

```text
http://localhost:3000
```

## วิธีรัน Test

รันทั้งชุด:

```bash
bin/rails test
```

รันเฉพาะไฟล์:

```bash
bin/rails test test/models/attendance_test.rb
bin/rails test test/controllers/employees_controller_test.rb
bin/rails test test/controllers/attendances_controller_test.rb
bin/rails test test/services/employee_payroll_calculator_test.rb
```

รัน RuboCop:

```bash
bin/rubocop --no-server
```

## การใช้ AI Tools

AI tools ที่ใช้:
- OpenAI / Codex-style assistant

AI ถูกใช้ช่วยในส่วนต่อไปนี้:
- ช่วยสร้าง prototype ให้สามารถทดลองกดใช้งานได้ตาม wireframe ที่ออกแบบไว้เอง
- ช่วยขึ้น project ให้ตามแบบ prototype
- debug runtime errors
- วิเคราะห์ failing tests
- ช่วยเพิ่มและปรับ test coverage
- review flow ของ controller / model / service
- ช่วยเรียบเรียง README และเอกสารประกอบโปรเจกต์

## Known Limitations

- ภาษีในโปรเจกต์นี้คิดจาก `base_salary` เท่านั้น
- ยังไม่มี authentication / authorization
- ยังไม่มี deployment
- ยังไม่มี browser/system test
- attendance model รองรับ 1 record ต่อคนต่อวัน ยังไม่รองรับหลาย shift ในวันเดียว

## Future Improvements

- เพิ่ม system tests แบบ end-to-end
- เพิ่ม pagination สำหรับข้อมูลจำนวนมาก
- เพิ่ม export/report
- เพิ่ม dashboard analytics สำหรับ attendance และ payroll
- เพิ่ม role-based access control หากระบบขยายเกินขอบเขต assignment
