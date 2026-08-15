# 🛡️ ZShield — Cross-Platform Glassmorphic VPN Client & Tunneling Engine

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Core](https://img.shields.io/badge/Core-Xray--core_%2F_sing--box-black?style=flat-square)](https://github.com/XTLS/Xray-core)
[![Wintun](https://img.shields.io/badge/Driver-Wintun_TUN-orange?style=flat-square)](https://www.wintun.net/)
[![Status: Paused](https://img.shields.io/badge/Status-Paused%20%2F%20Archived-lightgrey?style=flat-square)](#-project-status)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

**A high-performance cross-platform VPN client and network proxying station featuring modern Glassmorphism UI, Riverpod 2 reactive state management, Wintun adapter tunneling, and Xray / Sing-box VLESS (Reality/Vision) protocol support.**

[Project Status](#-project-status) • [Features](#-key-features) • [Architecture](#-architecture) • [Protocols](#-supported-protocols--routing) • [Quick Start](#-quick-start) • [License](#-license)

</div>

---

## ⏸️ Project Status

> [!NOTE]
> **DEVELOPMENT STATUS: PAUSED / ARCHIVED**
> Active development on this project is currently discontinued. The codebase is preserved in a working, completed state as an architectural reference and portfolio showcase for complex Flutter desktop/mobile tunneling clients, Riverpod 2.x reactive state machines, and embedded Xray-core / Sing-box process management.

---

## 📖 Overview

**ZShield** (V-Shield) is an open-source VPN desktop and mobile client designed with a strong focus on anti-censorship protocols, speed, and cutting-edge visual aesthetics. Built on **Flutter (Dart)** with a custom **Glassmorphic design system**, it encapsulates low-level proxy cores (**Xray-core** and **sing-box**) alongside the high-performance **Wintun** driver on Windows.

It provides system-wide virtual TUN adapters, application-specific split tunneling, sub-second latency ping measurement, dynamic subscription management, and real-time traffic throughput telemetry.

---

## ✨ Key Features

- ⚡ **Next-Gen Anti-Censorship Protocols**
  - Full support for VLESS (XTLS Reality / Vision), VMess, Trojan, and Shadowsocks protocols bypassing DPI (Deep Packet Inspection) filters.
- 💎 **Deep Glassmorphism Design System**
  - High-fidelity frosted glass panels (`GlassPanel`), smooth neon status glows (`StatusGlow`), fluid micro-animations, and theme persistence.
- 🖧 **System-Wide Wintun TUN Adapter Integration**
  - Automatic creation and routing of high-throughput virtual network adapters (`172.19.0.1/30`) on Windows with zero packet loss.
- 🔀 **Flexible Smart Routing & Split Tunneling**
  - Rule-based traffic dispatching: direct domestic traffic routing, private RFC 1918 subnets bypassing, and proxying of international destinations.
- 📊 **Real-Time Traffic Telemetry & Latency Diagnostics**
  - Integrated high-frequency TCP/ICMP ping service (`PingService`) with live upload/download bitrate monitors.
- 🔗 **Universal Subscription & Node Importer**
  - Seamlessly imports Base64, JSON, and standard URI configuration links (`vless://`, `vmess://`, `trojan://`).

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                   ZShield Flutter / Dart UI                      │
│        (Dashboard + GlassPanel + GoRouter + StatusGlow)          │
└─────────────────────────────────┬────────────────────────────────┘
                                  │ Riverpod 2.x State Notifiers
┌─────────────────────────────────▼────────────────────────────────┐
│                    Application Service Layer                     │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────────┐  │
│  │ XrayService Controller │  │ PingService Latency Monitor    │  │
│  └────────────────────────┘  └────────────────────────────────┘  │
│  ┌────────────────────────┐  ┌────────────────────────────────┐  │
│  │ Node Subscription Store│  │ Routing Rule Config Generator  │  │
│  └────────────────────────┘  └────────────────────────────────┘  │
└─────────────────────────────────┬────────────────────────────────┘
                                  │ IPC Subprocess / Win32 Process
┌─────────────────────────────────▼────────────────────────────────┐
│             Embedded Tunneling Core (sing-box / Xray)            │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ VLESS (Reality/Vision) • VMess • Trojan • Shadowsocks      │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────┬────────────────────────────────┘
                                  │ Virtual Network Device
┌─────────────────────────────────▼────────────────────────────────┐
│        Wintun TUN Adapter (Windows) / VpnService (Android/iOS)   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📡 Supported Protocols & Routing

| Protocol | Transport / Security | Supported Features |
|---|---|---|
| **VLESS** | TCP + XTLS Reality / Vision | Anti-DPI fingerprinting, 0-RTT handshake |
| **VMess** | WebSocket, gRPC + TLS | Universal CDN proxying & multiplexing |
| **Trojan** | TLS / HTTPS Encapsulation | Standard web traffic camouflage |
| **Shadowsocks** | AEAD Ciphers (2022) | High-speed lightweight obfuscation |
| **TUN Routing** | Wintun Adapter Layer 3 | System-wide transparent proxying |

---

## 🛠 Tech Stack

| Domain | Technology | Description |
|---|---|---|
| **Framework** | Flutter 3.x, Dart 3.0+ | Cross-platform desktop (Windows) and mobile GUI |
| **State Management** | Riverpod 2.x (`Notifier`) | Type-safe reactive dependency injection and state |
| **Routing & Navigation**| GoRouter | Declarative route trees with transition animations |
| **Tunneling Backend** | `Xray-core` / `sing-box` | High-throughput Go network proxy engine |
| **Windows TUN Driver** | `Wintun.dll` | Ultra-low latency Windows kernel network driver |

---

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK**: `v3.10` or higher
- **Dart SDK**: `v3.0` or higher
- **Windows / Android / iOS Build Tools**

### 1. Clone the Repository
```bash
git clone https://github.com/T58574/zshield.git
cd zshield
```

### 2. Fetch Dependencies
```bash
flutter pub get
```

### 3. Run in Development Mode
```bash
flutter run -d windows
```

### 4. Build Standalone Release Executable
```bash
flutter build windows --release
```
Release executable and assets will be output to: `build/windows/x64/runner/Release/`.

---

## 📁 Project Structure

```
zshield/
├── assets/                  # Embedded tunneling binaries & icons
│   └── core/                # sing-box.exe, wintun.dll, xray.exe
├── lib/
│   ├── core/                # System services (XrayService, PingService, Router, Theme)
│   ├── providers/           # Riverpod state notifiers (VPN status, node list, settings)
│   ├── screens/             # UI Views (Dashboard, Servers, Routing, Settings)
│   ├── widgets/             # Reusable UI components (GlassPanel, StatusGlow, MetricCards)
│   └── main.dart            # Flutter application entry point
├── pubspec.yaml             # Dart package dependencies & asset manifests
├── analysis_options.yaml    # Strict Dart linter rules
├── LICENSE                  # MIT License
└── README.md                # Project documentation
```

---

## 📜 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
