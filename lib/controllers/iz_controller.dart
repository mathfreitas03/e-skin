// // class IzController {
// //   List<double> real = [];
// //   List<double> imag = [];
// //   List<double> freq = [];

// //   void process(String raw) {
// //     real = [];
// //     imag = [];
// //     freq = [];

// //     //  pega só até o primeiro bloco completo
    
// //     final block = raw.contains("@") ? raw.split("@").first : raw;
    

// //     //  quebra linha corretamente (Windows/Linux)
// //     final lines = block.split(RegExp(r'\r?\n'));
// //     print("Quantidade de linhas: ${lines.length}");
    
// //     for (var line in lines) {
// //       final cleanLine = line.trim();

// //       if (!cleanLine.contains("&")) continue;

// //       //  split seguro ignorando espaços
// //       final parts = cleanLine.split("&").map((e) => e.trim()).toList();

// //       if (parts.length < 3) continue;

// //       final r = double.tryParse(parts[0]);
// //       final im = double.tryParse(parts[1]);
// //       final f = double.tryParse(parts[2]);

// //       if (r != null && im != null && f != null) {
// //         real.add(r);
// //         imag.add(im);
// //         freq.add(f);
// //       }
// //     }

// //     if (freq.isEmpty) {
// //       print("ERRO: Nenhum dado IZ encontrado");
// //       return;
// //     }

// //     //  ordena por frequência
// //     final data = List.generate(freq.length, (i) {
// //       return {
// //         "f": freq[i],
// //         "r": real[i],
// //         "i": imag[i],
// //       };
// //     });

// //     data.sort((a, b) => (a["f"] as double).compareTo(b["f"] as double));

// //     freq = data.map((e) => e["f"] as double).toList();
// //     real = data.map((e) => e["r"] as double).toList();
// //     imag = data.map((e) => e["i"] as double).toList();

// //     //  DEBUG
// //     print("DEBUG IZ:");
// //     print("freq: ${freq.length}");
// //     print("real: ${real.length}");
// //     print("imag: ${imag.length}");
// //   }

// // }

// // VERSÃO PARA PROCESSAR MENSAGENS DE CONFIGURAÇÃO
// class IzController {
//   List<double> real = [];
//   List<double> imag = [];
//   List<double> freq = [];
//   double? temperatura;
//   double? forca;
//   double? forcaTareada;
//   // NOVO: armazenamento da configuração
//   Map<String, String> config = {};

//   void process(String raw) {
//     real = [];
//     imag = [];
//     freq = [];
//     config = {};
     


//     final configMatch = RegExp(
//       r'------- Saved Configuration -------([\s\S]*?)----------------------------------',
//     ).firstMatch(raw);

//     if (configMatch != null) {
//       final configBlock = configMatch.group(1)!;

//       final configLines = configBlock.split(RegExp(r'\r?\n'));

//       for (var line in configLines) {
//         final clean = line.trim();

//         if (clean.isEmpty) continue;

//         // separa por ":" apenas na primeira ocorrência
//         final idx = clean.indexOf(":");

//         if (idx == -1) continue;

//         final key = clean.substring(0, idx).trim();
//         final value = clean.substring(idx + 1).trim();

//         config[key] = value;
//       }

//       print("CONFIGURAÇÃO CARREGADA:");
//       print(config);
//     }

//     // Processamento de temperatura e forças

//     final simpleMatch = RegExp(
//       r'ok\s*\r?\n\s*\r?\n\s*([^\r\n@]+)',
//       caseSensitive: false,
//     ).firstMatch(raw);

//     if (simpleMatch != null) {
//       final dataLine = simpleMatch.group(1)!.trim();

//       final parts =
//           dataLine.split("&").map((e) => e.trim()).toList();

//       if (parts.length >= 3) {
//         temperatura = double.tryParse(parts[0]);
//         forca = double.tryParse(parts[0]);
//         forcaTareada = double.tryParse(parts[1]);

//         print("DADOS SIMPLES RECEBIDOS:");
//         print("Temperatura: $temperatura");
//         print("Força: $forca");
//         print("Força tareada: $forcaTareada");

//         return;
//       }
//     }

//     // =========================
//     // PROCESSA DADOS IZ
//     // =========================

//     // pega somente conteúdo antes do @
//     final block = raw.contains("@") ? raw.split("@").first : raw;

//     // quebra linhas corretamente
//     final lines = block.split(RegExp(r'\r?\n'));

//     print("Quantidade de linhas: ${lines.length}");

//     for (var line in lines) {
//       final cleanLine = line.trim();

//       // ignora linhas que não possuem formato IZ
//       if (!cleanLine.contains("&")) continue;

//       final parts =
//           cleanLine.split("&").map((e) => e.trim()).toList();

//       if (parts.length < 3) continue;

//       final r = double.tryParse(parts[0]);
//       final im = double.tryParse(parts[1]);
//       final f = double.tryParse(parts[2]);

//       if (r != null && im != null && f != null) {
//         real.add(r);
//         imag.add(im);
//         freq.add(f);
//       }
//     }

//     // =========================
//     // VALIDAÇÃO
//     // =========================
    

//     if (freq.isEmpty) {
//       print("Nenhum dado IZ encontrado.");

//       // ainda pode existir configuração válida
//       if (config.isNotEmpty) {
//         print("Somente configuração recebida.");
//       }

//       return;
//     }

//     // ORDENA POR FREQUÊNCIA

//     final data = List.generate(freq.length, (i) {
//       return {
//         "f": freq[i],
//         "r": real[i],
//         "i": imag[i],
//       };
//     });

//     data.sort(
//       (a, b) => (a["f"] as double)
//           .compareTo(b["f"] as double),
//     );

//     freq = data.map((e) => e["f"] as double).toList();
//     real = data.map((e) => e["r"] as double).toList();
//     imag = data.map((e) => e["i"] as double).toList();

//     // =========================
//     // DEBUG
//     // =========================

//     print("DEBUG IZ:");
//     print("freq: ${freq.length}");
//     print("real: ${real.length}");
//     print("imag: ${imag.length}");
//     print("temperatura ${real[0]}");
//     print("força ${freq[0]}");
//     print("força tareada ${imag[0]}");
//   }
// }

class IzController {
  // =========================
  // DADOS IZ
  // =========================

  List<double> real = [];
  List<double> imag = [];
  List<double> freq = [];

  // =========================
  // DADOS SIMPLES
  // =========================

  double? temperatura;
  double? forca;
  double? forcaTareada;

  // =========================
  // CONFIGURAÇÃO
  // =========================

  Map<String, String> config = {};

  void process(String raw) {
    // limpa estado anterior

    real = [];
    imag = [];
    freq = [];

    temperatura = null;
    forca = null;
    forcaTareada = null;

    config = {};

    // =========================
    // QUEBRA LINHAS
    // =========================

    final lines = raw.split(RegExp(r'\r?\n'));

    print("Quantidade de linhas: ${lines.length}");

    // DEBUG
    for (int i = 0; i < lines.length; i++) {
      print("Linha $i: ${lines[i]}");
    }

    // =========================
    // PROCESSA CONFIGURAÇÃO
    // =========================

    final configMatch = RegExp(
      r'------- Saved Configuration -------([\s\S]*?)----------------------------------',
    ).firstMatch(raw);

    if (configMatch != null) {
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

      print("CONFIGURAÇÃO CARREGADA:");
      print(config);
    }

    // =========================
    // PROCESSA NOVO FORMATO:
    //
    // ok
    // temp & forca & forca_tareada
    //
    // =========================

    for (int i = 0; i < lines.length; i++) {
      final current = lines[i].trim().toLowerCase();

      if (current == "ok") {
        // próxima linha contém os dados
        if (i + 1 < lines.length) {
          final dataLine = lines[i + 1].trim();

          final parts =
              dataLine.split("&").map((e) => e.trim()).toList();

          if (parts.length >= 3) {
            final t = double.tryParse(parts[0]);
            final ft = double.tryParse(parts[1]);
            final f = double.tryParse(parts[2]);

            // só aceita se os 3 forem válidos
            if (t != null && f != null && ft != null) {
              temperatura = t;
              forca = f;
              forcaTareada = ft;

              print("DADOS SIMPLES RECEBIDOS:");
              print("Temperatura: $temperatura");
              print("Força: $forca");
              print("Força tareada: $forcaTareada");

              return;
            }
          }
        }
      }
    }

    // Processamento de dados IZ

  if(lines.length > 2) {
    for (var line in lines) {
      final cleanLine = line.trim();

      if (cleanLine.isEmpty) continue;

      // precisa possuir "&"
      if (!cleanLine.contains("&")) continue;

      final parts =
          cleanLine.split("&").map((e) => e.trim()).toList();

      // IZ precisa de exatamente 3 partes
      if (parts.length != 3) continue;

      final r = double.tryParse(parts[0]);
      final im = double.tryParse(parts[1]);
      final f = double.tryParse(parts[2]);

      // se qualquer valor falhar, ignora
      if (r == null || im == null || f == null) {
        continue;
      }

      // IMPORTANTE:
      // ignora linhas de INF simples
      //
      // mensagem simples:
      // temperatura ~ 20-40
      // força pode ser negativa
      // frequência absurda não faz sentido aqui
      //
      // dados IZ normalmente possuem
      // frequência organizada em sweep
      //
      // então ignoramos linha se houver "ok"
      // antes dela
      //
      final lineIndex = lines.indexOf(line);

      if (lineIndex > 0) {
        final prev = lines[lineIndex - 1]
            .trim()
            .toLowerCase();

        if (prev == "ok") {
          continue;
        }
      }

      real.add(r);
      imag.add(im);
      freq.add(f);
    }

    // =========================
    // VALIDAÇÃO
    // =========================

    if (freq.isEmpty) {
      print("Nenhum dado IZ encontrado.");

      if (config.isNotEmpty) {
        print("Somente configuração recebida.");
      }

      return;
    }

    // =========================
    // ORDENA POR FREQUÊNCIA
    // =========================

    final data = List.generate(freq.length, (i) {
      return {
        "f": freq[i],
        "r": real[i],
        "i": imag[i],
      };
    });

    data.sort(
      (a, b) => (a["f"] as double)
          .compareTo(b["f"] as double),
    );

    freq = data.map((e) => e["f"] as double).toList();
    real = data.map((e) => e["r"] as double).toList();
    imag = data.map((e) => e["i"] as double).toList();

    // =========================
    // DEBUG
    // =========================

    print("DEBUG IZ:");
    print("freq: ${freq.length}");
    print("real: ${real.length}");
    print("imag: ${imag.length}");
  }
  }
}