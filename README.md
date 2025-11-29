# 🐾 AI Dog Translator & Walk
<a id="english"></a>

<div align="center">

![Banner](Docs/banner.png)

[![iOS 16.0+](https://img.shields.io/badge/iOS-16.0%2B-000000.svg?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138.svg?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-007AFF.svg?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Xcode 15](https://img.shields.io/badge/Xcode-15-1575F9.svg?style=for-the-badge&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)

[![Live Activities](https://img.shields.io/badge/Live%20Activities-Dynamic%20Island-7D55C7.svg?style=for-the-badge&logo=activity&logoColor=white)](https://developer.apple.com/documentation/activitykit)
[![MapKit](https://img.shields.io/badge/MapKit-Location-34C759.svg?style=for-the-badge&logo=apple-maps&logoColor=white)](https://developer.apple.com/documentation/mapkit)
[![AVFoundation](https://img.shields.io/badge/AVFoundation-Audio-FF2D55.svg?style=for-the-badge&logo=apple-music&logoColor=white)](https://developer.apple.com/documentation/avfoundation)
[![Architecture](https://img.shields.io/badge/Arch-Clean%20MVVM-FF9500.svg?style=for-the-badge)](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<br>

**[Читать на русском](#russian)**

</div>

---

## 💡 Project Overview

**AI Dog Translator & Walk** is a cutting-edge iOS application that redefines pet interaction. By fusing **Generative AI**, **Signal Processing**, and **Real-time Geolocation**, it offers a comprehensive suite of tools for the modern dog owner.

Built with a relentless focus on **Clean Architecture** and **Scalability**, this project serves as a benchmark for modern iOS development practices, utilizing the full power of the Apple ecosystem.

---

## 📱 Application Showcase

<div align="center">

| **Sounds** | **AI Translator** | **Walk Tracker** |
|:---:|:---:|:---:|
| <img src="Docs/screenshots/sounds.png" width="240" alt="Sounds" style="border-radius: 16px; box-shadow: 0 8px 16px rgba(0,0,0,0.15);" /> | <img src="Docs/screenshots/translator.png" width="240" alt="Translator" style="border-radius: 16px; box-shadow: 0 8px 16px rgba(0,0,0,0.15);" /> | <img src="Docs/screenshots/walk.png" width="240" alt="Walk Tracker" style="border-radius: 16px; box-shadow: 0 8px 16px rgba(0,0,0,0.15);" /> |

| **Whistle Generator** | **Memories** | |
|:---:|:---:|:---:|
| <img src="Docs/screenshots/generator.png" width="240" alt="Generator" style="border-radius: 16px; box-shadow: 0 8px 16px rgba(0,0,0,0.15);" /> | <img src="Docs/screenshots/memories.png" width="240" alt="Memories" style="border-radius: 16px; box-shadow: 0 8px 16px rgba(0,0,0,0.15);" /> | |

</div>

---

## 🛠 Technical Architecture & Stack

The application is architected using **SwiftUI** and adheres to a strict **MVVM (Model-View-ViewModel)** pattern with a **Service-Oriented** layer. This ensures separation of concerns, testability, and ease of maintenance.

### 🏗 Core Technologies

*   **SwiftUI**: Declarative UI framework for building fluid, responsive interfaces.
*   **Combine**: Reactive framework for handling asynchronous events and data streams.
*   **Concurrency (Async/Await)**: Modern structured concurrency for efficient background tasks.
*   **Core Data / UserDefaults**: Robust data persistence strategies.

### 🧩 Key Frameworks & Modules

| Feature | Frameworks / Tools | Technical Highlight |
| :--- | :--- | :--- |
| **AI Engine** | `URLSession`, `Codable` | Integration with **Anthropic Claude 3 API** for context-aware, humorous translation generation. |
| **Geolocation** | `CoreLocation`, `MapKit` | High-precision GPS tracking, background location updates, and custom map overlays (`MKPolyline`). |
| **Live Activities** | `ActivityKit`, `WidgetKit` | **Dynamic Island** support for iPhone 14 Pro+ and Lock Screen widgets for real-time walk stats. |
| **Audio Processing** | `AVFoundation` | Custom `AVTonePlayerUnit` for generating pure sine waves (10kHz-20kHz) and real-time spectral analysis. |
| **Monetization** | `StoreKit 2` | Modern IAP implementation with `ProductView`, subscription groups, and entitlement verification. |
| **Visuals** | `SpriteKit` | High-performance 2D particle systems (floating bones) integrated seamlessly into SwiftUI views. |

---

## 📂 Project Structure

Reflecting a modular and scalable folder structure:

```text
Dog Translator/
├── App/
│   ├── DogTranslatorApp.swift    # App Entry Point & Dependency Injection
│   └── MainTabView.swift         # Root Navigation Controller
├── Core/
│   ├── Services/                 # Singleton Services (Audio, Location, API)
│   ├── Models/                   # Data Models & Structs
│   ├── Extensions/               # Swift Extensions (Color, View, etc.)
│   └── UI/                       # Reusable UI Components (Buttons, Backgrounds)
├── Features/
│   ├── Translator/               # MVVM for AI Translation
│   ├── Walk/                     # MVVM for Map & Tracking
│   ├── Sounds/                   # MVVM for Audio Grid
│   ├── Generator/                # MVVM for Frequency Oscillator
│   ├── Memories/                 # MVVM for Walk History
│   └── Paywall/                  # StoreKit 2 Presentation
├── DogWalkWidget/                # Widget Extension Target
│   ├── DogWalkWidgetLiveActivity.swift
│   └── DogWalkWidgetBundle.swift
└── Resources/
    └── Assets.xcassets           # App Icon, Colors, Image Sets
```

---

<br>
<br>
<br>

# 🐾 AI Переводчик для Собак & Прогулки
<a id="russian"></a>

<div align="center">

**[Read in English](#english)**

</div>

---

## 💡 Обзор Проекта

**AI Dog Translator & Walk** — это флагманское iOS приложение, объединяющее развлечение и утилиты для владельцев собак. Проект демонстрирует использование передовых технологий: **Generative AI**, **Signal Processing** и **Real-time Geolocation**.

Разработано с применением принципов **Clean Architecture**, что делает кодовую базу масштабируемой, тестируемой и легкой в поддержке.

---

## 🛠 Технический Стек

Приложение построено на **SwiftUI** с использованием паттерна **MVVM** и сервисного слоя.

### 🧩 Ключевые Модули

| Функция | Фреймворки | Описание реализации |
| :--- | :--- | :--- |
| **AI Ядро** | `URLSession`, `Codable` | Интеграция с **Claude 3 API** для генерации "переводов" на основе контекста. |
| **Геолокация** | `CoreLocation`, `MapKit` | Точный GPS-трекинг, фоновое отслеживание, отрисовка маршрутов на карте. |
| **Live Activities** | `ActivityKit`, `WidgetKit` | Поддержка **Dynamic Island** и виджетов экрана блокировки для отображения статистики в реальном времени. |
| **Аудио** | `AVFoundation` | Генерация чистого синусоидального сигнала (ультразвук) и анализ аудио-спектра. |
| **Покупки** | `StoreKit 2` | Современная реализация подписок, восстановление покупок, динамический Paywall. |
| **Графика** | `SpriteKit` | Интеграция систем частиц (SpriteKit) в интерфейс SwiftUI для живых фонов. |

---

## 📂 Структура Проекта

```text
Dog Translator/
├── App/
│   ├── DogTranslatorApp.swift    # Точка входа
│   └── MainTabView.swift         # Навигация
├── Core/                         # Ядро приложения
│   ├── Services/                 # Сервисы (Аудио, Локация, API)
│   ├── Models/                   # Модели данных
│   └── UI/                       # Переиспользуемые компоненты
├── Features/                     # Функциональные модули (MVVM)
│   ├── Translator/               # Переводчик
│   ├── Walk/                     # Прогулки и Карты
│   ├── Sounds/                   # Звуки
│   ├── Generator/                # Генератор частот
│   └── Paywall/                  # Экран покупки
└── DogWalkWidget/                # Виджеты
```
