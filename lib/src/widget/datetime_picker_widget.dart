import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_cupertino_date_picker/src/date_time_formats_collection.dart';
import '../date_picker_theme.dart';
import '../date_time_formatter.dart';
import '../i18n/date_picker_i18n.dart';

const List<int> solarMonthsOf31Days = <int>[1, 3, 5, 7, 8, 10, 12];

/// DateTimePicker widget. Can display date and time picker.
class DateTimePickerWidget extends StatefulWidget {
  DateTimePickerWidget({
    Key? key,
    this.minDateTime,
    this.maxDateTime,
    this.initDateTime,
    required this.dateFormat,
    required this.isTablet,
    this.dateFormatSeparator = DATE_FORMAT_SEPARATOR,
    this.locale = DATETIME_PICKER_LOCALE_DEFAULT,
    this.pickerTheme = DateTimePickerTheme.Default,
    this.minuteDivider = 1,
    this.onCancel,
    this.onChange,
    this.onConfirm,
    required this.nowTimeGetter,
    this.onMonthChangeStartWithFirstDate = false,
    required this.titleWidgetBuilder,
    required this.formats,
  }) : super(key: key) {
    DateTime minTime = minDateTime ?? DateTime.parse("1900 01 01 00:00:00");
    DateTime maxTime = maxDateTime ?? DateTime.parse("2100 12 31 23:59:59");
    assert(minTime.compareTo(maxTime) < 0);
  }

  final DateTime? minDateTime, maxDateTime, initDateTime;
  final String dateFormat;
  final String dateFormatSeparator;
  final DateTimePickerLocale locale;
  final DateTimePickerTheme pickerTheme;
  final DateVoidCallback? onCancel;
  final DateValueCallback? onChange, onConfirm;
  final int minuteDivider;
  final bool onMonthChangeStartWithFirstDate;
  final DateTime Function() nowTimeGetter;
  final bool isTablet;
  final Widget Function(VoidCallback onSaveTextPressed, VoidCallback onCancelPressed)
      titleWidgetBuilder;
  final DateTimeFormatsCollection formats;

  @override
  State<StatefulWidget> createState() =>
      _DateTimePickerWidgetState(minDateTime, maxDateTime, initDateTime, minuteDivider);
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  late DateTime _minTime, _maxTime;
  late int _currYear, _currMonth, _currDay, _currHour, _currMinute, _curr12hours;
  late int _minuteDivider;
  late List<int> _yearRange, _monthRange, _dayRange, _hourRange, _minuteRange, _12hoursRange;
  late FixedExtentScrollController _yearScrollCtrl,
      _monthScrollCtrl,
      _dayScrollCtrl,
      _hourScrollCtrl,
      _minuteScrollCtrl,
      _12hourScrollCtrl;

  late Map<String, FixedExtentScrollController> _scrollCtrlMap;
  late Map<String, List<int>> _valueRangeMap;

  bool _isChangeTimeRange = false;

  _DateTimePickerWidgetState(
      DateTime? minTime, DateTime? maxTime, DateTime? initTime, int minuteDivider) {
    // check minTime value
    minTime ??= DateTime.parse("1900 01 01 00:00:00");
    // check maxTime value
    maxTime ??= DateTime.parse("2100 12 31 23:59:59");
    // check initTime value
    initTime ??= widget.nowTimeGetter();
    // limit initTime value
    if (initTime.compareTo(minTime) < 0) {
      initTime = minTime;
    }
    if (initTime.compareTo(maxTime) > 0) {
      initTime = maxTime;
    }

    _minTime = minTime;
    _maxTime = maxTime;
    _currYear = initTime.year;
    _currMonth = initTime.month;
    _currDay = initTime.day;
    _currHour = initTime.hour >= 12 ? initTime.hour - 12 : initTime.hour;
    _currMinute = initTime.minute;
    _curr12hours = initTime.hour >= 12 ? 1 : 0;

    _minuteDivider = minuteDivider;

    // limit the range of year
    _yearRange = _calcYearRange();
    _currYear = min(max(_minTime.year, _currYear), _maxTime.year);
    // limit the range of month
    _monthRange = _calcMonthRange();
    _currMonth = min(max(_monthRange.first, _currMonth), _monthRange.last);
    // limit the range of date
    _dayRange = _calcDayRange();
    _currDay = min(max(_dayRange.first, _currDay), _dayRange.last);

    // limit the range of hour
    _hourRange = _calcHourRange();
    _currHour = min(max(_hourRange.first, _currHour), _hourRange.last);

    // limit the range of minute
    _minuteRange = _calcMinuteRange();
    _currMinute = min(max(_minuteRange.first, _currMinute), _minuteRange.last);

    // limit the range of second
    _12hoursRange = _calc12hourRange();
    _curr12hours = min(max(_12hoursRange.first, _curr12hours), _12hoursRange.last);

    // create scroll controller
    _yearScrollCtrl = FixedExtentScrollController(initialItem: _currYear - _yearRange.first);
    _monthScrollCtrl = FixedExtentScrollController(initialItem: _currMonth - _monthRange.first);
    _dayScrollCtrl = FixedExtentScrollController(initialItem: _currDay - _dayRange.first);
    _hourScrollCtrl = FixedExtentScrollController(initialItem: _currHour - _hourRange.first);
    _minuteScrollCtrl = FixedExtentScrollController(
        initialItem: (_currMinute - _minuteRange.first) ~/ _minuteDivider);
    _12hourScrollCtrl =
        FixedExtentScrollController(initialItem: _curr12hours - _12hoursRange.first);

    _scrollCtrlMap = {
      'y': _yearScrollCtrl,
      'M': _monthScrollCtrl,
      'd': _dayScrollCtrl,
      'H': _hourScrollCtrl,
      'm': _minuteScrollCtrl,
      'a': _12hourScrollCtrl
    };
    _valueRangeMap = {
      'y': _yearRange,
      'M': _monthRange,
      'd': _dayRange,
      'H': _hourRange,
      'm': _minuteRange,
      'a': _12hoursRange
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Material(color: Colors.transparent, child: _renderPickerView(context, widget.formats)),
    );
  }

  /// render time picker widgets
  Widget _renderPickerView(BuildContext context, DateTimeFormatsCollection formats) {
    Widget pickerWidget = _renderDatePickerWidget(formats);

    // display the title widget
    if (widget.pickerTheme.title != null || widget.pickerTheme.showTitle) {
      Widget titleWidget = widget.titleWidgetBuilder(
        () => _onPressedConfirm(),
        () => Navigator.of(context).pop(),
      );
      return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(32),
            topRight: const Radius.circular(32),
            bottomRight: widget.isTablet ? const Radius.circular(32) : const Radius.circular(0),
            bottomLeft: widget.isTablet ? const Radius.circular(32) : const Radius.circular(0),
          ),
          child: Container(
              color: widget.pickerTheme.backgroundColor,
              child: Column(children: <Widget>[pickerWidget, titleWidget])));
    }
    return pickerWidget;
  }

  /// pressed confirm widget
  void _onPressedConfirm() {
    if (widget.onConfirm != null) {
      if (_curr12hours == 1) {
        _currHour = _currHour + 12;
      }
      DateTime dateTime = DateTime(_currYear, _currMonth, _currDay, _currHour, _currMinute);
      widget.onConfirm!(dateTime, _calcSelectIndexList());
    }
    Navigator.of(context).pop();
  }

  /// notify selected datetime changed
  void _onSelectedChange() {
    if (widget.onChange != null) {
      if (_curr12hours == 1) {
        _currHour = _currHour + 12;
      }
      DateTime dateTime = DateTime(_currYear, _currMonth, _currDay, _currHour, _currMinute);
      widget.onChange!(dateTime, _calcSelectIndexList());
    }
  }

  /// find scroll controller by specified format
  FixedExtentScrollController _findScrollCtrl(String format) {
    FixedExtentScrollController? scrollCtrl;
    _scrollCtrlMap.forEach((key, value) {
      if (format.contains(key)) {
        scrollCtrl = value;
      }
    });
    if (scrollCtrl == null) {
      throw Exception('Illegal format $format');
    }
    return scrollCtrl!;
  }

  /// find item value range by specified format
  List<int> _findPickerItemRange(String format) {
    List<int>? valueRange;
    _valueRangeMap.forEach((key, value) {
      if (format.contains(key)) {
        valueRange = value;
      }
    });
    if (valueRange == null) {
      throw Exception('Illegal format $format');
    }
    return valueRange!;
  }

  /// render the picker widget of year、month and day
  Widget _renderDatePickerWidget(DateTimeFormatsCollection formats) {
    List<Widget> pickers = [];
    List<String> formatArr = DateTimeFormatter(formats)
        .splitDateFormat(widget.dateFormat, dateFormatSeparator: widget.dateFormatSeparator);
    for (var format in formatArr) {
      List<int> valueRange = _findPickerItemRange(format);
      Widget pickerColumn = _renderDatePickerColumnComponent(
        scrollCtrl: _findScrollCtrl(format),
        valueRange: valueRange,
        format: format,
        minuteDivider: widget.minuteDivider,
        valueChanged: (value) {
          if (format.contains('y')) {
            _changeYearSelection(value);
          } else if (format.contains('M')) {
            _changeMonthSelection(value);
          } else if (format.contains('d')) {
            _changeDaySelection(value);
          } else if (format.contains('H')) {
            _changeHourSelection(value);
          } else if (format.contains('m')) {
            _changeMinuteSelection(value);
          } else if (format.contains('a')) {
            _change12hoursSelection(value);
          }
        },
      );
      pickers.add(pickerColumn);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: pickers);
  }

  Widget _renderDatePickerColumnComponent({
    required FixedExtentScrollController scrollCtrl,
    required List<int> valueRange,
    required String format,
    required ValueChanged<int> valueChanged,
    required int minuteDivider,
  }) {
    Widget builder(context, int index) {
      int value = valueRange.first + index;

      if (format.contains('m')) {
        value = minuteDivider * index + valueRange.first;
      }
      return _renderDatePickerItemComponent(value, format);
    }

    Widget columnWidget = Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      height: widget.pickerTheme.pickerHeight,
      decoration: BoxDecoration(color: widget.pickerTheme.backgroundColor),
      child: CupertinoPicker.builder(
        backgroundColor: widget.pickerTheme.backgroundColor,
        scrollController: scrollCtrl,
        diameterRatio: 0.9,
        magnification: 1.2,
        squeeze: 1.4,
        selectionOverlay: widget.pickerTheme.selectionOverlay ??
            Container(
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.black26),
                ),
              ),
            ),
        itemExtent: widget.pickerTheme.itemHeight,
        onSelectedItemChanged: valueChanged,
        childCount: format.contains('m')
            ? _calculateMinuteChildCount(valueRange, minuteDivider)
            : valueRange.last - valueRange.first + 1,
        itemBuilder: builder,
      ),
    );
    return Expanded(
      flex: 1,
      child: columnWidget,
    );
  }

  int _calculateMinuteChildCount(List<int> valueRange, int divider) {
    if (divider == 0) {
      debugPrint("Cant devide by 0");
      return (valueRange.last - valueRange.first + 1);
    }

    return (valueRange.last - valueRange.first + 1) ~/ divider;
  }

  /// render hour、minute、second picker item
  Widget _renderDatePickerItemComponent(int value, String format) {
    return Container(
      height: widget.pickerTheme.itemHeight,
      alignment: Alignment.center,
      child: Text(
        DateTimeFormatter.formatDateTime(value, format, widget.locale),
        style: widget.pickerTheme.itemTextStyle,
      ),
    );
  }

  /// change the selection of year picker
  void _changeYearSelection(int index) {
    int year = _yearRange.first + index;
    if (_currYear != year) {
      _currYear = year;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of month picker
  void _changeMonthSelection(int index) {
    int month = _monthRange.first + index;
    if (_currMonth != month) {
      _currMonth = month;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of day picker
  void _changeDaySelection(int index) {
    int dayOfMonth = _dayRange.first + index;
    if (_currDay != dayOfMonth) {
      _currDay = dayOfMonth;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of hour picker
  void _changeHourSelection(int index) {
    int value;
    if (index == 0) {
      value = 12;
    } else {
      value = _hourRange.first + index;
    }
    if (_currHour != value) {
      _currHour = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of minute picker
  void _changeMinuteSelection(int index) {
    int value = _minuteRange.first + index * _minuteDivider;
    if (_currMinute != value) {
      _currMinute = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of second picker
  void _change12hoursSelection(int index) {
    int value = _12hoursRange.first + index;
    if (_curr12hours != value) {
      _curr12hours = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change range of minute and second
  void _changeTimeRange() {
    if (_isChangeTimeRange) {
      return;
    }
    _isChangeTimeRange = true;

    List<int> monthRange = _calcMonthRange();
    bool monthRangeChanged =
        _monthRange.first != monthRange.first || _monthRange.last != monthRange.last;
    if (monthRangeChanged) {
      // selected year changed
      _currMonth = max(min(_currMonth, monthRange.last), monthRange.first);
    }

    List<int> dayRange = _calcDayRange();
    bool dayRangeChanged = _dayRange.first != dayRange.first || _dayRange.last != dayRange.last;
    if (dayRangeChanged) {
      // day range changed, need limit the value of selected day
      if (!widget.onMonthChangeStartWithFirstDate) {
        max(min(_currDay, dayRange.last), dayRange.first);
      } else {
        _currDay = dayRange.first;
      }
    }

    List<int> hourRange = _calcHourRange();
    bool hourRangeChanged =
        _hourRange.first != hourRange.first || _hourRange.last != hourRange.last;
    if (hourRangeChanged) {
      // selected day changed
      _currHour = max(min(_currHour, hourRange.last), hourRange.first);
    }

    List<int> minuteRange = _calcMinuteRange();
    bool minuteRangeChanged =
        _minuteRange.first != minuteRange.first || _minuteRange.last != minuteRange.last;
    if (minuteRangeChanged) {
      // selected hour changed
      _currMinute = max(min(_currMinute, minuteRange.last), minuteRange.first);
    }

    List<int> secondRange = _calc12hourRange();
    bool secondRangeChanged =
        _12hoursRange.first != secondRange.first || _12hoursRange.last != secondRange.last;
    if (secondRangeChanged) {
      // second range changed, need limit the value of selected second
      _curr12hours = max(min(_curr12hours, secondRange.last), secondRange.first);
    }

    setState(() {
      _monthRange = monthRange;
      _dayRange = dayRange;
      _hourRange = hourRange;
      _minuteRange = minuteRange;
      _12hoursRange = secondRange;

      _valueRangeMap['M'] = monthRange;
      _valueRangeMap['d'] = dayRange;
      _valueRangeMap['H'] = hourRange;
      _valueRangeMap['m'] = minuteRange;
      _valueRangeMap['a'] = secondRange;
    });

    if (monthRangeChanged) {
      int currMonth = _currMonth;
      _monthScrollCtrl.jumpToItem(monthRange.last - monthRange.first);
      if (currMonth < monthRange.last) {
        _monthScrollCtrl.jumpToItem(currMonth - monthRange.first);
      }
    }

    if (dayRangeChanged) {
      int currDay = _currDay;
      _dayScrollCtrl.jumpToItem(dayRange.last - dayRange.first);
      if (currDay < dayRange.last) {
        _dayScrollCtrl.jumpToItem(currDay - dayRange.first);
      }
    }

    if (hourRangeChanged) {
      int currHour = _currHour;
      _hourScrollCtrl.jumpToItem(hourRange.last - hourRange.first);
      if (currHour < hourRange.last) {
        _hourScrollCtrl.jumpToItem(currHour - hourRange.first);
      }
    }

    if (minuteRangeChanged) {
      int currMinute = _currMinute;
      _minuteScrollCtrl.jumpToItem((minuteRange.last - minuteRange.first) ~/ _minuteDivider);
      if (currMinute < minuteRange.last) {
        _minuteScrollCtrl.jumpToItem(currMinute - minuteRange.first);
      }
    }

    if (secondRangeChanged || hourRangeChanged) {
      int currSecond = _curr12hours;
      _12hourScrollCtrl.jumpToItem(secondRange.last - secondRange.first);
      if (currSecond < secondRange.last) {
        _12hourScrollCtrl.jumpToItem(currSecond - secondRange.first);
      }
    }

    _isChangeTimeRange = false;
  }

  /// calculate the count of day in current month
  int _calcDayCountOfMonth() {
    if (_currMonth == 2) {
      return isLeapYear(_currYear) ? 29 : 28;
    } else if (solarMonthsOf31Days.contains(_currMonth)) {
      return 31;
    }
    return 30;
  }

  /// whether or not is leap year
  bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  /// calculate selected index list
  List<int> _calcSelectIndexList() {
    int yearIndex = _currYear - _minTime.year;
    int monthIndex = _currMonth - _monthRange.first;
    int dayIndex = _currDay - _dayRange.first;
    int hourIndex = _currHour - _hourRange.first;
    int minuteIndex = _currMinute - _minuteRange.first;
    return [yearIndex, monthIndex, dayIndex, hourIndex, minuteIndex];
  }

  /// calculate the range of year
  List<int> _calcYearRange() {
    return [_minTime.year, _maxTime.year];
  }

  /// calculate the range of month
  List<int> _calcMonthRange() {
    int minMonth = 1, maxMonth = 12;
    int minYear = _minTime.year;
    int maxYear = _maxTime.year;
    if (minYear == _currYear) {
      // selected minimum year, limit month range
      minMonth = _minTime.month;
    }
    if (maxYear == _currYear) {
      // selected maximum year, limit month range
      maxMonth = _maxTime.month;
    }
    return [minMonth, maxMonth];
  }

  /// calculate the range of day
  List<int> _calcDayRange({currMonth}) {
    int minDay = 1, maxDay = _calcDayCountOfMonth();
    int minYear = _minTime.year;
    int maxYear = _maxTime.year;
    int minMonth = _minTime.month;
    int maxMonth = _maxTime.month;
    currMonth ??= _currMonth;
    if (minYear == _currYear && minMonth == currMonth) {
      // selected minimum year and month, limit day range
      minDay = _minTime.day;
    }
    if (maxYear == _currYear && maxMonth == currMonth) {
      // selected maximum year and month, limit day range
      maxDay = _maxTime.day;
    }
    return [minDay, maxDay];
  }

  /// calculate the range of hour
  /// in date format when show text we replace 00 with 12
  List<int> _calcHourRange() {
    int minHour = 0, maxHour = 11;
    if (_currYear == _minTime.year && _currMonth == _minTime.month && _currDay == _minTime.day) {
      if (_minTime.hour >= 12) {
        minHour = _minTime.hour - 12;
      } else {
        minHour = _minTime.hour;
      }
    }
    if (_currYear == _maxTime.year && _currMonth == _maxTime.month && _currDay == _maxTime.day) {
      if (_maxTime.hour >= 12) {
        maxHour = _maxTime.hour - 12;
      } else {
        maxHour = _maxTime.hour;
      }
    }
    return [minHour, maxHour];
  }

  /// calculate the range of minute
  List<int> _calcMinuteRange({currHour}) {
    int minMinute = 0, maxMinute = 59;
    currHour ??= _currHour;

    if (_currYear == _minTime.year &&
        _currMonth == _minTime.month &&
        _currDay == _minTime.day &&
        _currHour == _minTime.hour) {
      // selected minimum day、hour, limit minute range
      minMinute = _minTime.minute;
    }
    if (_currYear == _maxTime.year &&
        _currMonth == _maxTime.month &&
        _currDay == _maxTime.day &&
        _currHour == _minTime.hour) {
      // selected maximum day、hour, limit minute range
      maxMinute = _maxTime.minute;
    }
    return [minMinute, maxMinute];
  }

  /// calculate if AM or PM
  List<int> _calc12hourRange({currHour, currMinute}) {
    int minSecond = 0, maxSecond = 1;

    currHour ??= _currHour;
    currMinute ??= _currMinute;
    if (_minTime.hour >= 12) {
      minSecond = 0;
    }
    if (_maxTime.hour <= 12) {
      maxSecond = 1;
    }
    return [minSecond, maxSecond];
  }
}
