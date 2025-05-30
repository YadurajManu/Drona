<!-- 
    Hey there! 👋
    Consider adding your app's logo or a captivating banner image here. 
    For example:
    <p align="center">
      <img src="link_to_your_logo.png" alt="Drona App Logo" width="200"/>
    </p>
-->

# Drona - Your Personal AI Learning Companion 🚀

Welcome to Drona, a powerful and intuitive iOS application designed to revolutionize your learning experience! Drona acts as your personal AI-powered tutor, helping you understand complex topics, memorize facts effectively, and stay motivated on your educational journey.

## ✨ Key Features

Drona is packed with features to make learning smarter, not harder:

*   🧠 **Personalized Learning Experience:**
    *   Create a user profile with your educational background, interests, and learning goals.
    *   Drona adapts to your preferred topics and learning style.

*   💬 **AI-Powered Doubt Resolution:**
    *   Engage in insightful conversations with an advanced AI (powered by Gemini).
    *   Get clear explanations for academic questions, personal queries, and more.
    *   Conversations are categorized for easy access and review.

*   📚 **Effective Memorization with Flashcards:**
    *   Create custom flashcards or generate them automatically from your conversations.
    *   Utilize the proven SM-2 spaced repetition algorithm to boost memory retention.
    *   Organize flashcards by category, star important ones, and customize their appearance.
    *   Track your confidence levels and review history for each card.

*   🧑‍🏫 **Guided Study with AI Coaches:**
    *   Choose from a variety of AI study coaches, each with unique specializations (e.g., Math & Science, Language Arts), personalities (e.g., Motivational, Analytical), and avatars.
    *   Receive personalized study plans tailored to your subjects and goals.
    *   Gain valuable learning insights and track your study streaks.
    *   Build a relationship with your coach as they learn more about your progress.

*   📊 **Progress Tracking & Insights:**
    *   Monitor your learning activities, including flashcard mastery and study habits.
    *   Receive insights from your study coach to identify strengths and areas for improvement.

*   📤 **Data Management:**
    *   Your learning data is stored locally.
    *   Export and import conversation data.

## 🛠️ Technology Stack

*   **iOS Application:** Developed natively for iOS.
*   **SwiftUI:** Built with Apple's modern declarative UI framework for creating beautiful and responsive user interfaces.
*   **Gemini API:** Leverages Google's advanced AI models for intelligent conversation, flashcard generation, and study coach interactions.
*   **UserDefaults:** Utilized for local data persistence of user profiles, flashcards, conversations, and settings through JSON encoding.

## 🚀 Getting Started

To build and run Drona on your local machine:

1.  **Prerequisites:**
    *   macOS with Xcode installed (latest version recommended).
    *   An Apple Developer account might be required for certain features or deploying to a physical device.

2.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/drona-repo.git # Replace with the actual repo URL
    cd drona-repo
    ```

3.  **Open in Xcode:**
    *   Navigate to the `Personal.xcodeproj` file and open it with Xcode.

4.  **Configure API Keys (if necessary):**
    *   The application uses the Gemini API. You may need to obtain an API key from Google AI Studio.
    *   Locate the `GeminiService.swift` file (likely in `Personal/Services/`) and insert your API key where indicated.
    ```swift
    // Inside GeminiService.swift
    // private let apiKey = "YOUR_API_KEY" // Replace with your actual key
    ```
    *   *(Note: It's best practice to not hardcode API keys. Consider using environment variables or a configuration file for this in a production setting.)*

5.  **Build and Run:**
    *   Select your target device (simulator or physical device) in Xcode.
    *   Click the "Run" button (or press `Cmd+R`).

This should launch the Drona app on your selected simulator or device.

## 🙌 How to Contribute

We welcome contributions to Drona! Whether it's fixing bugs, adding new features, or improving documentation, your help is appreciated.

To contribute:

1.  **Fork the Repository:** Create your own copy of the project.
2.  **Create a Branch:** Make a new branch for your changes (`git checkout -b feature/your-amazing-feature`).
3.  **Make Your Changes:** Implement your feature or bug fix.
    *   Ensure your code follows the existing style and conventions.
    *   Write clear and concise commit messages.
4.  **Test Your Changes:** Make sure the app builds and runs correctly. Add unit tests if applicable.
5.  **Submit a Pull Request (PR):**
    *   Push your changes to your forked repository.
    *   Open a PR against the `main` branch of the original repository.
    *   Provide a clear description of your changes in the PR.

We'll review your PR as soon as possible. Thank you for helping make Drona even better!

## 📜 License

This project is licensed under the **[Your License Here]** License.

Please replace `[Your License Here]` with the actual license under which this project is distributed (e.g., MIT License, Apache License 2.0). You should also include the full license text in a `LICENSE` file in the repository.

For example, if you choose the MIT License:

```
Copyright (c) [Year] [Your Name/Organization]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
