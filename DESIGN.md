# Animango - System Design Document

## 1. Overview

Animango is a Japanese language learning app that uses real anime, manga, movie, J-drama, and game content to teach vocabulary, kanji, and grammar. Users discover media, add it to their library, and study the actual Japanese used in each episode through flashcards, grammar lessons, pronunciation exercises, and an AI tutor.

The system has two main components:

- **iOS App** (SwiftUI + SwiftData) - Client-side UI, study engine, LLM integration
- **Python Backend** (FastAPI + PostgreSQL) - NLP subtitle processing pipeline, served on AWS EC2

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS App (Swift)                             │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Discover │  │ Library  │  │  Study   │  │ Profile  │  ← Tabs   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │              │             │              │                  │
│  ┌────┴──────────────┴─────────────┴──────────────┴─────┐          │
│  │                  ViewModels (@Observable)              │          │
│  └────┬──────────────┬─────────────┬──────────────┬─────┘          │
│       │              │             │              │                  │
│  ┌────┴──────────────┴─────────────┴──────────────┴─────┐          │
│  │                     Services Layer                     │          │
│  │  Jikan · TMDB · Jisho · AnimangoAPI · LLM · SRS      │          │
│  └────┬──────────────────────────────────────────────────┘          │
│       │                                                             │
│  ┌────┴─────────────────────────────────────────────────┐          │
│  │              SwiftData (Local Database)                │          │
│  │  Media · Vocabulary · Kanji · Grammar · Progress      │          │
│  └──────────────────────────────────────────────────────┘          │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ HTTP
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    AWS EC2 (Docker Compose)                          │
│                                                                     │
│  ┌────────┐     ┌──────────────────────┐     ┌──────────────────┐  │
│  │ Caddy  │────▶│   FastAPI (Python)    │────▶│  PostgreSQL 16   │  │
│  │ :80    │     │   :8000               │     │  :5432           │  │
│  └────────┘     │                      │     └──────────────────┘  │
│                 │  Subtitle Pipeline:   │                           │
│                 │  Parse → Tokenize →   │     ┌──────────────────┐  │
│                 │  JLPT Tag → Enrich → │────▶│  subtitles/      │  │
│                 │  Persist              │     │  (volume mount)  │  │
│                 └──────────────────────┘     └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. iOS App Architecture

### 2.1 Data Models (SwiftData)

All models use Apple's SwiftData framework for local persistence.

#### Core Language Items

| Model | Primary Key | Key Fields | Purpose |
|-------|------------|------------|---------|
| **VocabularyItem** | word | reading, meaning, jlptLevel, frequency, partOfSpeech, exampleSentences | Japanese vocabulary entry |
| **KanjiItem** | character | onReadings[], kunReadings[], meaning, strokeCount, jlptLevel, grade | Single kanji character |
| **GrammarPoint** | pattern | explanation, jlptLevel, examples[] (japanese, reading, english) | Grammar pattern (e.g., "~ている") |

#### Media & Episodes

| Model | Primary Key | Key Fields | Purpose |
|-------|------------|------------|---------|
| **Media** | externalID | mediaType, title, titleJapanese, synopsis, imageURL, score, episodeCount, isInLibrary | Anime/manga/game/movie/jdrama |
| **Episode** | id | mediaExternalID, episodeNumber, title, titleJapanese | Single episode of a media |
| **MediaType** | (enum) | anime, manga, game, jdrama, movie | Discriminator with display names, icons, colors |

#### Junction Tables (Media ↔ Language Items)

These link language content to the media/episodes they appear in:

```
Media ──┬── MediaVocabulary ──── VocabularyItem
        ├── MediaKanji ───────── KanjiItem
        └── MediaGrammar ─────── GrammarPoint

Episode ┬── EpisodeVocabulary ── VocabularyItem (+ episode_frequency)
        ├── EpisodeKanji ─────── KanjiItem
        └── EpisodeGrammar ───── GrammarPoint
```

#### Learning & Progress

| Model | Key Fields | Purpose |
|-------|------------|---------|
| **UserProgress** | itemID, itemType, knowledgeState, nextReviewDate, easeFactor, interval, repetitions | SM-2 spaced repetition tracking |
| **KnowledgeState** | neverLearned, learning, developing, mastered | Progression levels with comprehension weights |
| **Lesson** | episodeID, grammarPattern, title, order | Grammar lesson for an episode |
| **LessonExercise** | lessonID, exerciseType, prompt, answer, hint | Exercise within a lesson |
| **ExerciseType** | vocabRecall, kanjiReading, grammarFill, translation, pronunciation | Exercise variants |

#### LLM Configuration

| Model | Key Fields | Purpose |
|-------|------------|---------|
| **LLMConfiguration** | provider (apple/anthropic/openAI), apiKey, selectedModel | User's LLM provider settings |

### 2.2 Services Layer

#### External API Services

| Service | API | Purpose | Rate Limit |
|---------|-----|---------|------------|
| **JikanService** | api.jikan.moe/v4 | Anime & manga search, seasonal/top lists | 0.35s between requests |
| **TMDBService** | api.themoviedb.org/3 | Japanese movies & J-drama discovery | Standard |
| **IGDBService** | api.igdb.com/v4 | Japanese game search | Standard |
| **JishoService** | jisho.org/api/v1 | Vocabulary lookup (readings, meanings, JLPT) | 1s between requests |
| **AnimangoAPIService** | 44.210.75.181/api/v1 | Episode vocab/kanji/grammar from backend | None |

All services use **APIClient**, a generic async HTTP client with error handling.

**MediaSearchService** orchestrates parallel searches across all media type services and returns results sorted by score.

#### Content Generation (3-Tier Fallback)

**ContentGenerationService** is the central content pipeline on the client:

```
Tier 1: AnimangoAPIService.fetchEpisodeContent()
  ↓ (if no backend data)
Tier 2: JishoService + LLM generation (grammar lessons, exercises)
  ↓ (if no LLM configured)
Tier 3: Jisho-only (basic vocab recall exercises)
```

Each tier persists results to SwiftData, so subsequent loads are instant.

#### LLM Integration

**LLMServiceManager** (@Observable) routes requests to the configured provider:

| Provider | Backend | Models | Auth |
|----------|---------|--------|------|
| **AppleIntelligenceProvider** | FoundationModels (on-device) | System default | None needed |
| **AnthropicProvider** | api.anthropic.com | claude-sonnet, claude-haiku, claude-opus | API key |
| **OpenAIProvider** | api.openai.com | gpt-4o, gpt-4o-mini | API key |

All providers implement the **LLMServiceProvider** protocol:
- `generateEpisodeContent(mediaTitle, episodeTitle, episodeNumber)` → vocabulary + grammar lessons + exercises as structured JSON
- `chat(messages)` → conversational response for the AI tutor

#### Speech & Pronunciation

| Service | Framework | Purpose |
|---------|-----------|---------|
| **SpeechService** | AVSpeechSynthesizer | Text-to-speech for Japanese (with slow mode at 0.25x rate) |
| **PronunciationService** | SFSpeechRecognizer (ja-JP) + AVAudioEngine | Speech recognition, audio level for waveform, pronunciation scoring |

**Pronunciation scoring** uses:
- Character-level Levenshtein distance (text accuracy)
- Voice analytics jitter (pitch stability)
- Speaking rate in morae/minute + pause duration (fluency)

#### Learning Engine

| Service | Purpose |
|---------|---------|
| **SRSEngine** | SM-2 spaced repetition: grades (again/hard/good/easy), updates easeFactor, interval, repetitions, knowledgeState, nextReviewDate |
| **ComprehensionCalculator** | Weighted average of vocabulary knowledgeStates × frequency per media |
| **RecommendationService** | Scores candidates by genreScore (0.35), noveltyScore (0.30), typeScore (0.20), ratingScore (0.15) |

### 2.3 ViewModels

All ViewModels are `@Observable` (or `@Observable @MainActor`) for SwiftUI binding.

| ViewModel | Key State | Actions |
|-----------|-----------|---------|
| **DiscoverViewModel** | searchResults[], topAnime[], topManga[], popularMovies[], popularDrama[] | loadInitialContent(), search(), addToLibrary() |
| **MediaDetailViewModel** | vocabularyItems[], kanjiItems[], grammarPoints[], comprehensionPercentage | loadLanguageData(), loadProgressData() |
| **EpisodeDetailViewModel** | vocabularyItems[], kanjiItems[], grammarPoints[], lessons[] | generateContent() (triggers 3-tier), loadContent() |
| **EpisodeListViewModel** | episodes[] | loadEpisodes() |
| **StudyViewModel** | selectedMedia?, dueItemCount | loadDueItems() |
| **StudySessionViewModel** | cards[] (max 20), currentIndex, isFlipped, sessionResult | startSession(), gradeCard() |
| **LessonViewModel** | exercises[], currentExerciseIndex, correctCount | loadLesson(), checkAnswer(), pronunciationCompleted() |
| **ChatTutorViewModel** | messages[], inputText | configure(), sendMessage() (via LLM) |
| **ProfileViewModel** | totalKnownWords, jlptBreakdown, studyStreak | loadStats() |
| **LibraryViewModel** | comprehensionScores[], sortOrder | refreshComprehension(), removeFromLibrary() |
| **VocabularyListViewModel** | vocabularyItems[], searchText | loadVocabulary(), filteredItems |

### 2.4 Views & Navigation

```
TabView
├── Tab 1: Discover
│   └── DiscoverView
│       ├── MediaTypeFilterBar (anime/manga/game/jdrama/movie filter)
│       ├── RecommendationSection × 4 (browse mode)
│       ├── LazyVGrid of MediaCardView (search mode)
│       └── → MediaDetailView
│           ├── Hero: poster, title, score, synopsis
│           ├── Language points: vocab/kanji/grammar counts
│           ├── → VocabularyListView → WordDetailView
│           ├── → KanjiListView → KanjiDetailView
│           ├── → GrammarListView → GrammarDetailView
│           ├── → EpisodeListView → EpisodeDetailView
│           │       ├── Vocabulary, Kanji, Grammar tabs
│           │       └── → LessonView
│           │           ├── Grammar intro
│           │           └── LessonExerciseView (5 types)
│           │               └── PronunciationExerciseView
│           └── Comprehension gauge
│
├── Tab 2: Library
│   └── LibraryView
│       ├── Sort/filter controls
│       ├── LibraryMediaRow (with ComprehensionGaugeView)
│       └── → MediaDetailView
│
├── Tab 3: Study
│   └── StudyView
│       ├── Due items counter
│       ├── SessionTypePickerView (vocab/kanji/grammar)
│       ├── Media selector
│       ├── → StudySessionView
│       │   ├── StudyCard (flip animation)
│       │   ├── Grade buttons (Again/Hard/Good/Easy)
│       │   └── → StudyResultView (summary)
│       └── → ChatTutorView (AI conversation)
│
└── Tab 4: Profile
    └── ProfileView
        ├── StatsCardView (words/kanji known/learning)
        ├── JLPTBreakdownChart (N1-N5 progress)
        └── → SettingsView (LLM provider config)
```

### 2.5 Key Data Flows

#### Flow 1: Discovering and Adding Media

```
User opens Discover tab
  → DiscoverViewModel.loadInitialContent()
    → JikanService.getTopAnime() (parallel)
    → JikanService.getTopManga() (parallel)
    → TMDBService.discoverJapaneseMovies() (parallel)
    → TMDBService.discoverJDrama() (parallel)
  → Results displayed in RecommendationSections
  → User taps media card → MediaDetailView
  → User taps "Add to Library"
    → media.isInLibrary = true (saved to SwiftData)
```

#### Flow 2: Generating Episode Content

```
User opens episode in MediaDetailView
  → EpisodeDetailViewModel.generateContent()
    → ContentGenerationService.generateContentForEpisode()

  Tier 1 (Cloud API):
    → AnimangoAPIService.fetchEpisodeContent("anime_16498", 1)
    → Returns: 446 words, 292 kanji, 8 grammar patterns
    → Persists: VocabularyItem + EpisodeVocabulary links
                KanjiItem + EpisodeKanji links
                GrammarPoint + EpisodeGrammar links

  Tier 2 (if Tier 1 fails - LLM + Jisho):
    → JishoService.searchWords(mediaTitle) → top 12 words
    → LLMServiceManager.generateEpisodeContent()
      → Anthropic/OpenAI/Apple: generates JSON with vocab + lessons
    → Persists: VocabularyItem, Lesson, LessonExercise

  Tier 3 (if no LLM - Jisho only):
    → Creates basic vocab recall exercises from Jisho results

  → EpisodeDetailView loads and displays content
```

#### Flow 3: Studying with Flashcards

```
User selects media + session type in Study tab
  → StudySessionViewModel.startSession()
    → Queries MediaVocabulary WHERE mediaExternalID = selected
    → Fetches matching VocabularyItems
    → Filters: due (nextReviewDate ≤ now) OR new (no UserProgress)
    → Creates StudyCardData (front: word, back: reading + meaning)
    → Shuffles, limits to 20 cards

  User flips card, selects grade
  → StudySessionViewModel.gradeCard(grade)
    → SRSEngine.processReview(progress, grade)
      → Updates: easeFactor, interval, repetitions
      → Advances: neverLearned → learning → developing → mastered
      → Sets: nextReviewDate based on new interval
    → Saves to SwiftData

  Session ends → StudyResultView shows performance
```

#### Flow 4: Pronunciation Exercise

```
User reaches pronunciation exercise in LessonView
  → PronunciationExerciseView displays target text
  → User taps record button
    → PronunciationService.startRecording(expectedText)
      → SFSpeechRecognizer (ja-JP) starts listening
      → AVAudioEngine captures audio levels → WaveformView
  → User stops recording
    → PronunciationService.computeFeedback()
      → Levenshtein distance: text accuracy
      → Voice analytics: pitch stability (jitter)
      → Speaking rate: fluency (morae/min + pauses)
    → PronunciationScoreView shows breakdown
    → If score ≥ 0.6: LessonViewModel.correctCount++
```

---

## 3. Python Backend Architecture

### 3.1 Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | FastAPI (async) |
| Database | PostgreSQL 16 (asyncpg driver) |
| ORM | SQLAlchemy 2.0 (async) |
| Migrations | Alembic |
| Tokenizer | MeCab via Fugashi + UniDic-Lite |
| Subtitle parsing | pysrt (SRT), ass (ASS/SSA) |
| HTTP client | aiohttp (async) |
| Server | Uvicorn (ASGI) |
| Reverse proxy | Caddy |
| Container | Docker + Docker Compose |

### 3.2 Database Schema

```
┌──────────────────┐     ┌──────────────────────────┐
│    Vocabulary     │     │  EpisodeVocabularyLink    │
│──────────────────│     │──────────────────────────│
│ word (PK)        │◄────│ vocabulary_word (FK)      │
│ reading          │     │ media_id                  │
│ meaning          │     │ episode_number            │
│ jlpt_level       │     │ episode_frequency         │
│ frequency        │     │ UNIQUE(media,ep,word)     │
│ part_of_speech   │     └──────────────────────────┘
│ example_sentence │
└──────────────────┘

┌──────────────────┐     ┌──────────────────────────┐
│      Kanji       │     │    EpisodeKanjiLink       │
│──────────────────│     │──────────────────────────│
│ character (PK)   │◄────│ kanji_character (FK)      │
│ on_readings[]    │     │ media_id                  │
│ kun_readings[]   │     │ episode_number            │
│ meaning          │     │ UNIQUE(media,ep,char)     │
│ stroke_count     │     └──────────────────────────┘
│ jlpt_level       │
│ grade            │
└──────────────────┘

┌──────────────────┐     ┌──────────────────────────┐
│  GrammarPoint    │     │   EpisodeGrammarLink      │
│──────────────────│     │──────────────────────────│
│ pattern (PK)     │◄────│ grammar_pattern (FK)      │
│ explanation      │     │ media_id                  │
│ jlpt_level       │     │ episode_number            │
└───────┬──────────┘     │ UNIQUE(media,ep,pattern)  │
        │                └──────────────────────────┘
        ▼
┌──────────────────┐     ┌──────────────────────────┐
│ GrammarExample   │     │    ProcessedEpisode       │
│──────────────────│     │──────────────────────────│
│ grammar_pattern  │     │ media_id                  │
│ japanese         │     │ episode_number            │
│ reading          │     │ processed_at              │
│ english          │     │ stats (JSON)              │
└──────────────────┘     │ UNIQUE(media,ep)          │
                         └──────────────────────────┘
```

### 3.3 API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| **GET** | `/api/v1/health` | Health check → `{"status": "ok"}` |
| **POST** | `/api/v1/media/{media_id}/episodes/{ep}/subtitles` | Upload .srt/.ass file, process through pipeline |
| **GET** | `/api/v1/media/{media_id}/episodes/{ep}/content` | Retrieve processed episode content (cached) |
| **GET** | `/api/v1/media/{media_id}/content` | Aggregate content across all episodes of a media |

### 3.4 Subtitle Processing Pipeline

This is the core of the backend. When a subtitle file is submitted (via API upload or the seed script), it goes through 12 steps:

```
Step 1:  Cache check (ProcessedEpisode table)
           ↓ (not cached)
Step 2:  Parse subtitles
           Input:  Raw .srt or .ass text
           Output: List[TimedLine] with start_ms, end_ms, text
           Notes:  Filters to Japanese-only lines (CJK/kana detection)
                   Strips HTML tags and ASS override codes
           ↓
Step 3:  Tokenize with MeCab
           Input:  List of text lines
           Output: TokenizationResult (word_frequencies, word_info)
           Notes:  Extracts lemmas (dictionary forms)
                   POS tagging (名詞→Noun, 動詞→Verb, etc.)
                   Skips particles, symbols, auxiliary verbs, single kana
           ↓
Step 4:  Extract kanji
           Input:  Full text
           Output: Set of unique kanji characters (U+4E00..U+9FFF)
           ↓
Step 5:  Detect grammar patterns
           Input:  Full text
           Output: List[GrammarMatch] (pattern, explanation, jlpt_level)
           Notes:  Regex matching against ~50 bundled patterns
                   Filters by minimum 2 occurrences, max 20 results
           ↓
Step 6:  JLPT tagging
           Input:  Word list
           Output: JLPT breakdown dict ({"N1": 5, "N5": 20, ...})
           Notes:  Looks up bundled jlpt_vocabulary.json + jlpt_kanji.json
           ↓
Step 7:  Jisho enrichment
           Input:  Top 50 words not in JLPT data (by frequency)
           Output: Dict of {word: {reading, meaning, jlpt_level, pos}}
           Notes:  Rate-limited async HTTP to jisho.org API
           ↓
Steps 8-10: Persist to database
           - Vocabulary: Create if new, link to episode (with frequency)
           - Kanji: Create if new, link to episode
           - Grammar: Create point + examples if new, link to episode
           ↓
Step 11: Record ProcessedEpisode
           Stores: media_id, episode_number, processed_at, stats JSON
           ↓
Step 12: Build response
           Output: EpisodeContentResponse (vocabulary[], kanji[], grammar[], stats)
```

### 3.5 Services

| Service | File | Purpose |
|---------|------|---------|
| **SubtitleParser** | subtitle_parser.py | Parse SRT/ASS formats → TimedLine objects |
| **Tokenizer** | tokenizer.py | MeCab morphological analysis → lemmas + frequencies |
| **KanjiExtractor** | kanji_extractor.py | Unicode range scan → unique kanji set |
| **JLPTTagger** | jlpt_tagger.py | Bundled JLPT data lookup (vocab + kanji) |
| **GrammarDetector** | grammar_detector.py | Regex pattern matching against bundled grammar patterns |
| **JishoEnricher** | jisho_enricher.py | Async HTTP to Jisho API for missing word data |
| **Pipeline** | pipeline.py | Orchestrates all services in 12-step sequence |

### 3.6 Bundled Data Files

| File | Contents | Size |
|------|----------|------|
| `app/data/jlpt_vocabulary.json` | ~1000+ vocab entries with JLPT levels 1-5 | ~30KB |
| `app/data/jlpt_kanji.json` | ~2200+ kanji with readings, stroke count, grade | ~34KB |
| `app/data/grammar_patterns.json` | ~50+ patterns with regex, explanation, examples | ~34KB |

### 3.7 Scripts

#### scripts/seed.py - Batch Subtitle Seeder

Processes an entire directory of subtitle files in one run:

```bash
python -m scripts.seed \
  --dir /app/subtitles/shingeki_no_kyojin \
  --media-id anime_16498 \
  --start-episode 1
```

- Scans for `.srt` and `.ass` files (sorted alphabetically)
- Extracts episode numbers from filenames (regex: `ep(\d+)`, fallback to index)
- Calls `pipeline.process_subtitles()` for each file
- Handles UTF-8 BOM encoding (`utf-8-sig`)
- Continues on errors (logs and skips)
- Prints summary: processed/skipped/errors + totals

#### scripts/download.py - Subtitle Downloader

Downloads Japanese subtitles from external sources:

```bash
# From jimaku.cc (anime-focused, preferred)
python -m scripts.download jimaku \
  --anilist-id 16498 \
  --media-id anime_16498 \
  --seed  # optionally seed immediately

# From OpenSubtitles.com (broader catalog)
python -m scripts.download opensubtitles \
  --query "Attack on Titan" \
  --media-id anime_16498 \
  --seed
```

**jimaku.cc API**:
- Auth: `Authorization` header with API key
- Search: `GET /api/entries/search?anilist_id=X` or `?query=X`
- Files: `GET /api/entries/{id}/files`
- Rate limit: 25 req/min

**OpenSubtitles API**:
- Auth: `Api-Key` header
- Search: `GET /subtitles?languages=ja&query=X` or `&tmdb_id=X`
- Download: `POST /download` with `file_id` → temp URL
- Rate limit: per-tier (check response headers)

---

## 4. Deployment Architecture

### 4.1 AWS Infrastructure

| Resource | Details |
|----------|---------|
| **EC2 Instance** | t4g.small (ARM64), Amazon Linux 2023 |
| **Elastic IP** | 44.210.75.181 |
| **Security Group** | Ports 22 (SSH), 80 (HTTP), 443 (HTTPS) |
| **Key Pair** | animango-key (PEM) |

### 4.2 Docker Compose Services

```yaml
services:
  db:        # PostgreSQL 16-alpine, persistent volume, health check
  api:       # FastAPI app, port 8000, subtitles volume mount
  caddy:     # Reverse proxy, port 80 → api:8000
```

**Environment Variables** (in `.env`):
- `POSTGRES_PASSWORD` - Database password
- `JIMAKU_API_KEY` - jimaku.cc API key
- `OPENSUBTITLES_API_KEY` - OpenSubtitles API key

### 4.3 iOS ↔ Backend Communication

The iOS app communicates with the backend via `AnimangoAPIService`:

```
iOS AnimangoAPIService
  → GET http://44.210.75.181/api/v1/media/{id}/episodes/{ep}/content
  → Caddy (reverse proxy)
    → FastAPI (port 8000)
      → Pipeline.get_cached_content()
        → PostgreSQL query
  ← EpisodeContentResponse JSON
    ← VocabularyDTO[], KanjiDTO[], GrammarDTO[], StatsDTO
```

The iOS app has an **App Transport Security** exception in `Info.plist` for HTTP to the bare IP address.

---

## 5. End-to-End Workflow

### How content gets from a subtitle file to the user's study session:

```
1. ACQUIRE SUBTITLES
   scripts/download.py jimaku --anilist-id 16498 --media-id anime_16498
   → Downloads 177 .ass/.srt files to /app/subtitles/shingeki_no_kyojin/

2. PROCESS & STORE
   scripts/seed.py --dir /app/subtitles/shingeki_no_kyojin --media-id anime_16498
   → Each file passes through the 12-step pipeline
   → Result: 3,878 vocabulary, 1,420 kanji, 34 grammar patterns in PostgreSQL

3. SERVE VIA API
   GET /api/v1/media/anime_16498/episodes/1/content
   → Returns episode 1: 446 words, 292 kanji, 8 grammar patterns

4. iOS APP FETCHES
   ContentGenerationService → Tier 1 → AnimangoAPIService.fetchEpisodeContent()
   → Parses response → Persists to SwiftData (VocabularyItem, KanjiItem, etc.)

5. USER STUDIES
   StudySessionViewModel → Queries SwiftData for due items
   → Presents flashcards → User grades → SRSEngine updates progress
   → Next review date calculated via SM-2 algorithm
```

---

## 6. Data Sizes (Attack on Titan Season 1)

| Metric | Value |
|--------|-------|
| Episodes processed | 25 |
| Unique vocabulary | 3,878 words |
| Unique kanji | 1,420 characters |
| Grammar patterns | 34 |
| Avg words per episode | ~580 |
| Avg kanji per episode | ~400 |
| Avg grammar per episode | ~12 |
| Lines per episode | ~300 |

---

## 7. Key Design Decisions

### Why 3-Tier Fallback?
Not all anime has been seeded into the backend yet. Tier 2 (LLM) generates contextually relevant content on the fly. Tier 3 (Jisho-only) ensures the app is always functional even without an LLM configured.

### Why MeCab for Tokenization?
Japanese doesn't use spaces between words. MeCab is the standard morphological analyzer for Japanese NLP, providing accurate word segmentation, lemmatization (dictionary form extraction), and part-of-speech tagging.

### Why SM-2 for Spaced Repetition?
SM-2 is the proven algorithm behind Anki. It balances simplicity with effectiveness: tracks easeFactor (difficulty), interval (days between reviews), and repetitions (consecutive correct answers) to schedule optimal review times.

### Why Bundled JLPT Data?
Looking up every word via Jisho API would be too slow (1 req/sec rate limit). Bundled JSON files allow instant JLPT classification for ~3000+ vocabulary and ~2200+ kanji. Jisho is only called for the remaining unlabeled words.

### Why SwiftData (not Core Data)?
SwiftData is Apple's modern persistence framework that integrates naturally with SwiftUI's @Observable pattern. It provides type-safe queries, automatic schema migration, and less boilerplate than Core Data.

### Why Caddy?
Caddy provides automatic HTTPS with Let's Encrypt when a domain is configured. Currently running in HTTP-only mode for the bare IP, but switching to HTTPS requires only a one-line Caddyfile change.
