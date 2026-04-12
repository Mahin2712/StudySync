# StudySync 📚

StudySync is a focused, community-driven study platform built with Flutter and Supabase. It provides a virtual space for students to engage in deep work sessions, track their progress, and stay motivated through a collaborative environment.

## ✨ Features

-   **Focused Study Rooms**: Join or create study rooms tailored to specific subjects like Physics, Mathematics, and more.
-   **Deep Work Sessions**: Integrated session timer with mandatory check-ins to ensure you stay focused.
-   **Live Collaboration**: See who else is studying in real-time and join a community of dedicated learners.
-   **Leaderboards**: Stay motivated by competing for the top spots on daily, weekly, and monthly leaderboards.
-   **Personal Stats Dashboard**: Track your study habits with detailed insights into your time spent on different subjects.
-   **Profile Customization**: Set up your student profile with your school/institution details.

## 🛠️ Technology Stack

-   **Frontend**: [Flutter](https://flutter.dev/) (Cross-platform UI toolkit)
-   **Backend**: [Supabase](https://supabase.com/) (Open-source Firebase alternative)
    -   **Authentication**: Secure email/password login.
    -   **Database**: PostgreSQL for storing profiles, rooms, and study sessions.
    -   **Realtime**: Live updates for room members and active study sessions.

## 🚀 Getting Started

### Prerequisites

-   Flutter SDK installed on your machine.
-   A Supabase project set up.

### Setup Instructions

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-repo/studysync.git
    cd studysync
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Supabase Configuration**:
    The project currently uses a pre-configured Supabase instance. If you want to use your own:
    -   Update the `url` and `anonKey` in `lib/main.dart` with your Supabase project credentials.
    -   Set up the required tables (`profiles`, `rooms`, `room_members`, `study_sessions`, `subjects`) and views for leaderboards in your Supabase database.

4.  **Run the app**:
    ```bash
    flutter run
    ```

## 📂 Project Structure

-   `lib/models/`: Data models for profiles, rooms, sessions, and subjects.
-   `lib/screens/`: UI screens for login, home, study rooms, leaderboards, and stats.
-   `lib/services/`: Service classes for interacting with Supabase.
-   `lib/main.dart`: Entry point of the application and authentication router.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue for any bugs or feature requests.

## 📄 License

This project is licensed under the MIT License.
