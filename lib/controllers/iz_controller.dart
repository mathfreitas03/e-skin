class IzController {
  List<double> real = [];
  List<double> imag = [];
  List<double> freq = [];

  void process(String raw) {
    real = [];
    imag = [];
    freq = [];

    // 🔥 pega só até o primeiro bloco completo
    final block = raw.contains("@") ? raw.split("@").first : raw;

    // 🔥 quebra linha corretamente (Windows/Linux)
    final lines = block.split(RegExp(r'\r?\n'));

    for (var line in lines) {
      final cleanLine = line.trim();

      if (!cleanLine.contains("&")) continue;

      // 🔥 split seguro ignorando espaços
      final parts = cleanLine.split("&").map((e) => e.trim()).toList();

      if (parts.length < 3) continue;

      final r = double.tryParse(parts[0]);
      final im = double.tryParse(parts[1]);
      final f = double.tryParse(parts[2]);

      if (r != null && im != null && f != null) {
        real.add(r);
        imag.add(im);
        freq.add(f);
      }
    }

    if (freq.isEmpty) {
      print("ERRO: Nenhum dado IZ encontrado");
      return;
    }

    // 🔥 ordena por frequência
    final data = List.generate(freq.length, (i) {
      return {
        "f": freq[i],
        "r": real[i],
        "i": imag[i],
      };
    });

    data.sort((a, b) => (a["f"] as double).compareTo(b["f"] as double));

    freq = data.map((e) => e["f"] as double).toList();
    real = data.map((e) => e["r"] as double).toList();
    imag = data.map((e) => e["i"] as double).toList();

    // 🔥 DEBUG
    print("DEBUG IZ:");
    print("freq: ${freq.length}");
    print("real: ${real.length}");
    print("imag: ${imag.length}");
  }

}