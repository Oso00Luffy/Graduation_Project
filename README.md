
# 🔐 SCC_App — Secure Communication & Cryptography App

A cross-platform Flutter application focused on secure communication through modern cryptographic techniques and steganography. Designed as a graduation project in Cybersecurity at Tafila Technical University.

> 🧪 Graduation Project by:
> - Osama Wesam Jaradat [@Oso00Luffy](https://github.com/Oso00Luffy)
> - Moath Amjad Hdairis  
> Supervised by: Dr. Eman

---

## Table of Contents
- [Project Objectives](#-project-objectives)
- [Tech Stack](#-tech-stack)
- [Features](#-features)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Screenshots](#-screenshots)
- [To-Do](#-to-do)
- [Educational Value](#-educational-value)
- [License](#-license)
- [Links](#-links)
- [Star History](#star-history)

---

## 🎯 Project Objectives

- Enable **secure encryption/decryption** of messages and images
- Support **steganography techniques** for hiding messages in plain sight
- Create a **peer-to-peer secure chat** system
- Allow users to set **expiry dates for encrypted content**
- Showcase a **modular, privacy-focused** mobile app for cybersecurity use cases

---

## 🛠 Tech Stack

| Layer        | Technology                          |
|--------------|--------------------------------------|
| Language     | Dart                                 |
| Framework    | Flutter                              |
| Encryption   | AES, RSA (custom implementations)    |
| Steganography| Zero-width encoding, homoglyphs, whitespaces |
| Chat         | Local LAN or Bluetooth (P2P)         |
| Platform     | Android (Flutter)                    |

---

## 📦 Features

### 🔐 Encryption & Decryption
- Encrypt text with AES or RSA
- Decrypt content using private keys
- Offline & secure processing

### 🖼️ Image Steganography
- Hide encrypted text inside images
- Extract and decode hidden messages
- Techniques: Homoglyph substitution, zero-width, spacing

### 💬 Secure Chat
- Peer-to-peer local communication
- End-to-end encrypted messages
- Expiry timer for sensitive chats

### ⏳ Message Expiry & Session
- Time-bound messages (self-destruct after expiry)
- Secure session data stored locally
- Session handling for user privacy

---

## 🧱 Project Structure

```
lib/
├── main.dart
├── routes.dart
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
│   └── ... [see all: https://github.com/Oso00Luffy/Graduation_Project/tree/main/lib/screens]
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
│   └── ... [see all: https://github.com/Oso00Luffy/Graduation_Project/tree/main/lib/services]
├── theme/
│   └── theme_provider.dart
├── utils/
│   └── crypto_service.dart
├── widgets/
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── message_list.dart
│   ├── outlined_text.dart
│   ├── profile_keys_section.dart
│   ├── show_more_text.dart
│   └── ... [see all: https://github.com/Oso00Luffy/Graduation_Project/tree/main/lib/widgets]
```

> For the full and most up-to-date structure, browse the [lib/ directory on GitHub](https://github.com/Oso00Luffy/Graduation_Project/tree/main/lib).

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

---

## 📸 Screenshots

> _(Add screenshots from your app in `/assets/screenshots/` and display them below)_

```
![Home Screen](assets/screenshots/home.png)
![Encryption](assets/screenshots/encryption.png)
![Chat](assets/screenshots/chat.png)
```

---

## ✅ To-Do

- [ ] UI polish and animations
- [ ] Add QR-code export for encrypted messages
- [ ] Add backup option using Firebase (optional)
- [ ] Add biometric authentication for login
- [ ] Support for more steganographic techniques

---

## 🧠 Educational Value

This project showcases:
- Hands-on application of cryptographic algorithms
- Practical implementation of steganography in mobile apps
- Peer-to-peer communication without internet dependency
- Session security and lifecycle awareness in mobile development

---

## 📝 License

This project is part of an academic graduation project and is not licensed for commercial use.

---

## 🌐 Links

- 🎓 University: Tafila Technical University
- 📜 Supervisor: Dr. Eman
- 📁 Repository: [https://github.com/Oso00Luffy/Graduation_Project](https://github.com/Oso00Luffy/Graduation_Project)

---
## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Oso00Luffy/Graduation_Project&type=Date)](https://star-history.com/#Oso00Luffy/Graduation_Project&Date)
