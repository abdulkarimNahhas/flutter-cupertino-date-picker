import 'package:flutter/material.dart';
import 'date_picker_theme.dart';
import 'date_time_formats_collection.dart';
import 'date_time_formatter.dart';
import 'i18n/date_picker_i18n.dart';
import 'widget/datetime_picker_widget.dart';

enum DateTimePickerMode {
  /// Display DatePicker
  date,

  /// Display TimePicker
  time,

  /// Display DateTimePicker
  datetime,

  /// Display month year Picker
  monthYear,

  /// Display month Picker
  month,

  /// Display year Picker
  year,
}

/// Selected value of DatePicker.
typedef DateValueCallback = Function(DateTime dateTime, List<int> selectedIndex);

/// Pressed cancel callback.
typedef DateVoidCallback = Function();

///
/// author: Dylan Wu
/// since: 2018/06/21
class DatePicker {
  /// Display date picker in bottom sheet.
  ///
  /// context: [BuildContext]
  /// minDateTime: [DateTime] minimum date time
  /// maxDateTime: [DateTime] maximum date time
  /// initialDateTime: [DateTime] initial date time for selected
  /// dateFormat: [String] date format pattern
  /// locale: [DateTimePickerLocale] internationalization
  /// pickerMode: [DateTimePickerMode] display mode: date(DatePicker)、time(TimePicker)、datetime(DateTimePicker)
  /// pickerTheme: [DateTimePickerTheme] the theme of date time picker
  /// onCancel: [DateVoidCallback] pressed title cancel widget event
  /// onClose: [DateVoidCallback] date picker closed event
  /// onChange: [DateValueCallback] selected date time changed event
  /// onConfirm: [DateValueCallback] pressed title confirm widget event
  static void showDatePicker(BuildContext context,
      {DateTime? minDateTime,
      DateTime? maxDateTime,
      DateTime? initialDateTime,
      String? dateFormat,
      DateTimePickerLocale locale = DATETIME_PICKER_LOCALE_DEFAULT,
      DateTimePickerMode pickerMode = DateTimePickerMode.date,
      DateTimePickerTheme pickerTheme = DateTimePickerTheme.Default,
      DateVoidCallback? onCancel,
      DateVoidCallback? onClose,
      DateValueCallback? onChange,
      DateValueCallback? onConfirm,
      required bool isTablet,
      int minuteDivider = 1,
      bool onMonthChangeStartWithFirstDate = false,
      required DateTime Function() nowTimeGetter,
      required DateTimeFormatsCollection dateTimeFormatsCollection,
      required Widget Function(VoidCallback onSaveTextPressed, VoidCallback onCancelTextPressed)
          titleWidgetBuilder}) {
    // handle the range of datetime
    minDateTime ??= DateTime.parse("1900 01 01 00:00:00");
    maxDateTime ??= DateTime.parse("2100 12 31 23:59:59");

    // handle initial DateTime
    initialDateTime ??= nowTimeGetter();

    // Set value of date format
    if (dateFormat != null && dateFormat.isNotEmpty) {
      // Check whether date format is legal or not
      if (DateTimeFormatter.isDayFormat(dateFormat)) {
        if (pickerMode == DateTimePickerMode.time) {
          pickerMode = DateTimeFormatter.isTimeFormat(dateFormat)
              ? DateTimePickerMode.datetime
              : DateTimePickerMode.date;
        }
      } else {
        if (pickerMode == DateTimePickerMode.date || pickerMode == DateTimePickerMode.datetime) {
          pickerMode = DateTimePickerMode.time;
        }
      }
    } else {
      dateFormat = DateTimeFormatter(dateTimeFormatsCollection).generateDateFormat(pickerMode);
    }

    Navigator.push(
      context,
      _DatePickerRoute(
        onMonthChangeStartWithFirstDate: onMonthChangeStartWithFirstDate,
        minDateTime: minDateTime,
        maxDateTime: maxDateTime,
        initialDateTime: initialDateTime,
        dateFormat: dateFormat,
        locale: locale,
        pickerMode: pickerMode,
        pickerTheme: pickerTheme,
        onCancel: onCancel,
        onChange: onChange,
        onConfirm: onConfirm,
        isTablet: isTablet,
        theme: Theme.of(context),
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        minuteDivider: minuteDivider,
        formats: dateTimeFormatsCollection,
        nowTimeGetter: nowTimeGetter,
        titleWidgetBuilder: titleWidgetBuilder,
      ),
    ).whenComplete(onClose ?? () => {});
  }
}

class _DatePickerRoute<T> extends PopupRoute<T> {
  _DatePickerRoute({
    required this.onMonthChangeStartWithFirstDate,
    this.minDateTime,
    this.maxDateTime,
    this.initialDateTime,
    required this.dateFormat,
    required this.locale,
    required this.pickerMode,
    required this.pickerTheme,
    required this.isTablet,
    this.onCancel,
    this.onChange,
    this.onConfirm,
    required this.theme,
    this.barrierLabel,
    required this.minuteDivider,
    required this.nowTimeGetter,
    required this.formats,
    required this.titleWidgetBuilder,
    RouteSettings? settings,
  }) : super(settings: settings);

  final DateTime? minDateTime, maxDateTime, initialDateTime;
  final String dateFormat;
  final DateTimePickerLocale locale;
  final DateTimePickerMode pickerMode;
  final DateTimePickerTheme pickerTheme;
  final VoidCallback? onCancel;
  final DateValueCallback? onChange;
  final DateValueCallback? onConfirm;
  final int minuteDivider;
  final bool onMonthChangeStartWithFirstDate;
  final bool isTablet;
  final DateTimeFormatsCollection formats;
  final DateTime Function() nowTimeGetter;
  final Widget Function(VoidCallback onSaveTextPressed, VoidCallback onCancelPressed)
      titleWidgetBuilder;

  final ThemeData theme;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get barrierDismissible => true;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    assert(navigator?.overlay != null);
    _animationController = BottomSheet.createAnimationController(navigator!.overlay!);
    return _animationController!;
  }

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    double height = pickerTheme.pickerHeight;
    if (pickerTheme.title != null || pickerTheme.showTitle) {
      height += pickerTheme.titleHeight;
    }

    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _DatePickerComponent(
        route: this,
        pickerHeight: height,
        isTablet: isTablet,
        formats: formats,
        nowTimeGetter: nowTimeGetter,
        titleWidgetBuilder: titleWidgetBuilder,
      ),
    );

    bottomSheet = Theme(data: theme, child: bottomSheet);
    return bottomSheet;
  }
}

class _DatePickerComponent extends StatelessWidget {
  final _DatePickerRoute route;
  final double pickerHeight;
  final bool isTablet;
  final DateTimeFormatsCollection formats;
  final DateTime Function() nowTimeGetter;
  final Widget Function(VoidCallback onSaveTextPressed, VoidCallback onCancelPressed)
      titleWidgetBuilder;

  const _DatePickerComponent(
      {Key? key,
      required this.route,
      required this.pickerHeight,
      required this.isTablet,
      required this.formats,
      required this.nowTimeGetter,
      required this.titleWidgetBuilder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget pickerWidget = _buildPickerWidget();

    return AnimatedBuilder(
      animation: route.animation!,
      builder: (BuildContext context, Widget? child) {
        if (isTablet) {
          // Render as centered dialog for tablet
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: pickerHeight,
              child: pickerWidget,
            ),
          );
        } else {
          return CustomSingleChildLayout(
            delegate: _BottomPickerLayout(route.animation!.value, contentHeight: pickerHeight),
            child: pickerWidget,
          );
        }
      },
    );
  }

  Widget _buildPickerWidget() {
    switch (route.pickerMode) {
      case DateTimePickerMode.date:
      case DateTimePickerMode.time:
      case DateTimePickerMode.datetime:
      case DateTimePickerMode.year:
      case DateTimePickerMode.monthYear:
      case DateTimePickerMode.month:
        return DateTimePickerWidget(
          minDateTime: route.minDateTime,
          maxDateTime: route.maxDateTime,
          initDateTime: route.initialDateTime,
          dateFormat: route.dateFormat,
          locale: route.locale,
          pickerTheme: route.pickerTheme,
          onCancel: route.onCancel,
          onChange: route.onChange,
          onConfirm: route.onConfirm,
          minuteDivider: route.minuteDivider,
          onMonthChangeStartWithFirstDate: route.onMonthChangeStartWithFirstDate,
          isTablet: isTablet,
          formats: formats,
          nowTimeGetter: nowTimeGetter,
          titleWidgetBuilder: titleWidgetBuilder,
        );
      default:
        return Container(); // or some default empty widget
    }
  }
}

class _BottomPickerLayout extends SingleChildLayoutDelegate {
  _BottomPickerLayout(this.progress, {required this.contentHeight});

  final double progress;
  final double contentHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: contentHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double height = size.height - childSize.height * progress;
    return Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_BottomPickerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
