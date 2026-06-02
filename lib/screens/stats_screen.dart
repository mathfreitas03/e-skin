import 'dart:io'; // IMPORTANTE: Necessário para usar a classe File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // IMPORTANTE: Biblioteca para abrir a galeria

import '../controllers/iz_controller.dart';
import '../models/measurement_session.dart';
import '../models/dataset.dart';
import '../models/measurement_point.dart';
import '../models/measurement_data.dart';

import 'graph_view_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final MeasurementSession session;
  final Set<String> _selectedDatasetIds = <String>{};

  bool get _isSelectionMode => _selectedDatasetIds.isNotEmpty;

  @override
  void initState() {
    super.initState();

    session = MeasurementSession(
      id: "session_001",
      name: "Medições registradas",
      createdAt: DateTime.now(),
      datasets: [
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
      ],
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedDatasetIds.contains(id)) {
        _selectedDatasetIds.remove(id);
      } else {
        _selectedDatasetIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDatasetIds.clear();
    });
  }

  void _deleteSelectedDatasets() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Excluir Datasets"),
          content: Text(
            "Tem certeza que deseja excluir ${_selectedDatasetIds.length} dataset(s) selecionado(s)?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  session.datasets.removeWhere(
                    (dataset) => _selectedDatasetIds.contains(dataset.id),
                  );
                  _selectedDatasetIds.clear();
                });
                Navigator.pop(context);
              },
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );
  }

  void _openDataset(DataSet dataset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DatasetMapScreen(
          dataset: dataset,
        ),
      ),
    );
  }

  /// ==========================================
  /// COMPONENTE AUXILIAR PARA RENDERIZAR IMAGEM
  /// ==========================================
  /// Método utilitário para carregar dinamicamente se a imagem vem do Asset ou da Galeria (File)
  static Widget _buildDatasetImage(String path, {required double width, required double height, required BoxFit fit}) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImageError(width, height),
      );
    } else {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImageError(width, height),
      );
    }
  }

  static Widget _buildImageError(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported),
    );
  }

  /// ==========================================
  /// COLETAR DADOS E CRIAR DATASET (COM GALERIA)
  /// ==========================================
  void _createNewDatasetDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    
    // Estado local do Dialog para armazenar o caminho escolhido da galeria
    String selectedImagePath = "assets/images/standard_fish.png"; 

    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permite atualizar a UI dentro do Dialog quando o usuário escolher uma foto
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            Future<void> pickImageFromGallery() async {
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setDialogState(() {
                  selectedImagePath = image.path; // Guarda o caminho do arquivo temporário do celular
                });
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
                        decoration: const InputDecoration(
                          labelText: "Nome do Dataset",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Por favor, insira um nome.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Preview da Imagem Selecionada
                      const Text(
                        "Imagem de Fundo:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildDatasetImage(
                          selectedImagePath,
                          width: 150,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Botão para abrir a galeria
                      OutlinedButton.icon(
                        onPressed: pickImageFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Selecionar da Galeria"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final uniqueId = "fish_${DateTime.now().millisecondsSinceEpoch}";

                      final newDataset = DataSet(
                        id: uniqueId,
                        name: nameController.text.trim(),
                        imagePath: selectedImagePath, // Salva o caminho (Asset ou File)
                        points: [],
                      );

                      setState(() {
                        session.datasets.add(newDataset);
                      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        title: Text(
          _isSelectionMode
              ? "${_selectedDatasetIds.length} selecionados"
              : session.name,
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedDatasets,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: session.datasets.length,
          itemBuilder: (context, index) {
            final dataset = session.datasets[index];
            final isSelected = _selectedDatasetIds.contains(dataset.id);

            return Card(
              elevation: isSelected ? 6 : 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: isSelected
                  ? RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.green, width: 2),
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text("${dataset.points.length} pontos"),
                trailing: _isSelectionMode
                    ? null
                    : const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  if (_isSelectionMode) {
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
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: _createNewDatasetDialog,
              child: const Icon(Icons.add),
            ),
    );
  }
}

// ==========================================
// MAPA INTERATIVO DO DATASET
// ==========================================
class _DatasetMapScreen extends StatelessWidget {
  final DataSet dataset;

  const _DatasetMapScreen({
    required this.dataset,
  });

  Future<void> _openMeasurement(
    BuildContext context,
    MeasurementPoint point,
    MeasurementData measurement,
  ) async {
    final iz = IzController();
    iz.real = List.from(measurement.real);
    iz.imag = List.from(measurement.imag);
    iz.freq = List.from(measurement.freq);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              "${dataset.name} - ${point.label}",
            ),
          ),
          body: GraphViewScreen(
            title: "${dataset.name} - ${point.label}",
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
        title: Text(dataset.name),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;

            double finalWidth = maxW;
            double finalHeight = maxW / imageAspectRatio;

            if (finalHeight > maxH) {
              finalHeight = maxH;
              finalWidth = maxH * imageAspectRatio;
            }

            return Container(
              width: finalWidth,
              height: finalHeight,
              color: Colors.black12,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Imagem de Fundo (Dinâmica: Aceita Asset ou Galeria)
                  Positioned.fill(
                    child: dataset.imagePath.startsWith('assets/')
                        ? Image.asset(
                            dataset.imagePath,
                            fit: BoxFit.fill,
                          )
                        : Image.file(
                            File(dataset.imagePath),
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                  ),
                  ...dataset.points.map(
                    (point) {
                      const double markerSize = 28.0;

                      return Positioned(
                        left: (finalWidth * point.x) - (markerSize / 2),
                        top: (finalHeight * point.y) - (markerSize / 2),
                        child: GestureDetector(
                          onTap: () {
                            if (point.measurements.isEmpty) return;
                            _openMeasurement(
                              context,
                              point,
                              point.measurements.first,
                            );
                          },
                          child: Container(
                            width: markerSize,
                            height: markerSize,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 6,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}