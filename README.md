# 📍 Geolocation-Based Attendance Tracking System

A smart attendance system that uses **QR Code + Geolocation + Firebase** to ensure secure and real-time attendance tracking.

---

## 🚀 Features

* 📱 **QR Code Based Attendance**

  * Teacher generates QR code for each class session
  * Students scan QR to mark attendance

* 📍 **Geolocation Verification**

  * Attendance is only marked if student is within valid range (15 meters)

* ⏱ **Session-Based Attendance**

  * Teacher starts and closes session
  * Attendance is recorded only within session time

* 🔐 **Authentication System**

  * Separate login for **Students** and **Teachers**
  * Firebase Authentication used

* ☁️ **Cloud Database**

  * Attendance stored securely using **Firebase Firestore**

* 📊 **Attendance Dashboard**

  * Teacher can view:

    * Current attendance
    * Past attendance
    * Student list (name, email, time)

* 🖼 **QR Sharing**

  * QR can be shared via WhatsApp or other apps
  * Proper white border ensures easy scanning

---

## 🛠 Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase
* **Database:** Cloud Firestore
* **Authentication:** Firebase Auth
* **Location Services:** Geolocator
* **QR Code:** qr_flutter & mobile_scanner

---

## 📂 Project Structure

```
lib/
│── main.dart
│── login_screen.dart
│── register_screen.dart
│── teacher_dashboard.dart
│── student_screen.dart
│── attendance_list_screen.dart
│── past_classes_screen.dart
```

---

## ⚙️ How It Works

### 👨‍🏫 Teacher Flow

1. Login as Teacher
2. Enter subject and start class
3. QR Code is generated
4. Share QR with students
5. Close session
6. View attendance list

### 👨‍🎓 Student Flow

1. Login as Student
2. Scan QR code
3. Location is verified
4. Attendance is marked if within range

---

## 📸 Screenshots

> Add screenshots here for better presentation

---

## 🔒 Security Features

* Prevents proxy attendance using location check
* Session-based validation (start & end time)
* Duplicate attendance prevention

---

## 🚀 Future Improvements

* 📊 Export attendance to Excel
* 📍 Map view of student locations
* 🔔 Notifications for attendance
* 📷 Face recognition integration

---

## 🧑‍💻 Author

**Soham Narvelkar**

---

## ⭐ Contribution

Feel free to fork this project and improve it!

---

## 📌 Note

Make sure to add your own:

* `google-services.json`
* Firebase configuration

---

## 🏆 P
