# FreshLoop - Smart Grocery & Food Waste Management System

[![Flutter](https://img.shields.io/badge/Flutter-v3.1.3+-02569B?style=for-the-badge)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.0+-0175C2?style=for-the-badge)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=for-the-badge)](https://firebase.google.com/)
[![Google ML Kit](https://img.shields.io/badge/Google%20ML%20Kit-OCR%20Vision-4285F4?style=for-the-badge)](https://developers.google.com/ml-kit)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

> **FreshLoop** is an intelligent, cross-platform Flutter application designed to combat household and retail food waste. By combining **OCR-driven automated expiry tracking**, **barcode scanning**, **automated background alerts**, an **AI Chef recipe assistant**, and a **community discount marketplace**, FreshLoop closes the loop on grocery freshness and sustainable consumption.

---

## Screenshots & Highlights

| Smart Dashboard | OCR Expiry Scanner | Community Marketplace | AI Chef Assistant |
|:---:|:---:|:---:|:---:|
| Inventory tracking & expiry status ring | Real-time text extraction for expiry dates | Discounted near-expiry community deals | Smart recipe generator based on your pantry |

---

## Key Features

### 1. Dual-Engine Scanner (Barcode + AI OCR)
- **Barcode & Label Scanning**: Quick identification of commercial packaged goods using `mobile_scanner`.
- **Google ML Kit OCR**: On-device Optical Character Recognition extracts and parses expiration/best-before dates (`dd/MM/yyyy`, `MM/yy`, etc.) automatically from camera feeds.
- **Expiry Parser Algorithm**: Robust date extraction pipeline with confidence scoring and regex normalization.

### 2. Smart Inventory & Expiry Alerts
- **Dynamic Status Categorization**: Automatic tagging as **Fresh**, **Expiring Soon** (within 3 days), or **Expired**.
- **Background Expiry Checker**: Periodic background workers scheduled via `workmanager` to check pantry inventory.
- **Local Push Notifications**: Automated notifications alerting users before items spoil (`flutter_local_notifications`).
- **Waste Analytics & Insights**: Interactive graphical breakdown of consumption vs. wastage using `fl_chart`.

### 3. AI Sous-Chef Chatbot
- **Pantry-Aware Suggestions**: Inspects expiring products in your pantry and recommends recipes to minimize waste.
- **Contextual Cooking Assistant**: Chat with an integrated chef persona for meal ideas, ingredient substitutions, and storage tips.

### 4. Circular Community Marketplace & Sell Desk
- **P2P Discount Market**: List excess or near-expiry food items at discounted rates for neighbors or local buyers.
- **Direct Sell / Liquidation**: Seamlessly move products from personal inventory to public listing with a single tap.
- **Multi-Category Browsing**: Filter by category (Dairy, Produce, Bakery, Meat, Pantry, etc.) with urgency tags.

### 5. Cloud Sync & Secure Authentication
- **Firebase Auth**: Secure Email/Password registration and login.
- **Cloud Firestore**: Real-time synchronization of pantry items, sales listings, and user preferences across devices.

---

## Architecture & Project Structure

FreshLoop follows clean architectural principles and feature-first modularity:

```text
lib/
├── background/            # Background tasks & WorkManager dispatchers
│   └── task_handler.dart
├── core/                  # App themes, design tokens, constants & palette
│   └── app_colors.dart
├── models/                # Typed data entities
│   └── product_model.dart # Product, Category, and Inventory models
├── screens/               # Feature screens & flows
│   ├── add/               # Manual and guided product addition
│   ├── home/              # Dashboard, status meters, and overview
│   ├── notifications/     # Notification activity feed
│   ├── products/          # Inventory management, filters, and list views
│   ├── profile/           # User account and preferences
│   ├── sales/             # Sell desk and liquidation flow
│   ├── scan/              # Barcode & ML Kit OCR scanning screens
│   ├── shop/              # Community marketplace & listings
│   ├── login_screen.dart  # User sign-in
│   └── signup_screen.dart # User registration
├── services/              # Core business services
│   ├── auth_service.dart          # Firebase authentication handling
│   ├── chef_service.dart          # AI recipe intelligence engine
│   ├── expiry_checker.dart        # Background expiry evaluation
│   ├── firestore_service.dart     # Cloud Firestore CRUD operations
│   └── notification_service.dart  # System & push notifications
├── widgets/               # Reusable atomic UI components
├── chat_screen.dart       # Interactive AI Chef chatbot interface
├── firebase_options.dart  # Firebase platform configuration
└── main.dart              # App bootstrap, auth routing, & theme initialization
```

---

## Tech Stack & Dependencies

| Layer | Technologies / Packages |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (Dart SDK `^3.1.3`) |
| **Backend & Cloud** | [Firebase Authentication](https://pub.dev/packages/firebase_auth), [Cloud Firestore](https://pub.dev/packages/cloud_firestore) |
| **Vision & ML** | [Google ML Kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition), [Mobile Scanner](https://pub.dev/packages/mobile_scanner), [Camera](https://pub.dev/packages/camera) |
| **Notifications & Jobs** | [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications), [WorkManager](https://pub.dev/packages/workmanager) |
| **Data Visualization** | [FL Chart](https://pub.dev/packages/fl_chart) |
| **State & Utilities** | [Provider](https://pub.dev/packages/provider), [Intl](https://pub.dev/packages/intl), [Path Provider](https://pub.dev/packages/path_provider) |

---

## Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.1.3` or later)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extension
- An active [Firebase Project](https://console.firebase.google.com/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/freshloop.git
   cd freshloop
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Run the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to link your Firebase project:
     ```bash
     flutterfire configure
     ```
   - Verify that your `lib/firebase_options.dart` and native config files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) are properly populated.

4. **Run the Application:**
   ```bash
   # Connect an Android / iOS device or emulator
   flutter run
   ```

---

## Hardware & Permission Requirements

To take full advantage of FreshLoop's vision and background engines, the following device capabilities are utilized:
- **Camera Access**: Required for barcode detection and OCR expiration date capture.
- **Notifications**: Required for timely expiry alerts and reminders.
- **Background Processing**: Used by WorkManager to evaluate inventory when the application is closed.

---

## Roadmap & Future Enhancements

- [ ] **Smart Recipe Bookmarking**: Save and export AI Chef recipes into customized meal prep plans.
- [ ] **In-App Payments**: Integrated payment gateways (Stripe/Razorpay) for frictionless community marketplace purchases.
- [ ] **Smart Home / Refrigerator API**: Sync directly with smart appliances and grocery delivery receipts.
- [ ] **Barcode Nutritional Breakdown**: Instant calorie, allergen, and nutrient breakdown alongside shelf-life.

---

## Contributing

Contributions make the open-source community an incredible place to learn, inspire, and create. Any contributions are appreciated.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<p align="center">
  Developed to eliminate food waste and promote sustainable living.
</p>
