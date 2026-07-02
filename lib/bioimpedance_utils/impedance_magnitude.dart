import 'dart:math' as math;

import 'package:eprobe/models/chard_data.dart';

List<ChartData> calcularMagnitude(List<ChartData> realData, List<ChartData> imagData) {
  final List<ChartData> magnitudeData = [];

  // Proteção: usa o tamanho da menor lista para evitar erro de RangeError (index out of bounds)
  final int length = realData.length < imagData.length ? realData.length : imagData.length;

  for (int i = 0; i < length; i++) {
    final double yReal = realData[i].y;
    final double yImag = imagData[i].y;
    final double x = realData[i].x; 

    // Calcula a magnitude entre as componentes Y
    final double magnitudeY = math.sqrt((yReal * yReal) + (yImag * yImag));

    magnitudeData.add(ChartData(x, magnitudeY));
  }

  return magnitudeData;
}