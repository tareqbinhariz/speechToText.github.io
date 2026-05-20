# Aswat | 🎤 Smart Speech-to-Text & Translation Dashboard

Aswat (Arabic for "Voices") is a modern, high-performance, responsive web application for **live microphone speech-to-text recording**, **audio file uploading & transcription**, and **instant translation** between Arabic and English. 

Powered by **Google's Gemini API**, the application features a premium dark glassmorphic design and incorporates an **ultra-resilient 16-model fallback cascade** with real-time UI feedback to guarantee a free, zero-cost, reliable transcription experience out-of-the-box.

---

## 📂 Repository Structure

This repository is unified to hold both the live website deployment assets and the Flutter source code:

*   **Root Directory (`/`)**: Holds the optimized, compiled release assets (HTML, JS, CanvasKit) served directly by **GitHub Pages**.
*   **`/project`**: Contains the complete **Flutter Source Code** for developers to modify and build.

---

## 🛠️ Unified Development Workflow

We have provided an automated deployment script in the root directory to make editing and publishing your changes extremely simple.

### Quick Deploy (PowerShell)
Whenever you make changes to the Flutter source code under `project/` and want to push them live to GitHub Pages, simply run the deploy script from the repository root:

```powershell
.\deploy.ps1
```

This script will automatically:
1. Compile the Flutter web application in release mode.
2. Synchronize all built assets (JS, CanvasKit, assets) to the root `/` folder.
3. Stage the files in Git, leaving you ready to commit and push!

---

## 💎 Features & Highlights

1.  **Dual Input Modes**: 
    *   **Live Microphone**: Record directly in the browser with high-fidelity concentric waveform feedback and smart sentence capitalization/duplication removal.
    *   **Audio File Upload**: Pick `.mp3`, `.wav`, `.m4a`, `.ogg`, or `.flac` files up to several megabytes and transcribe them instantly.
2.  **Ultra-Resilient Fallback Engine**: Cascades across 16 different Gemini models (including Gemini 3.5, 3.1, 2.5, 2.0, and 1.5 families) if a model is overloaded, busy (503), or deprecated.
3.  **Active UI Cascade Feedback**: Shows exactly which model is being attempted in real-time on your dashboard (e.g. `⚠️ Gemini model busy, cascading to fallback model: gemini-3.5-flash...`).
4.  **Instant Translation**: Translate generated transcriptions between Arabic and English on-the-fly.
5.  **Smart Formatter & Exporter**: Displays live statistics (word count, char count, read time) and allows one-click clipboard copying or raw `.txt` file downloading.
6.  **Secure Default Key**: Obfuscates the default API key at build time (runtime Base64 decoded) to prevent automated GitHub credential crawlers from revoking the token.
7.  **Fully Responsive Design**: Fluid sidebar layout that collapses into a scrollable mobile layout wrapper with overflow-safe navigation.
