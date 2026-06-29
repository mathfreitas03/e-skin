import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/iz_controller.dart';
import '../models/measurement_session.dart';
import '../models/dataset.dart';
import '../models/measurement_point.dart';
import '../models/measurement_data.dart';

import 'graph_view_screen.dart';

/// NOTIFIER GLOBAL/ESTÁTICO PARA MANTER OS DATASETS VIVOS NA MEMÓRIA
/// Substitua isso pelo seu repositório real ou singleton do banco de dados (Hive/Sqflite), se houver.
final ValueNotifier<List<DataSet>> globalDatasetsNotifier = ValueNotifier<List<DataSet>>([
  DataSet(
    id: "fish_001",
    name: "Tilápia A",
    imagePath: "assets/images/standard_fish.png",
    points: [
      MeasurementPoint(
        id: "head",
        label: "Cabeça",
        x: 0.18,
        y: 0.48,
        measurements: [
          MeasurementData(
            id: "m1",
            timestamp: DateTime.now(),
            real: const [10, 20, 30, 40],
            imag: const [5, 10, 15, 20],
            freq: const [100, 1000, 10000, 100000],
          ),
        ],
      ),
    ],
  ),
]);

class StatsScreen extends StatefulWidget {
  final MeasurementData? currentMeasurementToSave;

  const StatsScreen({
    super.key,
    this.currentMeasurementToSave,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final Set<String> _selectedDatasetIds = <String>{};

  bool get _isSelectionMode => _selectedDatasetIds.isNotEmpty;
  bool get _isSavingFlowMode => widget.currentMeasurementToSave != null;

  @override
  Widget build(BuildContext context) {
    // Escuta reativamente qualquer alteração na lista global de datasets
    return ValueListenableBuilder<List<DataSet>>(
      valueListenable: globalDatasetsNotifier,
      builder: (context, datasets, child) {
        return Scaffold(
          appBar: AppBar(
            leading: _isSelectionMode || _isSavingFlowMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (_isSavingFlowMode) {
                        Navigator.pop(context); // Aborta e volta ao gráfico
                      } else {
                        setState(() => _selectedDatasetIds.clear());
                      }
                    },
                  )
                : null,
            title: Text(
              _isSavingFlowMode
                  ? "Selecione o Dataset Alvo"
                  : _isSelectionMode
                      ? "${_selectedDatasetIds.length} selecionados"
                      : "Medições registradas",
            ),
            backgroundColor: _isSavingFlowMode ? Colors.blue[700] : null,
            foregroundColor: _isSavingFlowMode ? Colors.white : null,
            actions: [
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed: () => _deleteSelectedDatasets(datasets),
                ),
            ],
          ),
          body: Column(
            children: [
              if (_isSavingFlowMode)
                Container(
                  color: Colors.orange[100],
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Clique no dataset dinâmico abaixo para abrir o mapa correspondente e salvar.",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListView.builder(
                    itemCount: datasets.length,
                    itemBuilder: (context, index) {
                      final dataset = datasets[index];
                      final isSelected = _selectedDatasetIds.contains(dataset.id);

                      return Card(
                        elevation: isSelected ? 6 : 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: isSelected
                            ? RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.green, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : _isSavingFlowMode
                                ? RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.orange[300]!, width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                  )
                                : null,
                        color: isSelected ? Colors.green[50] : null,
                        child: ListTile(
                          leading: isSelected
                              ? Container(
                                  width: 60,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.check_circle, color: Colors.green),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildDatasetImage(
                                    dataset.imagePath,
                                    width: 80,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          title: Text(
                            dataset.name,
                            style: TextStyle(
                              fontWeight: isSelected || _isSavingFlowMode ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          // Mostra em tempo real a quantidade de pontos atualizada
                          subtitle: Text("${dataset.points.length} pontos mapeados"),
                          trailing: _isSelectionMode
                              ? null
                              : Icon(
                                  _isSavingFlowMode ? Icons.ads_click : Icons.arrow_forward_ios,
                                  color: _isSavingFlowMode ? Colors.orange[700] : null,
                                ),
                          onTap: () {
                            if (_isSavingFlowMode) {
                              _openDatasetForSaving(dataset, widget.currentMeasurementToSave!);
                            } else if (_isSelectionMode) {
                              _toggleSelection(dataset.id);
                            } else {
                              _openDataset(dataset);
                            }
                          },
                          onLongPress: () {
                            _toggleSelection(dataset.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : FloatingActionButton(
                  backgroundColor: _isSavingFlowMode ? Colors.orange[700] : Colors.green,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  onPressed: () => _createNewDatasetDialog(datasets),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  void _openDatasetForSaving(DataSet dataset, MeasurementData measurement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DatasetMapScreen(
          dataset: dataset,
          pendingMeasurement: measurement,
        ),
      ),
    );
  }

  void _openDataset(DataSet dataset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DatasetMapScreen(dataset: dataset),
      ),
    );
  }

  void _toggleSelection(String id) {
    if (_isSavingFlowMode) return;
    setState(() {
      if (_selectedDatasetIds.contains(id)) {
        _selectedDatasetIds.remove(id);
      } else {
        _selectedDatasetIds.add(id);
      }
    });
  }

  void _deleteSelectedDatasets(List<DataSet> currentList) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Excluir Datasets"),
          content: Text("Tem certeza que deseja excluir ${_selectedDatasetIds.length} dataset(s)?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                // Modifica a lista de referência e notifica os ouvintes da árvore
                final updatedList = List<DataSet>.from(currentList)
                  ..removeWhere((d) => _selectedDatasetIds.contains(d.id));
                globalDatasetsNotifier.value = updatedList;
                
                setState(() => _selectedDatasetIds.clear());
                Navigator.pop(context);
              },
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );
  }

  void _createNewDatasetDialog(List<DataSet> currentList) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String selectedImagePath = "assets/images/standard_fish.png";
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setDialogState(() => selectedImagePath = image.path);
              }
            }

            return AlertDialog(
              title: const Text("Novo Dataset"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Nome do Dataset"),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Insira um nome." : null,
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildDatasetImage(selectedImagePath, width: 150, height: 100, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Selecionar Foto"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newDataset = DataSet(
                        id: "fish_${DateTime.now().millisecondsSinceEpoch}",
                        name: nameController.text.trim(),
                        imagePath: selectedImagePath,
                        points: [],
                      );

                      // Atualiza o ValueNotifier global disparando a renderização dinâmica
                      globalDatasetsNotifier.value = [...currentList, newDataset];
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Criar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDatasetImage(String path, {required double width, required double height, required BoxFit fit}) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, width: width, height: height, fit: fit, errorBuilder: (c, e, s) => _buildImageError(width, height));
    }
    return Image.file(File(path), width: width, height: height, fit: fit, errorBuilder: (c, e, s) => _buildImageError(width, height));
  }

  Widget _buildImageError(double width, double height) {
    return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.image_not_supported));
  }
}

// ==========================================
// MAPA INTERATIVO DO DATASET
// ==========================================
class _DatasetMapScreen extends StatefulWidget {
  final DataSet dataset;
  final MeasurementData? pendingMeasurement;

  const _DatasetMapScreen({
    required this.dataset,
    this.pendingMeasurement,
  });

  @override
  State<_DatasetMapScreen> createState() => _DatasetMapScreenState();
}

class _DatasetMapScreenState extends State<_DatasetMapScreen> {
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
      builder: (context) {
        return AlertDialog(
          title: const Text("Nomear Ponto de Medição"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Ex: Lombo, Cabeça, Filé"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                final label = nameController.text.trim();
                if (label.isEmpty) return;

                final newPoint = MeasurementPoint(
                  id: "point_${DateTime.now().millisecondsSinceEpoch}",
                  label: label,
                  x: x,
                  y: y,
                  measurements: [widget.pendingMeasurement!],
                );

                // IMPORTANTE: Atualiza o objeto dentro do ValueNotifier global para refletir em todas as telas
                final currentGlobalList = globalDatasetsNotifier.value;
                for (var dataset in currentGlobalList) {
                  if (dataset.id == widget.dataset.id) {
                    dataset.points.add(newPoint);
                    break;
                  }
                }
                // Força o ValueNotifier a disparar uma notificação de mudança de estado interno
                globalDatasetsNotifier.value = List<DataSet>.from(currentGlobalList);

                Navigator.pop(context); // Fecha o Dialog de Nome
                Navigator.pop(context); // Fecha a tela de Mapa atual
                Navigator.pop(context); // Fecha a StatsScreen adaptativa voltando para a tela do Gráfico de Origem
                
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text("Medição acoplada com sucesso em '$label'!")),
                );
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMeasurement(BuildContext context, MeasurementPoint point, MeasurementData measurement) async {
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
        title: Text(_isSavingMode ? "Toque na imagem para salvar" : widget.dataset.name),
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
              child: const Text(
                "Modo de Gravação: Toque em um local livre para vincular o gráfico.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
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
                                    errorBuilder: (c, e, s) => Container(
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
                                if (_isSavingMode) return;
                                if (point.measurements.isEmpty) return;
                                _openMeasurement(context, point, point.measurements.first);
                              },
                              onLongPress: () {
                                // TODO: Remoção de pontos
                                print("Removendo Pontos...");        
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