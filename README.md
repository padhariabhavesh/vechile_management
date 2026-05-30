# Fleet Track

A premium, multi-tenant, and feature-rich vehicle fleet management platform built with Flutter, Riverpod, and MongoDB Atlas. 

Track your vehicles, record refuelings, monitor fuel efficiency, manage maintenance alerts, and view elegant analytics dashboards in one application.

---

## Key Features

- **Multi-Tenant Authentication**: Relational user registration and secure login synced directly with MongoDB Atlas cluster databases.
- **Type-Segregated Fleet Registry**: Organize vehicles separately as `two_wheelers` and `four_wheelers` for clean schema architecture.
- **Petrol & Fuel Tracking**:
  - Full-tank vs. partial-tank economy tracking.
  - Precision mileage calculations using mathematical safeguards.
- **Predictive Maintenance reminders**:
  - Real-time remaining distance indicators before next required service.
  - Ok, Warning, and Overdue severity alerts for general checkups, brake pads, and oil changes.
- **Dynamic Analytics Dashboard**:
  - Fuel economy chronological charts.
  - Multi-month expense distributions.
  - Comparative fleet cost summaries.
- **Robust Offline-First Caching**: Thread-safe caching layer that automatically falls back to in-memory mocks when offline, synchronizing seamlessly with the cloud database once online.

---

## Tech Stack

* **Framework**: Flutter (Dart SDK `>=3.0.0 <4.0.0`)
* **State Management**: Flutter Riverpod (`v2`)
* **Database (Cloud)**: MongoDB Atlas (Direct TCP connection via `mongo_dart`)
* **Configuration**: Dotenv parameter injection (`flutter_dotenv`)

---

## Configuration Setup

Before running the application, ensure you create a `.env` file in the root directory:

```env
mongodb=mongodb+srv://<username>:<password>@<cluster-url>/?appName=Cluster
```

Include `.env` in your assets section in `pubspec.yaml` to package it inside the application bundle.

---

## Building the Release APK

To compile and package the production release APK file for Android devices, execute the following command in the project root:

```bash
flutter build apk
```

The resulting package will be compiled at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Static Quality Checks

To verify that the codebase is completely free of compile warnings and static analysis errors, run:

```bash
flutter analyze
```
