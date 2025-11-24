# 🎵 AI Radio Platform MVP

A cutting-edge Flutter mobile application combining live radio streaming, AI-powered music generation, and real-time social features - built without Google, AWS, or Twilio dependencies.

## ✨ Features

### 🎤 AI Music Generation (kie.ai)
- **Suno API Integration**: Generate high-quality music with custom lyrics
- **AI Avatar Creation**: Generate profile images using 4o Image API
- **Lyrics Generation**: Smart lyrics creation using LLM
- **Audio Stems**: Separate vocals, drums, bass, and instruments

### 📻 Radio Streaming
- Live radio station streaming
- Real-time chat integration
- Interactive features (gifts, reactions)
- Station discovery and favorites

### 💬 Real-Time Chat
- PocketBase WebSocket integration
- Live messaging during broadcasts
- Virtual gifting system
- User presence indicators

### 🎨 Modern UI/UX
- Glassmorphic design elements
- Smooth animations (flutter_animate)
- Dark theme with gradient accents
- Arabic RTL support ready

## 🚀 Tech Stack

### Mobile Framework
- **Flutter 3.32.0** with **Dart 3.10**
- **Riverpod 3.0** for state management
- **GoRouter 13.0** for navigation
- Clean architecture with feature-first organization

### UI/UX Packages
- `glassmorphism: ^3.2.0` - Modern glass effects
- `flutter_neumorphic: ^2.0.2` - Soft UI design
- `flutter_animate: ^4.5.0` - Advanced animations
- `lottie: ^3.1.0` - Motion graphics

### Audio & Media
- `just_audio: ^0.9.42` - Professional audio playback
- `record: ^5.1.2` - Audio recording
- `audio_wave: ^1.1.2` - Audio visualizations

### Backend Services (Big Tech-Free!)
- **kie.ai**: AI music generation, images, LLM
- **Supabase**: Database, auth, storage (open-source Firebase alternative)
- **PocketBase**: Real-time WebSocket connections

### Development Tools
- **Code Generation**: `build_runner`, `riverpod_generator`, `retrofit_generator`
- **Testing**: `flutter_test`, `integration_test`, `mockito`
- **Linting**: `flutter_lints`, `custom_lint`, `very_good_analysis`

## 📱 MVP Scope

### Phase 1 (8 weeks)
- ✅ User authentication & profiles
- ✅ AI music generation studio
- ✅ Basic radio streaming
- ✅ Real-time chat
- ✅ Modern glassmorphic UI
- ✅ Arabic RTL support

### Phase 2 (Future)
- Karaoke features
- Advanced social features
- Monetization system
- Enhanced radio management

## 🛠️ Setup Instructions

### Prerequisites
- Flutter 3.32.0+
- Dart 3.10+
- kie.ai API key
- Supabase project
- PocketBase instance (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_radio_platform
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

4. **Run code generation**
   ```bash
   flutter packages pub run build_runner build
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### API Setup

#### kie.ai
1. Sign up at [kie.ai](https://kie.ai)
2. Get your API key from dashboard
3. Add to `.env`: `KIE_AI_API_KEY=your_key_here`

#### Supabase
1. Create project at [Supabase](https://supabase.com)
2. Create required tables:
   - `users` - User profiles
   - `stations` - Radio stations
   - `ai_tracks` - Generated music tracks
   - `chat_messages` - Chat history
3. Add URL and anon key to `.env`

## 📁 Project Structure

```
lib/
├── app/                    # App-level configuration
│   ├── theme/             # Design system
│   ├── router/            # Navigation
│   └── pages/             # Main pages
├── core/                  # Shared utilities
│   ├── constants/         # App constants
│   ├── errors/           # Error handling
│   ├── network/          # HTTP configuration
│   └── utils/            # Helper functions
├── features/             # Feature modules
│   ├── auth/             # Authentication
│   ├── ai_music/         # AI music generation
│   ├── radio/            # Radio streaming
│   └── chat/             # Real-time chat
├── services/             # External services
│   ├── kie_ai_service.dart
│   ├── supabase_service.dart
│   └── pocketbase_service.dart
└── shared/               # Shared widgets/extensions
```

## 🎨 Design System

### Colors
- **Primary**: Purple gradient (`#8B5CF6`)
- **Secondary**: Teal (`#14B8A6`)
- **Background**: Deep space blue (`#0F0F23`)
- **Surface**: Midnight purple (`#1A1B3A`)

### Typography
- **Font**: Inter (Latin), Cairo (Arabic)
- **Styles**: Modern, clean hierarchy
- **RTL Support**: Full Arabic language support

### UI Components
- Glassmorphic buttons with blur effects
- Audio visualizers with gradients
- Smooth animations and transitions
- Responsive design patterns

## 🔧 Development

### Code Generation
```bash
# Run all generators
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch
```

### Testing
```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Build for Production
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📊 Performance Metrics

### Target Performance
- **App Load Time**: <3 seconds
- **Music Generation**: <30 seconds
- **UI Smoothness**: 60 FPS
- **Memory Usage**: <150MB

### Optimization Techniques
- Lazy loading for large lists
- Image caching with `cached_network_image`
- Audio streaming optimization
- Memory-efficient animations

## 🔒 Security

- Secure storage with `flutter_secure_storage`
- API key management via environment variables
- Input validation and sanitization
- Authentication state management

## 🌍 Localization

- English (default)
- Arabic (RTL support)
- Extensible localization system
- Dynamic language switching

## 📈 Roadmap

### MVP Release (Q1 2025)
- [x] Core app structure
- [x] AI music generation
- [x] Basic radio functionality
- [x] Real-time chat
- [ ] App store deployment

### v1.1 (Q2 2025)
- [ ] Karaoke recording
- [ ] Advanced social features
- [ ] Push notifications
- [ ] Performance optimizations

### v2.0 (Q3 2025)
- [ ] Monetization features
- [ ] Advanced AI tools
- [ ] Multi-language support
- [ ] Enterprise features

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make your changes
4. Add tests
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Join our Discord community
- Check the documentation

---

Built with ❤️ using Flutter, kie.ai, Supabase, and PocketBase