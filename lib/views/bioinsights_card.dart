import 'dart:math';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/models/chard_data.dart' show ChartData;
import 'package:flutter/material.dart';

class BioinsightsCard extends StatefulWidget {
  final List<ChartData> realData; // Dados Reais (Resistência - R)
  final List<ChartData> imaginaryData; // Dados Imaginários (Reatância - Xc)

  const BioinsightsCard({
    super.key,
    required this.realData,
    required this.imaginaryData,
  });

  @override
  State<BioinsightsCard> createState() => _BioInsightsCardState();
}

class _BioInsightsCardState extends State<BioinsightsCard> {
  final TextEditingController _freqController = TextEditingController();
  ChartData? _selectedReal;
  ChartData? _selectedImaginary;
  double? _phaseAngle;
  double? _magnitude;

  @override
  void dispose() {
    _freqController.dispose();
    super.dispose();
  }

  void _searchFrequency(String value) {
    final targetFreq = double.tryParse(value);
    if (targetFreq == null || widget.realData.isEmpty) {
      setState(() {
        _selectedReal = null;
        _selectedImaginary = null;
        _phaseAngle = null;
        _magnitude = null;
      });
      return;
    }

    ChartData closestReal = widget.realData.reduce((a, b) =>
        (a.x - targetFreq).abs() < (b.x - targetFreq).abs() ? a : b);

    ChartData closestImag = widget.imaginaryData.firstWhere(
      (element) => element.x == closestReal.x,
      orElse: () => widget.imaginaryData.reduce((a, b) =>
          (a.x - targetFreq).abs() < (b.x - targetFreq).abs() ? a : b),
    );

    double r = closestReal.y;
    double xc = closestImag.y.abs();

    double phaseAngle = (r != 0) ? (atan(xc / r) * (180 / pi)) : 0.0;
    double magnitude = sqrt((r * r) + (xc * xc));

    setState(() {
      _selectedReal = closestReal;
      _selectedImaginary = closestImag;
      _phaseAngle = phaseAngle;
      _magnitude = magnitude;
    });
  }

  ChartData? _getPeakReactancePoint() {
    if (widget.imaginaryData.isEmpty) return null;
    return widget.imaginaryData.reduce((a, b) => a.y.abs() > b.y.abs() ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.realData.isEmpty) {
      return const SizedBox.shrink();
    }

    final peakXc = _getPeakReactancePoint();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _freqController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: LanguageHandler().translate('frequency'),
                        hintText: "Hz",
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.search, size: 20),
                      ),
                      onChanged: _searchFrequency,
                    ),
                  ),
                ),
                if (peakXc != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      "fc: ${(peakXc.x / 1000).toStringAsFixed(1)} kHz",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ],
              ],
            ),

            if (_selectedReal != null && _selectedImaginary != null) ...[
              const SizedBox(height: 12),
              Text(
                "${_selectedReal!.x.toStringAsFixed(0)} Hz",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricTile(
                    "R",
                    "${_selectedReal!.y.toStringAsFixed(1)} Ω",
                  ),
                  _buildMetricTile(
                    "Xc",
                    "${_selectedImaginary!.y.abs().toStringAsFixed(1)} Ω",
                  ),
                  _buildMetricTile(
                    "|Z|",
                    "${_magnitude?.toStringAsFixed(1)} Ω",
                  ),
                  _buildMetricTile(
                    "ϕ",
                    "${_phaseAngle?.toStringAsFixed(2)}°",
                    isHighlight: true,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.blue.shade800 : Colors.black87,
          ),
        ),
      ],
    );
  }
}