/// ChapterService
///
/// Provides chapter lists per subject (SSC/HSC Bangladesh curriculum).
/// Currently backed by a static map for MVP speed.
/// To switch to a DB table later: replace [getChapters] body with a Supabase
/// query — no other file needs changing.
class ChapterService {
  ChapterService._();

  // ─── Chapter map ─────────────────────────────────────────────────────────
  static const Map<String, List<String>> _chapters = {
    'higher math': [
      'Chapter 1 — Sets & Functions',
      'Chapter 2 — Algebraic Expressions',
      'Chapter 3 — Geometry & Coordinates',
      'Chapter 4 — Trigonometry',
      'Chapter 5 — Binomial Theorem',
      'Chapter 6 — Statistics',
      'Chapter 7 — Limits & Continuity',
      'Chapter 8 — Differentiation',
      'Chapter 9 — Integration',
      'Chapter 10 — Complex Numbers',
    ],
    'general math': [
      'Chapter 1 — Real Numbers',
      'Chapter 2 — Ratio & Proportion',
      'Chapter 3 — Algebra (Basics)',
      'Chapter 4 — Geometry (Lines & Angles)',
      'Chapter 5 — Circles',
      'Chapter 6 — Mensuration',
      'Chapter 7 — Statistics & Probability',
      'Chapter 8 — Financial Math',
    ],
    'physics': [
      'Chapter 1 — Physical World & Measurement',
      'Chapter 2 — Vector & Scalar Quantities',
      'Chapter 3 — Motion (Kinematics)',
      'Chapter 4 — Laws of Motion',
      'Chapter 5 — Work, Energy & Power',
      'Chapter 6 — Gravitation',
      'Chapter 7 — Properties of Matter',
      'Chapter 8 — Waves & Sound',
      'Chapter 9 — Light (Optics)',
      'Chapter 10 — Electricity & Magnetism',
      'Chapter 11 — Modern Physics',
    ],
    'chemistry': [
      'Chapter 1 — Atomic Structure',
      'Chapter 2 — Periodic Table',
      'Chapter 3 — Chemical Bonding',
      'Chapter 4 — Chemical Reactions',
      'Chapter 5 — Gases',
      'Chapter 6 — Solutions',
      'Chapter 7 — Acids, Bases & Salts',
      'Chapter 8 — Electrochemistry',
      'Chapter 9 — Organic Chemistry (Basics)',
      'Chapter 10 — Organic Chemistry (Advanced)',
    ],
    'biology': [
      'Chapter 1 — Introduction to Biology',
      'Chapter 2 — Cell Structure & Function',
      'Chapter 3 — Cell Division',
      'Chapter 4 — Bioenergetics (Photosynthesis & Respiration)',
      'Chapter 5 — Nutrition',
      'Chapter 6 — Transport in Plants & Animals',
      'Chapter 7 — Excretion',
      'Chapter 8 — Nervous System',
      'Chapter 9 — Reproduction',
      'Chapter 10 — Genetics & Heredity',
      'Chapter 11 — Evolution',
      'Chapter 12 — Ecology',
    ],
    'bangla 1st': [
      'Prose — Shuvo Karon',
      'Prose — Amar Choto Nadi',
      'Prose — Ekushey February',
      'Poetry — Banga Mata',
      'Poetry — Kanshi',
      'Poetry — Mukti',
      'Grammar — Sandhi',
      'Grammar — Samasa',
      'Grammar — Sentence Transformation',
      'Essay Writing',
    ],
    'bangla 2nd': [
      'Grammar — Parts of Speech (Shobdo O Pad)',
      'Grammar — Sentence (Bakyo)',
      'Grammar — Punctuation',
      'Grammar — Proverbs & Idioms',
      'Grammar — Letter & Application Writing',
      'Grammar — Paragraph',
      'Grammar — Comprehension (Poratit)',
    ],
    'english 1st': [
      'Reading — Comprehension Passages',
      'Reading — Short Stories',
      'Writing — Guided Composition',
      'Writing — Narrative Writing',
      'Writing — Descriptive Writing',
      'Writing — Dialogue Writing',
    ],
    'english 2nd': [
      'Grammar — Parts of Speech',
      'Grammar — Tense',
      'Grammar — Voice (Active & Passive)',
      'Grammar — Narration (Direct & Indirect)',
      'Grammar — Sentence Transformation',
      'Grammar — Fill in the Blanks (Articles & Prepositions)',
      'Grammar — Paragraph Writing',
      'Grammar — Letter & Email Writing',
      'Grammar — Completing Stories',
    ],
    'history': [
      'Chapter 1 — Ancient Bengal',
      'Chapter 2 — Mughal Period',
      'Chapter 3 — British Rule in Bengal',
      'Chapter 4 — Language Movement (1952)',
      'Chapter 5 — Six-Point Programme',
      'Chapter 6 — Mass Uprising (1969)',
      'Chapter 7 — Liberation War (1971)',
      'Chapter 8 — Post-Independence Bangladesh',
    ],
    'ict': [
      'Chapter 1 — Information & Communication Technology',
      'Chapter 2 — Communication Systems',
      'Chapter 3 — Number Systems & Encoding',
      'Chapter 4 — Web Design (HTML/CSS)',
      'Chapter 5 — Programming (C Language)',
      'Chapter 6 — Database Systems',
    ],
    'islam': [
      'Al-Quran — Tafsir & Tajweed',
      'Hadith — Major Collections',
      'Iman & Aqeedah (Belief)',
      'Salah & Ibadah (Prayer)',
      'Muamalat (Social & Financial Ethics)',
      'History of Islam in Bangladesh',
      'Islamic Morality & Character',
    ],
    'hinduism': [
      'Dharma — Basic Concepts',
      'Scripture — Introduction to Vedas & Upanishads',
      'Epics — Ramayana & Mahabharata',
      'Bhagavad Gita — Key Lessons',
      'Hindu Festivals & Rituals',
      'Ethics & Moral Values',
    ],
  };

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns the chapter list for [subjectKey], or [] if unknown.
  ///
  /// [subjectKey] should match the key used in [SubjectService] (lower-case).
  static List<String> getChapters(String subjectKey) {
    return _chapters[subjectKey.toLowerCase().trim()] ?? [];
  }

  /// True if this subject has a known chapter list.
  static bool hasChapters(String subjectKey) =>
      _chapters.containsKey(subjectKey.toLowerCase().trim());
}
