# Scope of Work (SOW): Digital Audio Platform

## Platform Vision

A digital audio entertainment ecosystem combining **live digital radio**, **karaoke experiences**, and **AI-powered music creation** into a user-centric platform designed for creators, listeners, brands, and broadcasters.

---

## STAGED DEVELOPMENT STRUCTURE

### Phase 1: Core Platform Setup

#### 1. User Onboarding & UI/UX Design

- Responsive and engaging UI/UX across mobile (iOS/Android) and web.
- Personal profile creation (for listeners, hosts, artists).
- Avatar & badge system for gamified user journeys.
- Multilingual interface with RTL support (Arabic & English initially).

#### 2. Digital Radio Core System

**For Listeners:**

- Browse and stream live episodes or 24/7 digital stations.
- Discover stations by:
  - Country, language, and genre.
- Real-time **interactive live player screen** includes:
  - Host name, avatar.
  - Episode sponsor name/logo.
  - **Mini ad-bar** with brand logos (auto-rotating).
  - Commercial breaks auto-inserted (no host action required).
  - Live listener chat.
  - Gifts & applause system (convertible to real or in-kind value).
  - Option to **send private message** to the host.
  - Call-in request button.

**For Hosts (Presenters):**

- Host dashboard with:
  - Stream controls.
  - Ad-break dashboard (automated, view-only).
  - Gift notifications.
  - Chat moderation.
  - Accept/reject listener calls.
  - Assign assistant/co-host.

**For Radio Station Owners:**

- Create & brand their own stations.
- Schedule episodes, assign or accept episode proposals from users.
- Filter content by:
  - Country, genre, and language.
- Host **station-level karaoke events**.
- Earn **automated ad revenue share** based on listener count & session engagement.
- View advanced analytics: listener trends, top shows, and income breakdown.

**For Advertisers:**

- **Self-Serve Ad Portal**:
  - Upload ads (audio + mini-bar logos).
  - Define campaign:
    - Audience targeting: age, gender, location, language.
    - Day/time slot, radio categories.
  - Assign budget per campaign.
  - Ads inserted automatically during live breaks (Snapchat-style logic).
  - Real-time dashboard: impressions, listen-through rate (LTR), click-through rate (CTR), and conversions.

---

### Phase 2: Live Karaoke Engine + Talent Ecosystem

#### 3. Karaoke Experience (Inspired by StarMaker)

**Karaoke for Users:**

- Solo, duet, or group mode.
- Search by artist, region, genre.
- Publish or save privately.
- Daily live karaoke parties (with themes).
- Interactive live audience with chat + gift sending.
- Performance bar for vocal accuracy (pitch-based scoring).
- Leaderboards + badges:
  - 🥉 Rising Star → 🌟 Hall of Famer → 👤 Renowned Singer → 🏆 Golden Icon.

**Hall of Fame**

- A prestigious golden-themed page showcasing iconic singers from each country.
- Each legendary artist will have a dedicated profile page featuring:
  - A brief biography
  - Featured portrait or avatar
  - A full list of their most performed or popular songs
- Below each artist profile, the platform displays the top karaoke performers of the week who sang their songs, ranked by:
  - Accuracy based on performance bar (pitch matching)
  - Number of virtual gifts received from the audience
  - Votes and reactions from listeners during the performance
- Each performer accumulates points based on the above criteria to determine their leaderboard position.
- High-ranking performers gain recognition, badges, and potential invitations to exclusive events or concerts hosted by the platform.

**The Lounge – Social Audio Room**

- A customizable audio lounge for users who follow each other on the platform.
- Users can invite friends into a themed lounge for audio-based interaction.
- Themes: Romantic, Celebration, Chill Vibes, Study Mode, and more.
- Lounge customization: virtual décor, lighting, emoji reactions, and background music selection.
- Voice chat enabled with spatial audio effects for immersive group discussions.
- Scheduled group listening events or private mini karaoke within the lounge.
- Hosts can send special gifts, run polls, or launch fun interactive activities.

**For Radio Stations & Hosts:**

- Host karaoke parties inside stations.
- Assign judges or audience polls.
- Branded karaoke events for sponsors.

**For the Audience:**

- Engage in chat, send applause and virtual gifts.
- Live polls/voting for top performers.

**Revenue Mechanics:**

- Performers receive gifts (convertible).
- Top talents featured in app + virtual concerts.
- Renowned singers are eligible for real-world stage performances + monetization.

---

### Phase 3: AI Music Composition Studio

#### 4. AI-Powered Music Studio

**User Journey:**

- Choose composition path:
  - 🎵 Upload MIDI / musical score.
  - 🎤 Hum/sing melody.
- AI interprets and generates a complete musical structure.
- Suggests arrangement, instruments (supporting Arabic maqams).
- User can:
  - Replace instruments (oud, qanoon, bendir, etc.).
  - Modify tempo, mood, genre.
  - Sing over the final track.
  - Save, export, or publish on their page.

**Open-Source Tech Integration:**

- **Amazon DeepComposer** (AWS Music AI tools).
- **Magenta by Google** (music generation models).
- **OpenAI Jukebox / MusicGen** (for future releases).
- **AI Maqam Training Model** (custom-trained to Arabic melodic scales).

**Collaborative Features:**

- Co-creation and draft-sharing.
- Community voting on original compositions.

**Monetization & Exposure:**

- Artists can monetize AI-created songs.
- Exclusive AI-content library promoted by the platform.
- Bookings enabled through Artist Profile Gate.

---

### Phase 4: Ecosystem Expansion

#### 5. Supporting Features

**Academy:**

- Courses in radio hosting, vocal training, music theory.
- Partnership with music institutions.
- Certification programs + onboarding into the platform as content creators.

**Virtual Talent Booking Gate:**

- Book any platform singer directly via platform.
- Smart calendar + payment integration.

**Annual Festival:**

- Spotlighting Hall of Fame users, top stations, and presenters.
- Real-life & virtual stage performances.
- Sponsors, fans, and VIP bookings.

**Merch & Mini-Shops:**

- Official merch store.
- In-app branded shops (shoppable during audio sessions).
- Dynamic display within karaoke/live pages (ad bar model).

---

## Technical Requirements

- **Mobile App:** Native iOS (Swift) & Android (Kotlin) or cross-platform Flutter.
- **Web:** React/Next.js frontend, Node.js or Django backend.
- **Database:** PostgreSQL + Firebase + scalable AWS infrastructure.
- **Streaming Tech:** RCS-compatible (Zetta + Revma + GSelector), supports DAB (Digital Audio Broadcasting).
- **Ad Engine:** Custom integration with analytics, targeting, and automated insertion.

---

## Proposal Evaluation Criteria

| Criteria | Weight (%) | Details |
|----------|------------|---------|
| Technical Competency & Architecture | 25% | Clear understanding of required tech stack, APIs, integrations, and streaming protocols. |
| UI/UX Expertise | 20% | Strong portfolio with modern, interactive, and engaging mobile-first designs. |
| Audio/Streaming App Experience | 15% | Proven delivery of apps with radio, music, or social-audio functionalities. |
| AI Integration Capability | 10% | Experience in implementing AI models (e.g., AWS AI, Magenta, voice-to-music AI systems). |
| Scalability Plan | 10% | Backend scaling, security, content delivery, and multi-region support readiness. |
| Monetization & Revenue Tools | 10% | Ability to implement self-serve ads, gifting economy, and analytics dashboards. |
| Cost Effectiveness & Timeline | 10% | Clear delivery phases with optimized cost vs. value proposition. |
