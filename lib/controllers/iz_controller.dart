import 'dart:convert';

class IzController {
  static const bool debugMode = true;

  List<double> real = [];
  List<double> imag = [];
  List<double> freq = [];
  
  // Mudado para aceitar nulo quando o dado não fizer parte do bloco atual
  double? temperatura;
  double? forca;
  double? forcaTareada;
  
  Map<String, String> config = {};

  void process(String raw) {
    if (debugMode) {
      print("======= [DEBUG] STRING BRUTA RECEBIDA =======");
      print(raw);
      print("=============================================");
    }

    // 1. EXTRAÇÃO E LIMPEZA DAS LINHAS DO BLOCO
    final block = raw.contains("@") ? raw.split("@").first : raw;
    final lines = block.split(RegExp(r'\r?\n'))
                       .map((l) => l.trim())
                       .where((l) => l.isNotEmpty)
                       .toList();

    if (lines.isEmpty) return;

    // =========================================================================
    // CASO A: É UM BLOCO DE CONFIGURAÇÃO DO FIRMWARE
    // =========================================================================
    final configMatch = RegExp(
      r'------- Saved Configuration -------([\s\S]*?)----------------------------------',
    ).firstMatch(raw);

    if (configMatch != null) {
      config = {}; // Limpa apenas a configuração antiga
      final configBlock = configMatch.group(1)!;
      final configLines = configBlock.split(RegExp(r'\r?\n'));

      for (var line in configLines) {
        final clean = line.trim();
        if (clean.isEmpty) continue;

        final idx = clean.indexOf(":");
        if (idx == -1) continue;

        final key = clean.substring(0, idx).trim();
        final value = clean.substring(idx + 1).trim();

        config[key] = value;
      }
      if (debugMode) print("CONFIGURAÇÃO CARREGADA COM SUCESSO: $config");
      return; // Configuração processada, finaliza aqui.
    }

    // =========================================================================
    // CASO B: DADOS SIMPLES DE TELEMETRIA (Ex: Comando INF)
    // =========================================================================
    if (lines.first.toLowerCase() == 'ok' && lines.length == 2) {
      final dataLine = lines[1];
      if (dataLine.contains("&")) {
        final parts = dataLine.split("&").map((e) => e.trim()).toList();
        if (parts.length >= 3) {
          temperatura = double.tryParse(parts[0]); 
          forcaTareada = double.tryParse(parts[1]); 
          forca = double.tryParse(parts[2]);         
          
          if (debugMode) {
            print("DADOS SIMPLES -> Temp: $temperatura | Força: $forca | Força Tareada: $forcaTareada");
          }
          return; // Aborta aqui! Assim NÃO tocamos nas listas do gráfico (real, imag, freq).
        }
      }
    }

    // =========================================================================
    // CASO C: MATRIZ DE VARREDURA DO GRÁFICO (Dados IZ)
    // =========================================================================
    
    // Como confirmamos que este bloco é do gráfico, limpamos as listas antigas dele
    List<double> localReal = [];
    List<double> localImag = [];
    List<double> localFreq = [];

    for (var line in lines) {
      final cleanLine = line.trim();

      if (cleanLine.toLowerCase() == 'ok' || cleanLine.startsWith("CFIT")) {
        continue;
      }

      if (!cleanLine.contains("&")) continue;

      final parts = cleanLine.split("&").map((e) => e.trim()).toList();

      if (parts.length != 3) {
        if (debugMode) {
          print("Linha desalinhada/corrompida ignorada (Colunas: ${parts.length}): $cleanLine");
        }
        continue;
      }

      final r = double.tryParse(parts[0]);
      final im = double.tryParse(parts[1]);
      final f = double.tryParse(parts[2]);

      if (r != null && im != null && f != null && f > 0) {
        localReal.add(r);
        localImag.add(im);
        localFreq.add(f);
      }
    }

    if (localFreq.isEmpty) {
      print("ERRO: Nenhum dado de varredura IZ válido foi encontrado.");
      return;
    }

    // Gera o mapa estruturado para aplicar a ordenação estável por frequência (Eixo X)
    final data = List.generate(localFreq.length, (i) {
      return {
        "f": localFreq[i],
        "r": localReal[i],
        "i": localImag[i],
      };
    });

    // Ordena de forma crescente pelo valor correto da Frequência
    data.sort((a, b) => (a["f"] as double).compareTo(b["f"] as double));

    // Despacha os arrays ordenados de volta para as propriedades globais da classe
    freq = data.map((e) => e["f"] as double).toList();
    real = data.map((e) => e["r"] as double).toList();
    imag = data.map((e) => e["i"] as double).toList();

    temperatura = null;
    forca = null;
    forcaTareada = null;

    if (debugMode) {
      print("DEBUG IZ CONCLUÍDO:");
      print("-> Total de frequências válidas: ${freq.length}");
      print("-> Primeiro ponto da curva -> F: ${freq.first} Hz | R: ${real.first} | I: ${imag.first}");
    }
  }
}