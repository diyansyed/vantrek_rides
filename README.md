# Vantrek Rides


Vantrek Rides is a Flutter-based mobile application designed to connect users with van and shuttle drivers for their daily commute, with a focus on transportation for educational institutions. The platform facilitates searching for drivers, managing subscriptions, live vehicle tracking, and in-app communication to provide a streamlined and reliable transportation solution.

### Core Features

**For Users:**
- **Authentication:** Secure sign-up and sign-in with email/password.
- **Institution & Driver Discovery:** Search for educational institutions and view registered drivers along with their routes and ratings.
- **Live Tracking:** Track the real-time location of subscribed drivers on an interactive map.
- **Subscription Management:** Send ride requests to drivers and manage active subscriptions.
- **Direct Communication:** In-app chat functionality to communicate directly with drivers.
- **Ratings & Reviews:** Rate drivers and provide feedback to help maintain service quality.

**For Drivers:**
- **Driver Registration:** An application process to become a verified driver on the platform.
- **Driver Dashboard:** A central dashboard to manage online status, view subscriber counts, and see pending ride requests.
- **Status & Location Sharing:** Toggle online/offline status to start or stop sharing real-time location with subscribers.
- **Route Management:** Register with multiple institutions and define specific service routes, including pickup and drop-off times.
- **Request Management:** View, accept, and reject ride requests from users.
- **Subscriber Management:** View and manage the list of subscribed users.

### Technology Stack

- **Framework:** Flutter
- **State Management:** Flutter Riverpod
- **Backend:** Firebase (Authentication, Cloud Firestore, Realtime Database)
- **Maps & Geolocation:**
  - Google Maps Flutter
  - Google Places API
  - Geolocator & Geocoding
- **Architecture:** The project is organized following a clean, feature-driven structure, separating UI, state management, and services.

### Project Structure
The `lib` directory is organized as follows:
- `controllers/`: Contains Riverpod StateNotifiers for managing complex state and business logic.
- `models/`: Defines all data structures used within the app (e.g., `AppUser`, `DriverProfile`, `RideRequest`).
- `providers/`: Houses simple Riverpod providers for accessing services and state across the app.
- `repositories/`: Abstracts data sources, primarily handling communication with Firebase services.
- `screens/`: Contains the UI for all the different pages of the application, separated for users and drivers.
- `services/`: Provides specific functionalities such as chat, location tracking, and API interactions.
- `widgets/`: Includes reusable UI components like custom dialogs and input fields.

### Getting Started

To get a local copy up and running, follow these simple steps.

**Prerequisites:**
- Flutter SDK installed.
- A configured IDE like Android Studio or VS Code.
- A Firebase project.

**Installation:**
1.  **Clone the repository:**
    ```sh
    git clone https://github.com/diyansyed/vantrek_rides.git
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd vantrek_rides
    ```
3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Configure Firebase:**
    - Follow the official [FlutterFire CLI documentation](https://firebase.google.com/docs/flutter/setup) to connect your Firebase project. This will generate a `lib/firebase_options.dart` file.
    - Place your `google-services.json` file in `android/app/`.

5.  **Add API Keys:**
    - Add your Google Maps API key to the `android/app/src/main/AndroidManifest.xml` file.
    - Ensure the **Google Places API** is enabled in your Google Cloud Platform project.

6.  **Run the application:**
    ```sh
    flutter run
