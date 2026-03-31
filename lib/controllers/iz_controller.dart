// Description: Controller for processing impedance data from a string block.
// Descrição: Controlador para processar dados de impedância a partir de um bloco de string.

class IzController {

  List<double> real = [];
  List<double> imag = [];
  List<double> freq = [];

  void process(String block) {

    final clean = block.replaceAll("@", "");
    final parts = clean.split("&");

    if (parts.length < 4) return;

    real = [];
    imag = [];
    freq = [];

    for (int i = 1; i < parts.length; i += 3) {

      if (i + 2 >= parts.length) break;

      final r = double.tryParse(parts[i]);
      final im = double.tryParse(parts[i + 1]);
      final f = double.tryParse(parts[i + 2]);

      if (r != null && im != null && f != null) {
        real.add(r);
        imag.add(im);
        freq.add(f);
      }
    }
  }
}