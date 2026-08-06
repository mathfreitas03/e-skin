import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eprobe/models/dataset.dart';
import 'package:eprobe/repositories/dataset_repository.dart';

class DatasetNotifier extends StateNotifier<List<DataSet>> {
  final DatasetRepository _repository;

  DatasetNotifier(this._repository) : super([]) {
    loadDatasets();
  }

  Future<void> loadDatasets() async {
    try {
      final datasets = await _repository.getDatasetsFromCurrentSession();
      state = datasets; // Notifica automaticamente os ouvintes
    } catch (e) {
      // Tratar erros ou manter estado atual
    }
  }

  Future<void> deleteDatasets(Set<String> datasetIds) async {
    await _repository.deleteDatasets(datasetIds);
    await loadDatasets();
  }

  Future<void> createDataset(String name, String imagePath) async {
    await _repository.createDataset(name: name, imagePath: imagePath);
    await loadDatasets();
  }
}

// Provider global acessível por qualquer widget
final datasetProvider = StateNotifierProvider<DatasetNotifier, List<DataSet>>((ref) {
  return DatasetNotifier(DatasetRepository());
});