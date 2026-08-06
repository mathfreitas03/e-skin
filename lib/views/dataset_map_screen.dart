import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/controllers/iz_controller.dart';
import 'package:eprobe/models/dataset.dart';
import 'package:eprobe/models/dataset_point.dart';
import 'package:eprobe/models/measurement_point.dart';
import 'package:eprobe/repositories/dataset_repository.dart';
import 'graph_view_screen.dart';
import 'stats_screen.dart';

class DatasetMapScreen extends ConsumerStatefulWidget {
  final DataSet dataset;
  final MeasurementPoint? pendingMeasurement;

  const DatasetMapScreen({
    super.key,
    required this.dataset,
    this.pendingMeasurement,
  });

  @override
  ConsumerState<DatasetMapScreen> createState() => _DatasetMapScreenState();
}

class _DatasetMapScreenState extends ConsumerState<DatasetMapScreen> {
  final DatasetRepository _repository = DatasetRepository();
  bool get _isSavingMode => widget.pendingMeasurement != null;

  void _handleImageTap(TapUpDetails details, double finalWidth, double finalHeight) {
    if (!_isSavingMode) return;

    final double relativeX = double.parse((details.localPosition.dx / finalWidth).toStringAsFixed(3));
    final double relativeY = double.parse((details.localPosition.dy / finalHeight).toStringAsFixed(3));

    _showNamePointDialog(relativeX, relativeY);
  }

  void _showNamePointDialog(double x, double y) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(LanguageHandler().translate('name_measurement_point')),
        content: TextField(controller: nameController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(LanguageHandler().translate('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final label = nameController.text.trim();
              if (label.isEmpty) return;

              await _repository.saveMeasurementPoint(
                datasetId: widget.dataset.id,
                label: label,
                x: x,
                y: y,
                measurement: widget.pendingMeasurement!,
              );

              // Atualiza o estado via Riverpod
              await ref.read(datasetProvider.notifier).loadCurrentSessionDatasets();

              if (mounted) {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Mapa
                Navigator.pop(context); // Gráfico

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${LanguageHandler().translate('measurement_save_successfull')} '$label'!")),
                );
              }
            },
            child: Text(LanguageHandler().translate('save')),
          ),
        ],
      ),
    );
  }

  void _deletePointDialog(DatasetPoint point) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LanguageHandler().translate('remove_point')),
        content: Text("${LanguageHandler().translate('confirm_delete')} '${point.label}' ${LanguageHandler().translate('and_measurements')}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(LanguageHandler().translate('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _repository.deletePoint(point.id);
              
              // Atualiza o estado via Riverpod
              await ref.read(datasetProvider.notifier).loadCurrentSessionDatasets();

              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  widget.dataset.points.removeWhere((p) => p.id == point.id);
                });
              }
            },
            child: Text(LanguageHandler().translate('delete')),
          ),
        ],
      ),
    );
  }

  void _openMeasurement(BuildContext context, DatasetPoint point, MeasurementPoint measurement) {
    final iz = IzController();
    iz.real = List.from(measurement.real);
    iz.imag = List.from(measurement.imag);
    iz.freq = List.from(measurement.freq);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text("${widget.dataset.name} - ${point.label}")),
          body: GraphViewScreen(
            title: "${widget.dataset.name} - ${point.label}",
            iz: iz,
            xAxis: 'logarithmic',
            historyMode: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double imageAspectRatio = 16 / 10;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSavingMode ? LanguageHandler().translate('tap_image_save') : widget.dataset.name),
        backgroundColor: _isSavingMode ? Colors.blue[700] : null,
        foregroundColor: _isSavingMode ? Colors.white : null,
      ),
      body: Column(
        children: [
          if (_isSavingMode)
            Container(
              color: Colors.orange[100],
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Text(
                LanguageHandler().translate("recording_mode_save_measurement"),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double finalWidth = constraints.maxWidth;
                  double finalHeight = constraints.maxWidth / imageAspectRatio;

                  if (finalHeight > constraints.maxHeight) {
                    finalHeight = constraints.maxHeight;
                    finalWidth = constraints.maxHeight * imageAspectRatio;
                  }

                  return Container(
                    width: finalWidth,
                    height: finalHeight,
                    color: Colors.black12,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) => _handleImageTap(details, finalWidth, finalHeight),
                            child: widget.dataset.imagePath.startsWith('assets/')
                                ? Image.asset(widget.dataset.imagePath, fit: BoxFit.fill)
                                : Image.file(
                                    File(widget.dataset.imagePath),
                                    fit: BoxFit.fill,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, size: 50),
                                    ),
                                  ),
                          ),
                        ),
                        ...widget.dataset.points.map((point) {
                          const double markerSize = 34.0;
                          return Positioned(
                            left: (finalWidth * point.x) - (markerSize / 2),
                            top: (finalHeight * point.y) - (markerSize / 2),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_isSavingMode || point.measurements.isEmpty) return;
                                _openMeasurement(context, point, point.measurements.first);
                              },
                              onLongPress: () {
                                if (_isSavingMode) return;
                                _deletePointDialog(point);
                              },
                              child: Container(
                                width: markerSize,
                                height: markerSize,
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
                                    ),
                                    child: const Icon(Icons.circle, size: 8, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}