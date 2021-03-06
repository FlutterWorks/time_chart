import 'dart:math';

import 'package:flutter/material.dart';
import '../../cand_touchable/touchable.dart';
//import 'package:touchable/touchable.dart';
import '../../utils/time_assistant.dart' as TimeAssistant;
import '../../view_mode.dart';
import '../chart_engine.dart';

class AmountBarPainter extends ChartEngine {

  AmountBarPainter({
    ScrollController scrollController,
    @required this.tooltipCallback,
    @required this.context,
    @required this.sleepData,
    @required this.topHour,
    @required this.bottomHour,
    @required int dayCount,
    @required ViewMode viewMode,
    @required this.inFadeAnimating,
    this.barColor,
  }) :  assert(tooltipCallback != null),
        assert(context != null),
        assert(sleepData != null),
        super(
        scrollController: scrollController,
        dayCount: dayCount,
        viewMode: viewMode,
        firstValueDateTime: sleepData.first.end,
        context: context,
      );

  final TooltipCallback tooltipCallback;
  final BuildContext context;
  final Color barColor;
  final List<DateTimeRange> sleepData;
  final int topHour;
  final int bottomHour;
  /// FadeIn animation 도중에는 보이는 칸만 그리기 위해 이용하는 변수이다.
  final bool inFadeAnimating;

  @override
  void drawBar(Canvas canvas, Size size, List<dynamic> coordinates) {
    final touchyCanvas = TouchyCanvas(
        context, canvas,
        scrollController: scrollController,
        scrollDirection: AxisDirection.left);
    final paint = Paint()
      ..color = barColor ?? Theme.of(context).accentColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int index = 0; index < coordinates.length; index++) {
      final OffsetWithAmountDate offsetWithAmount = coordinates[index];

      final double left = paddingForAlignedBar + offsetWithAmount.dx;
      final double right = paddingForAlignedBar + offsetWithAmount.dx + barWidth;
      final double top = offsetWithAmount.dy;
      final double bottom = size.height;

      final rRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, right, bottom),
        topLeft: barRadius,
        topRight: barRadius,
      );

      final callback = (_) => tooltipCallback(
        amount: offsetWithAmount.amount,
        amountDate: offsetWithAmount.dateTime,
        position: scrollController.position,
        rect: rRect.outerRect,
        barWidth: barWidth,
      );

      touchyCanvas.drawRRect(rRect, paint,
        onTapUp: callback,
        onLongPressStart: callback,
        onLongPressMoveUpdate: callback,
      );
    }
    //if(bottomHour > 0) {
    //  _drawBrokeBarLine(canvas, size);
    //}
  }

  @deprecated
  void drawBrokeBarLine(Canvas canvas, Size size) {
    double strokeWidth;
    switch(viewMode) {
      case ViewMode.weekly: strokeWidth = 8.0; break;
      case ViewMode.monthly: strokeWidth = 4.0;
    }

    final Paint paint = Paint()
      ..color = Theme.of(context).backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = strokeWidth;
    final Path path = Path();
    final double interval = size.width / 7;
    final timeDiff = 2*(topHour - bottomHour);
    final double posY = size.height * (timeDiff - 1) / timeDiff;
    double posX = 0;

    for(int i=0;i<kWeeklyDayCount;++i) {
      path.moveTo(posX, posY);

      path.quadraticBezierTo(
          posX + interval/4, posY - 8,
          posX + interval/2, posY);
      path.quadraticBezierTo(
          posX + (3*interval)/4, posY + 8,
          posX + interval, posY);
      canvas.drawPath(path, paint);

      posX += interval;
    }
  }

  @override
  List<OffsetWithAmountDate> generateCoordinates(Size size) {
    List<OffsetWithAmountDate> coordinates = [];

    final double intervalOfBars = size.width / dayCount;
    final int length = sleepData.length;
    final limitDay = getViewModeLimitDay(viewMode);
    int xIndexCounter = 1;
    double amountSum = 0;

    for (var index = 0; index < length; index++) {
      amountSum += TimeAssistant.durationHour(sleepData[index]);

      // [labels]가 다르면 오른쪽으로 한 칸 이동하여 그린다. 그 외에는 계속 sum 한다.
      if(index == length - 1
          || sleepData[index].end.day != sleepData[index+1].end.day) {

        final double normalizedTop =
            max(0, amountSum - bottomHour) / (topHour - bottomHour);

        final double dy = size.height - normalizedTop * size.height;
        final double dx = size.width - intervalOfBars*xIndexCounter;

        coordinates.add(OffsetWithAmountDate(dx, dy, amountSum, sleepData[index].end));

        amountSum = 0;
        if (limitDay < ++xIndexCounter - 1 && inFadeAnimating) break;
      }
    }

    return coordinates;
  }

  @override
  bool shouldRepaint(AmountBarPainter old) {
    return old.sleepData != sleepData || old.inFadeAnimating != inFadeAnimating;
  }

  @override
  void drawYLabels(Canvas canvas, Size size) {}
}