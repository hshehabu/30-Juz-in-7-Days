/// Static reference data for the 114 surahs, keyed to the standard 604-page
/// Madani mushaf (King Fahd Complex print). Used for page counts, reading time
/// estimates, in-day surah tracking and sitting splits.
class SurahInfo {
  final int number;
  final String nameEn;
  final String nameAr;

  /// Page on which the surah begins in the 604-page Madani mushaf.
  final int startPage;

  const SurahInfo(this.number, this.nameEn, this.nameAr, this.startPage);

  String name(bool isArabic) => isArabic ? nameAr : nameEn;
}

/// One sitting of a split daily portion (e.g. "after Fajr").
class ReadingSitting {
  final int index;
  final int startPage;
  final int endPage;
  final SurahInfo startSurah;

  const ReadingSitting({
    required this.index,
    required this.startPage,
    required this.endPage,
    required this.startSurah,
  });

  int get pageCount => endPage - startPage + 1;
}

class QuranData {
  QuranData._();

  static const int totalPages = 604;

  /// Average minutes needed to recite one mushaf page at a moderate pace.
  static const double minutesPerPage = 1.5;

  static const List<SurahInfo> surahs = [
    SurahInfo(1, 'Al-Fatihah', 'الفاتحة', 1),
    SurahInfo(2, 'Al-Baqarah', 'البقرة', 2),
    SurahInfo(3, 'Aal-Imran', 'آل عمران', 50),
    SurahInfo(4, 'An-Nisa', 'النساء', 77),
    SurahInfo(5, 'Al-Ma\'idah', 'المائدة', 106),
    SurahInfo(6, 'Al-An\'am', 'الأنعام', 128),
    SurahInfo(7, 'Al-A\'raf', 'الأعراف', 151),
    SurahInfo(8, 'Al-Anfal', 'الأنفال', 177),
    SurahInfo(9, 'At-Tawbah', 'التوبة', 187),
    SurahInfo(10, 'Yunus', 'يونس', 208),
    SurahInfo(11, 'Hud', 'هود', 221),
    SurahInfo(12, 'Yusuf', 'يوسف', 235),
    SurahInfo(13, 'Ar-Ra\'d', 'الرعد', 249),
    SurahInfo(14, 'Ibrahim', 'إبراهيم', 255),
    SurahInfo(15, 'Al-Hijr', 'الحجر', 262),
    SurahInfo(16, 'An-Nahl', 'النحل', 267),
    SurahInfo(17, 'Al-Isra', 'الإسراء', 282),
    SurahInfo(18, 'Al-Kahf', 'الكهف', 293),
    SurahInfo(19, 'Maryam', 'مريم', 305),
    SurahInfo(20, 'Ta-Ha', 'طه', 312),
    SurahInfo(21, 'Al-Anbiya', 'الأنبياء', 322),
    SurahInfo(22, 'Al-Hajj', 'الحج', 332),
    SurahInfo(23, 'Al-Mu\'minun', 'المؤمنون', 342),
    SurahInfo(24, 'An-Nur', 'النور', 350),
    SurahInfo(25, 'Al-Furqan', 'الفرقان', 359),
    SurahInfo(26, 'Ash-Shu\'ara', 'الشعراء', 367),
    SurahInfo(27, 'An-Naml', 'النمل', 377),
    SurahInfo(28, 'Al-Qasas', 'القصص', 385),
    SurahInfo(29, 'Al-Ankabut', 'العنكبوت', 396),
    SurahInfo(30, 'Ar-Rum', 'الروم', 404),
    SurahInfo(31, 'Luqman', 'لقمان', 411),
    SurahInfo(32, 'As-Sajdah', 'السجدة', 415),
    SurahInfo(33, 'Al-Ahzab', 'الأحزاب', 418),
    SurahInfo(34, 'Saba', 'سبأ', 428),
    SurahInfo(35, 'Fatir', 'فاطر', 434),
    SurahInfo(36, 'Ya-Sin', 'يس', 440),
    SurahInfo(37, 'As-Saffat', 'الصافات', 446),
    SurahInfo(38, 'Sad', 'ص', 453),
    SurahInfo(39, 'Az-Zumar', 'الزمر', 458),
    SurahInfo(40, 'Ghafir', 'غافر', 467),
    SurahInfo(41, 'Fussilat', 'فصلت', 477),
    SurahInfo(42, 'Ash-Shura', 'الشورى', 483),
    SurahInfo(43, 'Az-Zukhruf', 'الزخرف', 489),
    SurahInfo(44, 'Ad-Dukhan', 'الدخان', 496),
    SurahInfo(45, 'Al-Jathiyah', 'الجاثية', 499),
    SurahInfo(46, 'Al-Ahqaf', 'الأحقاف', 502),
    SurahInfo(47, 'Muhammad', 'محمد', 507),
    SurahInfo(48, 'Al-Fath', 'الفتح', 511),
    SurahInfo(49, 'Al-Hujurat', 'الحجرات', 515),
    SurahInfo(50, 'Qaf', 'ق', 518),
    SurahInfo(51, 'Adh-Dhariyat', 'الذاريات', 520),
    SurahInfo(52, 'At-Tur', 'الطور', 523),
    SurahInfo(53, 'An-Najm', 'النجم', 526),
    SurahInfo(54, 'Al-Qamar', 'القمر', 528),
    SurahInfo(55, 'Ar-Rahman', 'الرحمن', 531),
    SurahInfo(56, 'Al-Waqi\'ah', 'الواقعة', 534),
    SurahInfo(57, 'Al-Hadid', 'الحديد', 537),
    SurahInfo(58, 'Al-Mujadilah', 'المجادلة', 542),
    SurahInfo(59, 'Al-Hashr', 'الحشر', 545),
    SurahInfo(60, 'Al-Mumtahanah', 'الممتحنة', 549),
    SurahInfo(61, 'As-Saff', 'الصف', 551),
    SurahInfo(62, 'Al-Jumu\'ah', 'الجمعة', 553),
    SurahInfo(63, 'Al-Munafiqun', 'المنافقون', 554),
    SurahInfo(64, 'At-Taghabun', 'التغابن', 556),
    SurahInfo(65, 'At-Talaq', 'الطلاق', 558),
    SurahInfo(66, 'At-Tahrim', 'التحريم', 560),
    SurahInfo(67, 'Al-Mulk', 'الملك', 562),
    SurahInfo(68, 'Al-Qalam', 'القلم', 564),
    SurahInfo(69, 'Al-Haqqah', 'الحاقة', 566),
    SurahInfo(70, 'Al-Ma\'arij', 'المعارج', 568),
    SurahInfo(71, 'Nuh', 'نوح', 570),
    SurahInfo(72, 'Al-Jinn', 'الجن', 572),
    SurahInfo(73, 'Al-Muzzammil', 'المزمل', 574),
    SurahInfo(74, 'Al-Muddaththir', 'المدثر', 575),
    SurahInfo(75, 'Al-Qiyamah', 'القيامة', 577),
    SurahInfo(76, 'Al-Insan', 'الإنسان', 578),
    SurahInfo(77, 'Al-Mursalat', 'المرسلات', 580),
    SurahInfo(78, 'An-Naba', 'النبأ', 582),
    SurahInfo(79, 'An-Nazi\'at', 'النازعات', 583),
    SurahInfo(80, 'Abasa', 'عبس', 585),
    SurahInfo(81, 'At-Takwir', 'التكوير', 586),
    SurahInfo(82, 'Al-Infitar', 'الانفطار', 587),
    SurahInfo(83, 'Al-Mutaffifin', 'المطففين', 587),
    SurahInfo(84, 'Al-Inshiqaq', 'الانشقاق', 589),
    SurahInfo(85, 'Al-Buruj', 'البروج', 590),
    SurahInfo(86, 'At-Tariq', 'الطارق', 591),
    SurahInfo(87, 'Al-A\'la', 'الأعلى', 591),
    SurahInfo(88, 'Al-Ghashiyah', 'الغاشية', 592),
    SurahInfo(89, 'Al-Fajr', 'الفجر', 593),
    SurahInfo(90, 'Al-Balad', 'البلد', 594),
    SurahInfo(91, 'Ash-Shams', 'الشمس', 595),
    SurahInfo(92, 'Al-Layl', 'الليل', 595),
    SurahInfo(93, 'Ad-Duha', 'الضحى', 596),
    SurahInfo(94, 'Ash-Sharh', 'الشرح', 596),
    SurahInfo(95, 'At-Tin', 'التين', 597),
    SurahInfo(96, 'Al-Alaq', 'العلق', 597),
    SurahInfo(97, 'Al-Qadr', 'القدر', 598),
    SurahInfo(98, 'Al-Bayyinah', 'البينة', 598),
    SurahInfo(99, 'Az-Zalzalah', 'الزلزلة', 599),
    SurahInfo(100, 'Al-Adiyat', 'العاديات', 599),
    SurahInfo(101, 'Al-Qari\'ah', 'القارعة', 600),
    SurahInfo(102, 'At-Takathur', 'التكاثر', 600),
    SurahInfo(103, 'Al-Asr', 'العصر', 601),
    SurahInfo(104, 'Al-Humazah', 'الهمزة', 601),
    SurahInfo(105, 'Al-Fil', 'الفيل', 601),
    SurahInfo(106, 'Quraysh', 'قريش', 602),
    SurahInfo(107, 'Al-Ma\'un', 'الماعون', 602),
    SurahInfo(108, 'Al-Kawthar', 'الكوثر', 602),
    SurahInfo(109, 'Al-Kafirun', 'الكافرون', 603),
    SurahInfo(110, 'An-Nasr', 'النصر', 603),
    SurahInfo(111, 'Al-Masad', 'المسد', 603),
    SurahInfo(112, 'Al-Ikhlas', 'الإخلاص', 604),
    SurahInfo(113, 'Al-Falaq', 'الفلق', 604),
    SurahInfo(114, 'An-Nas', 'الناس', 604),
  ];

  static SurahInfo surah(int number) => surahs[(number.clamp(1, 114)) - 1];

  /// First page of the range, i.e. where [startSurah] begins.
  static int startPageOf(int startSurah) => surah(startSurah).startPage;

  /// Last page of a range ending with [endSurah] (inclusive).
  static int endPageOf(int endSurah) {
    if (endSurah >= 114) return totalPages;
    final next = surah(endSurah + 1).startPage;
    // If the next surah starts mid-page, that page is shared; count it once.
    return next > surah(endSurah).startPage ? next - 1 : next;
  }

  /// Number of mushaf pages covered by surahs [startSurah]..[endSurah].
  static int pageCount(int startSurah, int endSurah) {
    if (endSurah < startSurah) return 0;
    return endPageOf(endSurah) - startPageOf(startSurah) + 1;
  }

  /// Relative weight of a surah (in pages) for progress calculation.
  /// Short surahs sharing a page get a small fractional weight.
  static double surahWeight(int number) {
    final start = surah(number).startPage;
    final next = number >= 114 ? totalPages + 1 : surah(number + 1).startPage;
    final span = (next - start).toDouble();
    return span < 0.34 ? 0.34 : span;
  }

  /// Estimated recitation minutes for the given number of pages.
  static int estimatedMinutes(int pages) => (pages * minutesPerPage).round();

  /// The surah being read on [page].
  static SurahInfo surahAtPage(int page) {
    SurahInfo result = surahs.first;
    for (final s in surahs) {
      if (s.startPage <= page) {
        result = s;
      } else {
        break;
      }
    }
    return result;
  }

  /// Splits surahs [startSurah]..[endSurah] into [count] roughly equal
  /// page-based sittings.
  static List<ReadingSitting> splitIntoSittings(
    int startSurah,
    int endSurah, {
    int count = 5,
  }) {
    final first = startPageOf(startSurah);
    final last = endPageOf(endSurah);
    final total = last - first + 1;
    if (total <= 0) return const [];
    final n = count.clamp(1, total);
    final sittings = <ReadingSitting>[];
    var cursor = first;
    for (var i = 0; i < n; i++) {
      final remainingSittings = n - i;
      final remainingPages = last - cursor + 1;
      final size = (remainingPages / remainingSittings).round().clamp(1, remainingPages);
      final end = i == n - 1 ? last : cursor + size - 1;
      final surahAtStart = cursor == first ? surah(startSurah) : surahAtPage(cursor);
      sittings.add(ReadingSitting(
        index: i,
        startPage: cursor,
        endPage: end,
        startSurah: surahAtStart,
      ));
      cursor = end + 1;
    }
    return sittings;
  }
}
