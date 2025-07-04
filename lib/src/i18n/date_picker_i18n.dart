import 'dart:math';

part 'strings_ar.dart';
part 'strings_ar_eg.dart';
part 'strings_bn.dart';
part 'strings_bs.dart';
part 'strings_cs.dart';
part 'strings_de.dart';
part 'strings_en_us.dart';
part 'strings_es.dart';
part 'strings_fr.dart';
part 'strings_hr.dart';
part 'strings_hu.dart';
part 'strings_id.dart';
part 'strings_it.dart';
part 'strings_jp.dart';
part 'strings_ko.dart';
part 'strings_nl.dart';
part 'strings_pt_br.dart';
part 'strings_ro.dart';
part 'strings_ru.dart';
part 'strings_sr_cyr.dart';
part 'strings_sr_lat.dart';
part 'strings_tr.dart';
part 'strings_uk.dart';
part 'strings_vi.dart';
part 'strings_zh_cn.dart';

abstract class _StringsI18n {
  const _StringsI18n();

  /// Get the done widget text
  String getDoneText();

  /// Get the cancel widget text
  String getCancelText();

  /// Get the name of month
  List<String> getMonths();

  /// Get the short name of month
  List<String>? getMonthsShort();

  /// Get the full name of week
  List<String> getWeeksFull();

  /// Get the short name of week
  List<String>? getWeeksShort();

  List<String>? get12hours();
}

enum DateTimePickerLocale {
  /// English (EN) United States
  en_us,

  /// Chinese (ZH) Simplified
  zh_cn,

  /// Portuguese (PT) Brazil
  pt_br,

  /// Indonesia (ID)
  id,

  /// Spanish (ES)
  es,

  /// Turkish (TR)
  tr,

  /// French (FR)
  fr,

  /// Romanian (RO)
  ro,

  /// Bengali (BN)
  bn,

  /// Bosnian (BS)
  bs,

  /// Arabic (ar)
  ar,

  /// Arabic (ar) Egypt
  ar_eg,

  /// Japanese (JP)
  jp,

  /// Russian (RU)
  ru,

  /// German (DE)
  de,

  /// Czech (CS)
  cs,

  /// Korea (KO)
  ko,

  /// Italian (IT)
  it,

  /// Hungarian (HU)
  hu,

  /// Croatian (HR)
  hr,

  /// Ukrainian (UK)
  uk,

  /// Vietnamese (VN)
  vi,

  /// Serbia (sr) Cyrillic
  sr_cyrl,

  /// Serbia (sr) Latin
  sr_latn,

  /// Dutch (NL)
  nl,
}

/// Default value of date locale
const DateTimePickerLocale DATETIME_PICKER_LOCALE_DEFAULT = DateTimePickerLocale.en_us;

const Map<DateTimePickerLocale, _StringsI18n> datePickerI18n = {
  DateTimePickerLocale.en_us: _StringsEnUs(),
  DateTimePickerLocale.zh_cn: _StringsZhCn(),
  DateTimePickerLocale.pt_br: _StringsPtBr(),
  DateTimePickerLocale.id: _StringsId(),
  DateTimePickerLocale.ar: _StringsAr(),
  DateTimePickerLocale.ar_eg: _StringsArEg(),
  DateTimePickerLocale.es: _StringsEs(),
  DateTimePickerLocale.fr: _StringsFr(),
  DateTimePickerLocale.ro: _StringsRo(),
  DateTimePickerLocale.bn: _StringsBn(),
  DateTimePickerLocale.bs: _StringsBs(),
  DateTimePickerLocale.jp: _StringsJp(),
  DateTimePickerLocale.ru: _StringsRu(),
  DateTimePickerLocale.de: _StringsDe(),
  DateTimePickerLocale.cs: _StringsCs(),
  DateTimePickerLocale.ko: _StringsKo(),
  DateTimePickerLocale.it: _StringsIt(),
  DateTimePickerLocale.hu: _StringsHu(),
  DateTimePickerLocale.hr: _StringsHr(),
  DateTimePickerLocale.uk: _StringsUk(),
  DateTimePickerLocale.tr: _StringsTr(),
  DateTimePickerLocale.vi: _StringsVn(),
  DateTimePickerLocale.sr_cyrl: _StringsSrCyrillic(),
  DateTimePickerLocale.sr_latn: _StringsSrLatin(),
  DateTimePickerLocale.nl: _StringsNl(),
};

class DatePickerI18n {
  /// Get done button text
  static String getLocaleDone(DateTimePickerLocale locale) {
    _StringsI18n i18n = datePickerI18n[locale] ?? datePickerI18n[DATETIME_PICKER_LOCALE_DEFAULT]!;
    return i18n.getDoneText();
  }

  /// Get cancel button text
  static String getLocaleCancel(DateTimePickerLocale locale) {
    _StringsI18n i18n = datePickerI18n[locale] ?? datePickerI18n[DATETIME_PICKER_LOCALE_DEFAULT]!;
    return i18n.getCancelText();
  }

  /// Get locale month array
  static List<String>? getLocaleMonths(DateTimePickerLocale locale, [bool isFull = true]) {
    _StringsI18n i18n = datePickerI18n[locale] ?? datePickerI18n[DATETIME_PICKER_LOCALE_DEFAULT]!;

    if (isFull) {
      List<String> months = i18n.getMonths();
      return months;
    }

    List<String>? months = i18n.getMonthsShort();
    if (months != null && months.isNotEmpty && months.length == 12) {
      return months;
    }
    return i18n.getMonthsShort();
  }

  /// Get locale week array
  static List<String>? getLocaleWeeks(DateTimePickerLocale locale, [bool isFull = true]) {
    _StringsI18n i18n = datePickerI18n[locale] ?? datePickerI18n[DATETIME_PICKER_LOCALE_DEFAULT]!;
    if (isFull) {
      List<String> weeks = i18n.getWeeksFull();
      return weeks;
    }

    List<String>? weeks = i18n.getWeeksShort();
    if (weeks != null && weeks.isNotEmpty) {
      return weeks;
    }

    List<String> fullWeeks = i18n.getWeeksFull();
    return fullWeeks.map((item) => item.substring(0, min(3, item.length))).toList();
  }
}
