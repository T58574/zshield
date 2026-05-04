# ZShield (V-Shield) 🛡️

**ZShield** is a premium, open-source VPN client built with Flutter, designed with a focus on privacy, speed, and cutting-edge aesthetics. It features a modern **Glassmorphism** UI and utilizes the powerful **Xray-core** for reliable tunneling.

![License](https://img.shields.io/github/license/2dust/v2rayN)
![Flutter](https://img.shields.io/badge/Flutter-v3.11+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android%20%7C%20iOS%20%7C%20Linux-lightgrey)

---

## ✨ Key Features

*   **⚡ High Performance:** Powered by `Xray-core` supporting VLESS (Reality/Vision) protocols.
*   **💎 Premium UI:** Stunning Glassmorphism design system inspired by modern OS aesthetics.
*   **📡 Smart Routing:** Support for system-wide tunneling or application-specific proxying.
*   **📊 Real-time Analytics:** Monitor your connection speed, latency (Ping), and traffic consumption.
*   **🔗 Subscription Support:** Import and manage server lists from external providers easily.
*   **🛡️ Privacy First:** No logging, no tracking, pure open-source security.

---

## 🛠️ Technology Stack

*   **Frontend:** [Flutter](https://flutter.dev) (Dart)
*   **State Management:** [Riverpod 2.x](https://riverpod.dev)
*   **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
*   **Core Logic:** [Xray-core](https://github.com/XTLS/Xray-core) integration
*   **Persistence:** Shared Preferences & local secure storage

---

## 📸 Interface Preview

The application uses a custom-built **Glassmorphism** design system:
*   High-fidelity blur effects
*   Interactive micro-animations
*   Dynamic status indicators
*   Sleek Dark Mode by default

---

## 🏗️ Architecture

ZShield follows a modular architecture:
*   `/lib/providers`: Business logic and state management.
*   `/lib/screens`: High-level UI pages (Dashboard, Servers, Routing).
*   `/lib/widgets`: Reusable UI components (GlassPanel, StatusGlow).
*   `/lib/core`: Core services (XrayService, PingService, Router).

---

## 🤝 Contributing

Contributions are welcome! Whether it's reporting a bug, suggesting a feature, or submitting a pull request, we appreciate all help.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

*Developed with ❤️ by the ZShield Team.*
