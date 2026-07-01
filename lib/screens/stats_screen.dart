import 'dart:convert';
import 'dart:io';
import 'package:eprobe/database/db.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/iz_controller.dart';
import '../models/dataset.dart';
import '../models/dataset_point.dart';
import '../models/measurement_point.dart';
import 'graph_view_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

final ValueNotifier<List<DataSet>> globalDatasetsNotifier = ValueNotifier<List<DataSet>>([]);

Future<void> loadCurrentSessionDatasets() async {
  try {
    List<DataSet> data = await DB.instance.getDataSetsFromCurrentSession();
    globalDatasetsNotifier.value = data;
  } catch (e) {
    print("Erro ao carregar dados da sessão: $e");
  }
}

class StatsScreen extends StatefulWidget {
  final MeasurementPoint? currentMeasurementToSave;

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
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await loadCurrentSessionDatasets();
  }

  @override
  Widget build(BuildContext context) {
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
                        Navigator.pop(context);
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
              if (_isSelectionMode) ... [
                IconButton(
                  icon: const Icon(Icons.ios_share, color: Colors.black), 
                  onPressed: () => _exportSelectedDatasets(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed: () => _deleteSelectedDatasets(),
                ),
              ]
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
                  onPressed: _createNewDatasetDialog,
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  void _openDatasetForSaving(DataSet dataset, MeasurementPoint measurement) {
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

  void _exportSelectedDatasets() async {
    showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
      final db = await DB.instance.getDatabase;
      List<Map<String, dynamic>> exportData = [];

      // 1. Busca detalhadamente cada dataset selecionado no banco de dados
      for (String datasetId in _selectedDatasetIds) {
        // Busca o Dataset
        final List<Map<String, dynamic>> datasetMap = await db.query(
          'dataset',
          where: 'id = ?',
          whereArgs: [datasetId],
        );

        if (datasetMap.isEmpty) continue;
        Map<String, dynamic> datasetJson = Map<String, dynamic>.from(datasetMap.first);

        // Busca os Pontos do Dataset
        final List<Map<String, dynamic>> pointsMap = await db.query(
          'measurement_point',
          where: 'dataset_id = ?',
          whereArgs: [datasetId],
        );

        List<Map<String, dynamic>> pointsJsonList = [];

        for (var pointRow in pointsMap) {
          Map<String, dynamic> pointJson = Map<String, dynamic>.from(pointRow);
          String pointId = pointRow['id'];

          // Busca as Medições do Ponto
          final List<Map<String, dynamic>> measurementsMap = await db.query(
            'measurement_data',
            where: 'point_id = ?',
            whereArgs: [pointId],
          );

          // Decodifica as strings JSON salvas no banco de volta para estruturas de lista nativas
          List<Map<String, dynamic>> measurementsJsonList = measurementsMap.map((m) {
            return {
              'id': m['id'],
              'real': jsonDecode(m['real'] ?? '[]'),
              'imag': jsonDecode(m['imag'] ?? '[]'),
              'freq': jsonDecode(m['freq'] ?? '[]'),
            };
          }).toList();

          pointJson['measurements'] = measurementsJsonList;
          pointsJsonList.add(pointJson);
        }

        datasetJson['points'] = pointsJsonList;
        exportData.add(datasetJson);
      }

      // Fecha o modal de carregamento
      if (mounted) Navigator.pop(context);

      if (exportData.isEmpty) return;

      // 2. Converte a estrutura final para uma String JSON formatada
      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // 3. Grava em um arquivo temporário no dispositivo
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/eprobe_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final File file = File(filePath);
      await file.writeAsString(jsonString);

      // 4. Dispara a folha de compartilhamento nativa do sistema operacional
      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/json')],
        text: 'Exportação de Datasets do eProbe',
      );

      // Se o compartilhamento foi bem sucedido, limpa a seleção
      if (result.status == ShareResultStatus.success) {
        setState(() => _selectedDatasetIds.clear());
      }

    } catch (e) {
      // Garante fechar o loading em caso de erro catastrófico
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao exportar dados: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- INTERAÇÃO COM BANCO: DELETAR DATASET(S) ---
  void _deleteSelectedDatasets() {
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
              onPressed: () async {
                final db = await DB.instance.getDatabase;
                
                // Transação segura para deletar em lote
                await db.transaction((txn) async {
                  for (String id in _selectedDatasetIds) {
                    await txn.delete('dataset', where: 'id = ?', whereArgs: [id]);
                  }
                });

                // Atualiza o notifier buscando os dados atualizados do banco
                await loadCurrentSessionDatasets();
                
                if (mounted) {
                  setState(() => _selectedDatasetIds.clear());
                  Navigator.pop(context);
                }
              },
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );
  }

  // --- INTERAÇÃO COM BANCO: CRIAR DATASET ---
  void _createNewDatasetDialog() {
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final db = await DB.instance.getDatabase;

                      // Garante que existe ao menos uma sessão no banco para vincular o Dataset
                      List<Map<String, dynamic>> sessions = await db.query('measurement_session', limit: 1);
                      String sessionId;
                      
                      if (sessions.isEmpty) {
                        sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
                        await db.insert('measurement_session', {
                          'id': sessionId,
                          'name': 'Sessão Padrão',
                          'created_at': DateTime.now().toIso8601String(),
                        });
                      } else {
                        sessionId = sessions.first['id'];
                      }

                      String newDatasetId = "fish_${DateTime.now().millisecondsSinceEpoch}";

                      // Salva no SQLite
                      await db.insert('dataset', {
                        'id': newDatasetId,
                        'name': nameController.text.trim(),
                        'image_path': selectedImagePath,
                        'session_id': sessionId,
                      });

                      // Sincroniza a UI reativamente do Banco de Dados
                      await loadCurrentSessionDatasets();

                      if (mounted) Navigator.pop(context);
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
  final MeasurementPoint? pendingMeasurement;

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

  // --- INTERAÇÃO COM BANCO: SALVAR PONTO E MEDIÇÃO COMPLETA ---
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
              onPressed: () async {
                final label = nameController.text.trim();
                if (label.isEmpty) return;

                final db = await DB.instance.getDatabase;
                final String pointId = "point_${DateTime.now().millisecondsSinceEpoch}";
                final String measurementId = "meas_${DateTime.now().millisecondsSinceEpoch}";

                // Executa tudo em uma transação atômica segura
                await db.transaction((txn) async {
                  // 1. Insere o Ponto de medição no mapa
                  await txn.insert('measurement_point', {
                    'id': pointId,
                    'label': label,
                    'x': x,
                    'y': y,
                    'timestamp': DateTime.now().toIso8601String(),
                    'dataset_id': widget.dataset.id,
                    'metadata': null,
                  });

                  // 2. Insere os arrays brutos convertidos em JSON string
                  await txn.insert('measurement_data', {
                    'id': measurementId,
                    'point_id': pointId,
                    'real': jsonEncode(widget.pendingMeasurement!.real),
                    'imag': jsonEncode(widget.pendingMeasurement!.imag),
                    'freq': jsonEncode(widget.pendingMeasurement!.freq),
                  });
                });

                // Atualiza a lista vinda do banco reativamente
                await loadCurrentSessionDatasets();

                if (mounted) {
                  Navigator.pop(context); // Fecha Dialog
                  Navigator.pop(context); // Fecha Tela Mapa
                  Navigator.pop(context); // Retorna ao Gráfico de origem
                  
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text("Medição acoplada com sucesso em '$label'!")),
                  );
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  // --- INTERAÇÃO COM BANCO: DELETAR PONTO (LONG PRESS) ---
  void _deletePointDialog(DatasetPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover Ponto"),
        content: Text("Deseja realmente excluir o ponto '${point.label}' e todas as suas medições?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final db = await DB.instance.getDatabase;
              
              // O ON DELETE CASCADE na estrutura do banco cuidará da tabela measurement_data automaticamente
              await db.delete('measurement_point', where: 'id = ?', whereArgs: [point.id]);

              await loadCurrentSessionDatasets();
              
              if (mounted) {
                Navigator.pop(context);
                // Atualiza o estado da própria tela de mapa aberta para remover o marcador visualmente
                setState(() {
                  widget.dataset.points.removeWhere((p) => p.id == point.id);
                });
              }
            },
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }

  Future<void> _openMeasurement(BuildContext context, DatasetPoint point, MeasurementPoint measurement) async {
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
                                if (_isSavingMode) return;
                                _deletePointDialog(point); // Implementado a remoção
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