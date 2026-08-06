import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/models/dataset.dart';
import 'package:eprobe/models/measurement_point.dart';
import 'package:eprobe/repositories/dataset_repository.dart';
import 'package:eprobe/services/export_service.dart';
import 'package:eprobe/services/import_service.dart'; // Importação do Serviço de Importação
import 'package:image_picker/image_picker.dart';
import 'dataset_map_screen.dart';

class DatasetNotifier extends StateNotifier<List<DataSet>> {
  final DatasetRepository _repository;
  final ImportService _importService = ImportService();

  DatasetNotifier(this._repository) : super([]) {
    loadCurrentSessionDatasets();
  }

  Future<void> loadCurrentSessionDatasets() async {
    try {
      final datasets = await _repository.getDatasetsFromCurrentSession();
      state = datasets;
    } catch (e) {
      debugPrint("Erro ao carregar dados da sessão: $e");
    }
  }

  Future<void> deleteDatasets(Set<String> ids) async {
    await _repository.deleteDatasets(ids);
    await loadCurrentSessionDatasets();
  }

  Future<void> createDataset({required String name, required String imagePath}) async {
    await _repository.createDataset(name: name, imagePath: imagePath);
    await loadCurrentSessionDatasets();
  }

  /// Método para realizar a importação do arquivo ZIP e recarregar a lista local
  Future<bool> importDataset() async {
    final bool success = await _importService.importDatasetsFromFile();
    if (success) {
      await loadCurrentSessionDatasets();
    }
    return success;
  }
}

final datasetProvider = StateNotifierProvider<DatasetNotifier, List<DataSet>>((ref) {
  return DatasetNotifier(DatasetRepository());
});

// ============================================================================
// STATS SCREEN WIDGET
// ============================================================================

class StatsScreen extends ConsumerStatefulWidget {
  final MeasurementPoint? currentMeasurementToSave;

  const StatsScreen({super.key, this.currentMeasurementToSave});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final ExportService _exportService = ExportService();
  final Set<String> _selectedDatasetIds = <String>{};

  bool get _isSelectionMode => _selectedDatasetIds.isNotEmpty;
  bool get _isSavingFlowMode => widget.currentMeasurementToSave != null;

  void _toggleSelection(String id) {
    if (_isSavingFlowMode) return;
    setState(() {
      _selectedDatasetIds.contains(id) 
          ? _selectedDatasetIds.remove(id) 
          : _selectedDatasetIds.add(id);
    });
  }

  Future<void> _exportSelectedDatasets() async {
  // Exibe opções de ação para o usuário
  final String? choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download, color: Colors.blue),
            title: const Text('Salvar no Dispositivo (Downloads)'),
            onTap: () => Navigator.pop(ctx, 'save'),
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.green),
            title: const Text('Compartilhar com outro aplicativo'),
            onTap: () => Navigator.pop(ctx, 'share'),
          ),
        ],
      ),
    ),
  );

  if (choice == null) return;

  _showLoadingDialog();

    try {
      bool success = false;
      if (choice == 'save') {
        success = await _exportService.saveDatasetsToDevice(_selectedDatasetIds);
      } else if (choice == 'share') {
        success = await _exportService.shareDatasets(_selectedDatasetIds);
      }

      if (mounted) Navigator.pop(context); // Fecha loading

      if (success) {
        setState(() => _selectedDatasetIds.clear());
        _showSnackBar(
          choice == 'save' ? 'Arquivo salvo com sucesso!' : 'Exportado com sucesso!', 
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Erro ao exportar: $e", Colors.red);
    }
  }

  Future<void> _importDataset() async {
    _showLoadingDialog();

    try {
      final bool success = await ref.read(datasetProvider.notifier).importDataset();
      if (mounted) Navigator.pop(context);

      if (success) {
        _showSnackBar(
          LanguageHandler().translate('import_success'), 
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar(
        "${LanguageHandler().translate('import_failed')}: $e", 
        Colors.red,
      );
    }
  }

  Future<void> _deleteSelectedDatasets() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LanguageHandler().translate('delete_datasets')),
        content: Text("${LanguageHandler().translate('confirm_delete')} ${_selectedDatasetIds.length} dataset(s)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LanguageHandler().translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(LanguageHandler().translate('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(datasetProvider.notifier).deleteDatasets(_selectedDatasetIds);
      setState(() => _selectedDatasetIds.clear());
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datasets = ref.watch(datasetProvider);

    return Scaffold(
      appBar: AppBar(
        leading: (_isSelectionMode || _isSavingFlowMode)
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (_isSavingFlowMode) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _selectedDatasetIds.clear());
                  }
                },
              )
            : null,
        title: Text(
          _isSavingFlowMode
              ? LanguageHandler().translate('select_target_dataset')
              : _isSelectionMode
                  ? '${_selectedDatasetIds.length} ${LanguageHandler().translate('selected').toLowerCase()}'
                  : LanguageHandler().translate('recorded_measurements'),
        ),
        backgroundColor: _isSavingFlowMode ? Colors.blue[700] : null,
        foregroundColor: _isSavingFlowMode ? Colors.white : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _exportSelectedDatasets,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedDatasets,
            ),
          ]
          //  else if (!_isSavingFlowMode) ...[
          //   IconButton(
          //     icon: const Icon(Icons.file_upload_outlined),
          //     tooltip: LanguageHandler().translate('import'),
          //     onPressed: _importDataset,
          //   ),
          // ]
        ],
      ),
      body: Column(
        children: [
          if (_isSavingFlowMode) _buildSavingBanner(),
          Expanded(
            child: datasets.isEmpty
                ? Center(
                    child: Text(
                      LanguageHandler().translate('no_datasets'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: datasets.length,
                    itemBuilder: (context, index) {
                      final dataset = datasets[index];
                      final isSelected = _selectedDatasetIds.contains(dataset.id);
                      return DatasetCard(
                        dataset: dataset,
                        isSelected: isSelected,
                        isSavingFlowMode: _isSavingFlowMode,
                        isSelectionMode: _isSelectionMode,
                        onTap: () {
                          if (_isSavingFlowMode) {
                            _navigateToMap(dataset, pendingMeasurement: widget.currentMeasurementToSave);
                          } else if (_isSelectionMode) {
                            _toggleSelection(dataset.id);
                          } else {
                            _navigateToMap(dataset);
                          }
                        },
                        onLongPress: () => _toggleSelection(dataset.id),
                      );
                    },
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
              onPressed: () => _showAddOptionsModal(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  /// Exibe o Modal Bottom Sheet para escolher entre criar do zero ou importar
  void _showAddOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: Text(
                  LanguageHandler().translate('create_new_dataset'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateDatasetDialog(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.file_upload, color: Colors.white),
                ),
                title: Text(
                  LanguageHandler().translate('import_dataset'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _importDataset();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavingBanner() {
    return Container(
      color: Colors.orange[100],
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LanguageHandler().translate('touch_dataset'),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMap(DataSet dataset, {MeasurementPoint? pendingMeasurement}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DatasetMapScreen(dataset: dataset, pendingMeasurement: pendingMeasurement),
      ),
    );
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  void _showCreateDatasetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _CreateDatasetDialog(),
    );
  }
}

// ============================================================================
// DATASET CARD WIDGET
// ============================================================================

class DatasetCard extends StatelessWidget {
  final DataSet dataset;
  final bool isSelected;
  final bool isSavingFlowMode;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DatasetCard({
    super.key,
    required this.dataset,
    required this.isSelected,
    required this.isSavingFlowMode,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 6 : 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: isSelected
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : isSavingFlowMode
              ? RoundedRectangleBorder(
                  side: BorderSide(color: Colors.orange[300]!, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
      color: isSelected ? Colors.green[50] : null,
      child: ListTile(
        leading: isSelected
            ? const SizedBox(
                width: 60,
                child: Icon(Icons.check_circle, color: Colors.green),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(dataset.imagePath, 80, 60),
              ),
        title: Text(
          dataset.name,
          style: TextStyle(
            fontWeight: isSelected || isSavingFlowMode ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text("${dataset.points.length} ${LanguageHandler().translate('mapped_points')}"),
        trailing: isSelectionMode
            ? null
            : Icon(
                isSavingFlowMode ? Icons.ads_click : Icons.arrow_forward_ios,
                color: isSavingFlowMode ? Colors.orange[700] : null,
              ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  Widget _buildImage(String path, double width, double height) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, _, _) => _errorBox(width, height));
    }
    return Image.file(File(path), width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, _, _) => _errorBox(width, height));
  }

  Widget _errorBox(double width, double height) {
    return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.image_not_supported));
  }
}

// ============================================================================
// CREATE DATASET DIALOG WIDGET
// ============================================================================

class _CreateDatasetDialog extends ConsumerStatefulWidget {
  const _CreateDatasetDialog();

  @override
  ConsumerState<_CreateDatasetDialog> createState() => _CreateDatasetDialogState();
}

class _CreateDatasetDialogState extends ConsumerState<_CreateDatasetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedImagePath = "assets/images/standard_fish.png";

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LanguageHandler().translate('new_dataset')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: LanguageHandler().translate('dataset_name')),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Insira um nome." : null,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _selectedImagePath.startsWith('assets/')
                    ? Image.asset(_selectedImagePath, width: 150, height: 100, fit: BoxFit.cover)
                    : Image.file(File(_selectedImagePath), width: 150, height: 100, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(LanguageHandler().translate('select_picture')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(LanguageHandler().translate('cancel'))),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await ref.read(datasetProvider.notifier).createDataset(
                    name: _nameController.text.trim(),
                    imagePath: _selectedImagePath,
                  );
              if (mounted) Navigator.pop(context);
            }
          },
          child: Text(LanguageHandler().translate('create')),
        ),
      ],
    );
  }
}