<div align="center">
  <h1>Larry's Wordle 🐈</h1>
  
  <p><b>A cross-platform daily word puzzle game powered by Flutter and Serverless AWS</b></p>

  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Frontend-Flutter_&_Dart-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/State-Riverpod-0055FF?style=flat-square" alt="Riverpod"></a>
  <a href="https://aws.amazon.com/lambda/"><img src="https://img.shields.io/badge/Backend-AWS_Lambda-FF9900?style=flat-square&logo=awslambda&logoColor=white" alt="AWS Lambda"></a>
  <a href="https://aws.amazon.com/dynamodb/"><img src="https://img.shields.io/badge/Database-DynamoDB-4053D6?style=flat-square&logo=amazondynamodb&logoColor=white" alt="DynamoDB"></a>
</div>

<br>

## 🎮 About the Game
**Larry's Wordle** is a fully-featured clone of the popular game Wordle, challenging players to guess a secret five-letter word within six attempts. 

Designed for both mobile and web, the application features a highly responsive UI, real-time daily word synchronization via AWS EventBridge, and a persistent scoring system. Whether you're playing on the web or via the mobile app, the daily challenge is always perfectly synced!

### 📥 Download & Play
* 🚀 **[Download the Android APK Here](https://drive.google.com/uc?export=download&id=1dq8AhOxZu4l5by8WaAXgb9OZuVb4mSd_)**
* 📱 *Coming soon to the Google Play Store!*

---

## ✨ Features

### Game Mechanics
* **Classic Gameplay:** Guess the five-letter word with color-coded feedback (🟩 Correct, 🟨 Wrong position, ⬛ Not in word).
* **Scoring System:** Tracks your daily attempts and overall guessing accuracy.
* **Local Notifications:** Daily reminders and challenge alerts pushed directly to your device to keep your streak alive!

### System Architecture
* **Serverless Backend (AWS):** The daily word is securely fetched from an **AWS Lambda** function, triggered automatically every 24 hours via **Amazon EventBridge**, and routed through an **API Gateway**.
* **Cloud Storage:** Valid word lists and game states are managed in **Amazon DynamoDB**.
* **Reactive UI:** State management is handled completely by **Riverpod**, ensuring smooth animations and an efficient, reactive interface.
* **Cross-Platform & Adaptive:** Beautifully responsive design that supports seamless switching between light and **Dark Mode**.

---

## 🚀 Upcoming Roadmap
- [ ] **User Authentication:** Secure sign-up and login pipelines using AWS Cognito.
- [ ] **Global Leaderboard:** Track and compare the top players worldwide based on average score and streak.
- [ ] **Stripe Integration:** In-app purchases and donation support to keep the servers running.

---

## 🛠️ Local Development

Want to build or modify the project locally? Ensure you have the Flutter SDK installed and follow these steps:

**1. Clone the repository:**
```bash
git clone [https://github.com/AjaxxIsHere/Larry-s-Wordle-A-wordle-inspired-mobile-game.git](https://github.com/AjaxxIsHere/Larry-s-Wordle-A-wordle-inspired-mobile-game.git)
cd Larry-s-Wordle-A-wordle-inspired-mobile-game
