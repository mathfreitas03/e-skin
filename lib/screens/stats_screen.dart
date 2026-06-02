import 'package:flutter/material.dart';

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
  State<StatsScreen> createState() =>
      _StatsScreenState();
}

class _StatsScreenState
    extends State<StatsScreen> {

  late final MeasurementSession
      session;

  @override
  void initState() {

    super.initState();

    /// =========================
    /// SESSÃO EXEMPLO
    /// =========================

    session = MeasurementSession(

      id: "session_001",

      name: "Sessão Experimental",

      createdAt: DateTime.now(),

      datasets: [

        /// =========================
        /// DATASET 1
        /// =========================

        DataSet(

          id: "fish_001",

          name: "Tilápia A",

          imagePath:
              "assets/images/standard_fish.png",

          points: [

            MeasurementPoint(

              id: "head",

              label: "Cabeça",

              x: 0.18,
              y: 0.48,

              measurements: [

                MeasurementData(

                  id: "m1",

                  timestamp:
                      DateTime.now(),

                  real: const [
                    10,
                    20,
                    30,
                    40,
                  ],

                  imag: const [
                    5,
                    10,
                    15,
                    20,
                  ],

                  freq: const [
                    100,
                    1000,
                    10000,
                    100000,
                  ],
                ),
              ],
            ),

            MeasurementPoint(

              id: "body",

              label: "Corpo",

              x: 0.45,
              y: 0.48,

              measurements: [

                MeasurementData(

                  id: "m2",

                  timestamp:
                      DateTime.now(),

                  real: const [
                    15,
                    25,
                    35,
                    45,
                  ],

                  imag: const [
                    8,
                    12,
                    18,
                    24,
                  ],

                  freq: const [
                    100,
                    1000,
                    10000,
                    100000,
                  ],
                ),
              ],
            ),
          ],
        ),

        /// =========================
        /// DATASET 2
        /// =========================

        DataSet(

          id: "fish_002",

          name: "Tilápia B",

          imagePath:
              "assets/images/standard_fish.png",

          points: [

            MeasurementPoint(

              id: "tail",

              label: "Cauda",

              x: 0.18,
              y: 0.9,

              measurements: [

                MeasurementData(

                  id: "m3",

                  timestamp:
                      DateTime.now(),

                  real: const [
                    12,
                    18,
                    28,
                    36,
                  ],

                  imag: const [
                    4,
                    7,
                    13,
                    18,
                  ],

                  freq: const [
                    100,
                    1000,
                    10000,
                    100000,
                  ],
                ),
              ],
            ),

            MeasurementPoint(

              id: "dorsal",

              label: "Dorsal",

              x: 0.35,
              y: 0.5,

              measurements: [

                MeasurementData(

                  id: "m4",

                  timestamp:
                      DateTime.now(),

                  real: const [
                    9,
                    17,
                    24,
                    38,
                  ],

                  imag: const [
                    2,
                    5,
                    9,
                    14,
                  ],

                  freq: const [
                    100,
                    1000,
                    10000,
                    100000,
                  ],
                ),
              ],
            ),
          ],
        ),

        /// =========================
        /// DATASET 3
        /// =========================

        DataSet(

          id: "fish_003",

          name: "Tilápia C",

          imagePath:
              "assets/images/standard_fish.png",

          points: [

            MeasurementPoint(

              id: "ventral",

              label: "Ventral",

              x: 0.55,
              y: 0.60,

              measurements: [

                MeasurementData(

                  id: "m5",

                  timestamp:
                      DateTime.now(),

                  real: const [
                    11,
                    21,
                    31,
                    41,
                  ],

                  imag: const [
                    3,
                    8,
                    12,
                    19,
                  ],

                  freq: const [
                    100,
                    1000,
                    10000,
                    100000,
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// =========================
  /// ABRIR DATASET
  /// =========================

  void _openDataset(
    DataSet dataset,
  ) {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) =>
            _DatasetMapScreen(
          dataset: dataset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.all(12),

      child: ListView.builder(

        itemCount:
            session.datasets.length,

        itemBuilder: (context, index) {

          final dataset =
              session.datasets[index];

          return Card(

            elevation: 3,

            margin:
                const EdgeInsets.only(
              bottom: 12,
            ),

            child: ListTile(

              leading: ClipRRect(

                borderRadius:
                    BorderRadius.circular(8),

                child: Image.asset(

                  dataset.imagePath,

                  width: 60,

                  fit: BoxFit.cover,
                ),
              ),

              title: Text(
                dataset.name,
              ),

              subtitle: Text(
                "${dataset.points.length} pontos",
              ),

              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),

              onTap: () =>
                  _openDataset(
                dataset,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// MAPA DO DATASET
/// =========================
/// MAPA DO DATASET
/// =========================
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
    // Definimos uma proporção padrão para a imagem (ex: 4/3, 16/9 ou 1.0 se for quadrada).
    // Vamos assumir uma proporção comum baseada na foto típica de um peixe (ex: 4:3 -> 1.33 ou 16:9 -> 1.77)
    // Se a sua imagem for quadrada, use 1.0. Se for retangular padrão, 4 / 3 costuma funcionar bem.
    const double imageAspectRatio = 16 / 9; 

    return Scaffold(
      appBar: AppBar(
        title: Text(dataset.name),
      ),
      body: Center( // Garante que o container fique centralizado na tela
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Buscamos as dimensões máximas permitidas pela tela
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;

            // Calculamos o tamanho real que o AspectRatio vai ocupar (reproduzindo o BoxFit.contain)
            double finalWidth = maxW;
            double finalHeight = maxW / imageAspectRatio;

            if (finalHeight > maxH) {
              finalHeight = maxH;
              finalWidth = maxH * imageAspectRatio;
            }

            return Container(
              width: finalWidth,
              height: finalHeight,
              color: Colors.black12, // Opcional: para ver a área exata da imagem
              child: Stack(
                clipBehavior: Clip.none, // Evita que pontos sumam nas bordas
                children: [
                  // A imagem agora ocupa 100% do container que tem a proporção exata dela
                  Positioned.fill(
                    child: Image.asset(
                      dataset.imagePath,
                      fit: BoxFit.fill, // Pode usar fill porque o container já está na proporção correta
                    ),
                  ),

                  // Os pontos agora se posicionam em relação ao container idêntico à imagem
                  ...dataset.points.map(
                    (point) {
                      const double markerSize = 28.0;

                      return Positioned(
                        // Subtraímos metade do tamanho do marcador (14) para que o centro do 
                        // círculo seja exatamente a coordenada X e Y (evita desalinhamento)
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