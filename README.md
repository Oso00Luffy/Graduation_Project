# 🔐 SCC_App — Secure Communication & Cryptography App

A cross-platform Flutter application for secure communication and modern cryptography. Designed as a graduation project in Cybersecurity at Tafila Technical University.

> 🧪 Graduation Project by  
> **Osama Wesam Jaradat** [@Oso00Luffy](https://github.com/Oso00Luffy)  
> **Moath Amjad Hdairis**  [@moathhdairis]([https://github.com/moathhdairis])
> **Supervisor:** Dr. Eman

---

## 📚 Table of Contents

- [Project Objectives](#project-objectives)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Screenshots](#screenshots)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Educational Value](#educational-value)
- [To-Do](#to-do)
- [License](#license)
- [Links](#links)
- [Star History](#star-history)

---

## 🎯 Project Objectives

- Enable secure encryption/decryption of messages and images
- Support steganography for hiding messages in images or text
- Peer-to-peer secure chat system (local network/Bluetooth)
- Expiry for encrypted content and messages
- Modular, privacy-focused architecture for cybersecurity education

---

## 🛠 Tech Stack

| Layer        | Technology                          |
|--------------|-------------------------------------|
| Language     | Dart                                |
| Framework    | Flutter                             |
| Cryptography | AES, RSA (via [PointyCastle](https://pub.dev/packages/pointycastle)) |
| Steganography| Zero-width encoding, homoglyphs, whitespace |
| Communication| Local LAN/Bluetooth P2P             |
| Platform     | Android (Flutter)                   |

Other notable tech:  
- **Firebase** (App Check, Auth for login)
- **Provider** for state management
- **C++/CMake/Swift** for low-level extensions (minor)
- **Shared Preferences** for local, secure storage

---

## 📦 Features

### 🔐 Encryption & Decryption
- **Text:** AES and RSA encryption/decryption
- **Images:** Hide and extract messages securely
- **Offline:** All cryptographic processing is local

### 🖼️ Image Steganography
- Hide encrypted text in PNG/JPG images
- Extract hidden messages from steganographic images
- Multiple techniques: homoglyph, zero-width, whitespace

### 💬 Secure Chat
- Peer-to-peer local communication (LAN/Bluetooth)
- End-to-end encrypted messages
- Expiry timer for sensitive chats

### ⏳ Message Expiry & Session Management
- Self-destructing (time-bound) messages
- Secure session management & auto-logout

### 🎨 Theming & UX
- Multiple custom themes: AMOLED, Blue, Sepia, Gold & Purple, Pink & Blue-Gray, System, Light/Dark
- Theme persistence across sessions
- Modern, responsive UI

### ⚙️ Settings & Utilities
- Theme selector
- About and privacy information
- Session and security options

---

## 📸 Screenshots

<!-- Add your actual screenshots in assets/screenshots/ and update links -->
<p float="left">
  <img src="assets/screenshots/home.png" width="240" />
  <img src="assets/screenshots/encrypt.png" width="240" />
  <img src="assets/screenshots/chat.png" width="240" />
  <img src="assets/screenshots/settings.png" width="240" />
</p>

---

## 🧱 Project Structure

```
lib/
├── main.dart
├── constant/
│   └── colour_screen.dart
├── models/
│   └── message.dart
├── screens/
│   ├── auth_gate.dart
│   ├── chat_room_screen.dart
│   ├── decrypt_image_screen.dart
│   ├── decrypt_message_screen.dart
│   ├── encrypt_image_screen.dart
│   ├── encrypt_message_screen.dart
│   ├── file_sender_screen.dart
│   ├── firebase_options.dart
│   ├── home_screen.dart
│   ├── intro_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   └── ...
├── services/
│   ├── chat_room_service.dart
│   ├── chat_service.dart
│   ├── decryption_service.dart
│   ├── encryption_service.dart
│   ├── file_transfer_service.dart
│   ├── image_encryption_service.dart
│   ├── malware_check_service.dart
│   ├── message_encryption_service.dart
│   ├── recent_keys_service.dart
│   ├── user_service.dart
│   └── ...
├── theme/
│   └── theme_provider.dart
├── utils/
│   └── crypto_service.dart
├── widgets/
│   ├── gradient_background.dart
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── message_list.dart
│   ├── outlined_text.dart
│   ├── profile_keys_section.dart
│   ├── show_more_text.dart
│   └── ...
```

For a full, up-to-date structure, browse the [lib/ directory](https://github.com/Oso00Luffy/Graduation_Project/tree/main/lib).

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.0+)
- Dart (2.17+)
- Android Studio or VS Code
- Android device or emulator

### Installation

```bash
git clone https://github.com/Oso00Luffy/Graduation_Project.git
cd Graduation_Project
flutter pub get
flutter run
```

### Firebase Setup

- Place your `firebase_options.dart` in `lib/screens/` (see [FlutterFire docs](https://firebase.flutter.dev/docs/overview/))
- Enable App Check, Authentication, etc. in Firebase console

---

## 🧠 Educational Value

- Hands-on use of cryptographic algorithms
- Steganography techniques in mobile apps
- Peer-to-peer communication without internet
- Secure session management and lifecycle awareness

---

## ✅ To-Do

- [ ] UI polish and animations
- [ ] QR-code export for encrypted messages
- [ ] Optional backup via Firebase
- [ ] Biometric authentication for login
- [ ] Additional steganographic techniques

---

## 📝 License

This project is for academic/graduation purposes and is not licensed for commercial use.

---

## 🌐 Links

- 🎓 [Tafila Technical University](https://www.ttu.edu.jo/)
- 📁 [GitHub Repository](https://github.com/Oso00Luffy/Graduation_Project)
- 👤 [@Oso00Luffy](https://github.com/Oso00Luffy)

---

## 📈 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Oso00Luffy/Graduation_Project&type=Date)](https://star-history.com/#Oso00Luffy/Graduation_Project&Date)
