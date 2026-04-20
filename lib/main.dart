
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 600),
    center: true,
    minimumSize: Size(600, 400),
    title: "Precifica Fácil",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(PrecificaApp());
}

class PrecificaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precifica Fácil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', scaffoldBackgroundColor: Color(0xFF0F0F1A)),
      home: HomePage(),
    );
  }
}

class _CalcButton extends StatefulWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _CalcButton({required this.label, required this.bg, required this.fg, required this.onTap});
  @override
  _CalcButtonState createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: EdgeInsets.all(5),
            height: 64,
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: widget.bg.withOpacity(0.5), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Center(child: Text(widget.label, style: TextStyle(color: widget.fg, fontSize: 22, fontWeight: FontWeight.w600))),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final produtoController = TextEditingController();
  final lucroController = TextEditingController();
  final embalagemController = TextEditingController();
  final taxaFixaController = TextEditingController();
  final comissaoController = TextEditingController();
  final lucroManualController = TextEditingController();

  bool modoAutomatico = true;
  bool lucroEmReais = false;

  double preco = 0;
  double lucroReais = 0;
  double comissaoValor = 0;
  double comissaoPercentual = 0;
  double taxaFixaAplicada = 0;
  double liquido = 0;
  double custoTotal = 0;
  double custoProduto = 0;
  String faixaAplicada = '';
  bool calculou = false;
  bool mostrarCalc = false;

  String _displayFull = '0';
  String _currentNumber = '0';
  String _operando1 = '';
  String _operador = '';
  bool _novoNumero = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    lucroController.text = '30';
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  void calcular() {
    double cp = double.tryParse(produtoController.text.replaceAll(',', '.')) ?? 0;

    if (modoAutomatico) {
      double embalagem = 1.0;
      double lucroVal = double.tryParse(lucroController.text.replaceAll(',', '.')) ?? 30;
      double lucroPercent = lucroEmReais ? (cp > 0 ? lucroVal / cp : 0) : (lucroVal / 100);
      double lucroCalc = cp * lucroPercent;

      List<Map<String, dynamic>> faixas = [
        {'min': 0.0, 'max': 79.99, 'percent': 0.20, 'taxa': 4.0, 'faixa': 'Até R\$79,99 • 20% + R\$4'},
        {'min': 80.0, 'max': 99.99, 'percent': 0.14, 'taxa': 16.0, 'faixa': 'R\$80 a R\$99,99 • 14% + R\$16'},
        {'min': 100.0, 'max': 199.99, 'percent': 0.14, 'taxa': 20.0, 'faixa': 'R\$100 a R\$199,99 • 14% + R\$20'},
        {'min': 200.0, 'max': 499.99, 'percent': 0.14, 'taxa': 26.0, 'faixa': 'R\$200 a R\$499,99 • 14% + R\$26'},
        {'min': 500.0, 'max': double.infinity, 'percent': 0.14, 'taxa': 26.0, 'faixa': 'Acima de R\$500 • 14% + R\$26'},
      ];

      double precoVenda = 0, taxaFixa = 0, comissaoPercent = 0;
      String faixaStr = '';

      for (var f in faixas) {
        double tc = f['percent'];
        double tf = f['taxa'];
        double base = cp + embalagem + lucroCalc + tf;
        double pv = base / (1 - tc);
        if (pv >= f['min'] && pv <= f['max']) {
          precoVenda = pv; taxaFixa = tf; comissaoPercent = tc; faixaStr = f['faixa'];
          break;
        }
      }

      if (precoVenda == 0) {
        taxaFixa = 26.0; comissaoPercent = 0.14;
        precoVenda = (cp + embalagem + lucroCalc + taxaFixa) / (1 - comissaoPercent);
        faixaStr = 'Acima de R\$500 • 14% + R\$26';
      }

      double comissaoCalc = precoVenda * comissaoPercent;
      double liquidoCalc = precoVenda - comissaoCalc - taxaFixa;
      double custoCalc = cp + embalagem + comissaoCalc + taxaFixa;

      setState(() {
        preco = precoVenda; lucroReais = lucroCalc; comissaoValor = comissaoCalc;
        comissaoPercentual = comissaoPercent * 100; taxaFixaAplicada = taxaFixa;
        liquido = liquidoCalc; custoTotal = custoCalc; custoProduto = cp;
        faixaAplicada = faixaStr; calculou = true;
      });
    } else {
      double ce = double.tryParse(embalagemController.text.replaceAll(',', '.')) ?? 0;
      double tf = double.tryParse(taxaFixaController.text.replaceAll(',', '.')) ?? 0;
      double tc = (double.tryParse(comissaoController.text.replaceAll(',', '.')) ?? 0) / 100;
      double lc = (double.tryParse(lucroManualController.text.replaceAll(',', '.')) ?? 0) / 100;
      double lucroCalc = cp * lc;
      double precoVenda = tc < 1 ? (cp + ce + tf + lucroCalc) / (1 - tc) : 0;
      double comissaoCalc = precoVenda * tc;
      double liquidoCalc = precoVenda - comissaoCalc - tf;
      double custoCalc = cp + ce + tf + comissaoCalc;
      setState(() {
        preco = precoVenda; lucroReais = lucroCalc; comissaoValor = comissaoCalc;
        comissaoPercentual = tc * 100; taxaFixaAplicada = tf;
        liquido = liquidoCalc; custoTotal = custoCalc; custoProduto = cp;
        faixaAplicada = ''; calculou = true;
      });
    }
    _animController.reset();
    _animController.forward();
  }

  void _usarResultadoNoPrecificador() {
    double valor = double.tryParse(_currentNumber.replaceAll(',', '.')) ?? 0;
    if (valor <= 0) return;
    setState(() {
      produtoController.text = valor.toStringAsFixed(2);
      mostrarCalc = false;
    });
    calcular();
  }

  void _calcBotao(String valor) {
    setState(() {
      if (valor == 'AC') {
        _displayFull = '0'; _currentNumber = '0'; _operando1 = ''; _operador = ''; _novoNumero = false;
      } else if (valor == '⌫') {
        if (_currentNumber.length > 1) { _currentNumber = _currentNumber.substring(0, _currentNumber.length - 1); }
        else { _currentNumber = '0'; }
        _displayFull = _operador.isNotEmpty ? _operando1 + _operador + (_currentNumber == '0' ? '' : _currentNumber) : _currentNumber;
      } else if (['+', '-', '×', '÷'].contains(valor)) {
        _operando1 = _currentNumber; _operador = valor; _novoNumero = true;
        _displayFull = _currentNumber + valor;
      } else if (valor == '=') {
        if (_operando1.isNotEmpty && _operador.isNotEmpty) {
          double a = double.tryParse(_operando1) ?? 0;
          double b = double.tryParse(_currentNumber) ?? 0;
          double resultado = 0;
          if (_operador == '+') resultado = a + b;
          if (_operador == '-') resultado = a - b;
          if (_operador == '×') resultado = a * b;
          if (_operador == '÷') resultado = b != 0 ? a / b : 0;
          String res = resultado % 1 == 0 ? resultado.toInt().toString() : resultado.toStringAsFixed(2);
          _currentNumber = res; _displayFull = res; _operando1 = ''; _operador = ''; _novoNumero = false;
        }
      } else if (valor == '%') {
        double v = double.tryParse(_currentNumber) ?? 0;
        String res = (v / 100).toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
        _currentNumber = res;
        _displayFull = _operador.isNotEmpty ? _operando1 + _operador + res + '%' : res + '%';
      } else if (valor == ',') {
        if (!_currentNumber.contains('.')) {
          _currentNumber += '.';
          _displayFull = _operador.isNotEmpty ? _operando1 + _operador + _currentNumber : _currentNumber;
        }
      } else {
        if (_novoNumero || _currentNumber == '0') { _currentNumber = valor; _novoNumero = false; }
        else { _currentNumber += valor; }
        _displayFull = _operador.isNotEmpty ? _operando1 + _operador + _currentNumber : _currentNumber;
      }
    });
  }

  String moeda(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

  Widget _campo({required String label, required String hint, required IconData icone, required TextEditingController controller, required Color cor}) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: cor.withOpacity(0.3), width: 1.5)),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
          labelStyle: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          prefixIcon: Container(margin: EdgeInsets.all(12), padding: EdgeInsets.all(8), decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icone, color: cor, size: 20)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _campoLucro() {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF81C784).withOpacity(0.3), width: 1.5)),
      child: Row(children: [
        Container(margin: EdgeInsets.all(12), padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF81C784).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.trending_up_rounded, color: Color(0xFF81C784), size: 20)),
        Expanded(
          child: TextField(
            controller: lucroController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: lucroEmReais ? "Lucro Desejado (R\$)" : "Lucro Desejado (%)",
              labelStyle: TextStyle(color: Color(0xFF81C784), fontSize: 13, fontWeight: FontWeight.w600),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 18),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() { lucroEmReais = !lucroEmReais; lucroController.text = lucroEmReais ? '' : '30'; }),
          child: Container(
            margin: EdgeInsets.only(right: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Color(0xFF81C784).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(lucroEmReais ? 'R\$' : '%', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  Widget _cardDestaque({required String titulo, required String subtitulo, required double valor, required IconData icone, required List<Color> gradiente}) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradiente, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradiente[0].withOpacity(0.4), blurRadius: 18, offset: Offset(0, 7))],
        ),
        child: Row(children: [
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Icon(icone, color: Colors.white, size: 30)),
          SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            SizedBox(height: 4),
            Text(moeda(valor), style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            if (subtitulo.isNotEmpty) Text(subtitulo, style: TextStyle(color: Colors.white60, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }

  Widget _cardPequeno({required String titulo, required double valor, required IconData icone, required Color cor, String? extra}) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: cor.withOpacity(0.25), width: 1.2)),
        child: Row(children: [
          Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icone, color: cor, size: 18)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            SizedBox(height: 2),
            Row(children: [
              Text(moeda(valor), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              if (extra != null) ...[SizedBox(width: 8), Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(extra, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)))],
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _btn(String label, Color bg, Color fg) => _CalcButton(label: label, bg: bg, fg: fg, onTap: () => _calcBotao(label));

  Widget _calculadora() {
    return Container(
      decoration: BoxDecoration(color: Color(0xFF1A1A2E), borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]),
      padding: EdgeInsets.fromLTRB(12, 16, 12, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Calculadora", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
          GestureDetector(onTap: () => setState(() => mostrarCalc = false), child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 28)),
        ]),
        SizedBox(height: 12),
        Container(
          width: double.infinity, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(color: Color(0xFF0F0F1A), borderRadius: BorderRadius.circular(18)),
          child: Text(_displayFull, textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: _usarResultadoNoPrecificador,
          child: Container(
            width: double.infinity, padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Color(0xFF1565C0).withOpacity(0.5), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("USAR COMO CUSTO DO PRODUTO", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ]),
          ),
        ),
        SizedBox(height: 10),
        Row(children: [_btn('AC', Color(0xFF2A2A3E), Color(0xFFFF6A00)), _btn('⌫', Color(0xFF2A2A3E), Color(0xFFFF6A00)), _btn('%', Color(0xFF2A2A3E), Color(0xFFFF6A00)), _btn('÷', Color(0xFFFF6A00), Colors.white)]),
        Row(children: [_btn('7', Color(0xFF252538), Colors.white), _btn('8', Color(0xFF252538), Colors.white), _btn('9', Color(0xFF252538), Colors.white), _btn('×', Color(0xFFFF6A00), Colors.white)]),
        Row(children: [_btn('4', Color(0xFF252538), Colors.white), _btn('5', Color(0xFF252538), Colors.white), _btn('6', Color(0xFF252538), Colors.white), _btn('-', Color(0xFFFF6A00), Colors.white)]),
        Row(children: [_btn('1', Color(0xFF252538), Colors.white), _btn('2', Color(0xFF252538), Colors.white), _btn('3', Color(0xFF252538), Colors.white), _btn('+', Color(0xFFFF6A00), Colors.white)]),
        Row(children: [_btn('0', Color(0xFF252538), Colors.white), _btn(',', Color(0xFF252538), Colors.white), _btn('=', Color(0xFFFF6A00), Colors.white)]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      body: Stack(children: [
        Column(children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF9A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Color(0xFFFF6A00).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: Text("\$", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Precifica Fácil", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Calcule seu preço ideal", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                GestureDetector(
                  onTap: () => setState(() => mostrarCalc = !mostrarCalc),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: mostrarCalc ? Colors.white : Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                      boxShadow: mostrarCalc ? [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))] : [],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(mostrarCalc ? Icons.close_rounded : Icons.calculate_outlined, color: mostrarCalc ? Color(0xFFFF6A00) : Colors.white, size: 22),
                      SizedBox(width: 6),
                      Text(mostrarCalc ? "Fechar" : "Calc", style: TextStyle(color: mostrarCalc ? Color(0xFFFF6A00) : Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
              SizedBox(height: 18),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() { modoAutomatico = true; calculou = false; }),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: modoAutomatico ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.bolt_rounded, size: 15, color: modoAutomatico ? Color(0xFFFF6A00) : Colors.white70),
                        SizedBox(width: 5),
                        Text("Automático", style: TextStyle(color: modoAutomatico ? Color(0xFFFF6A00) : Colors.white70, fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                    ),
                  )),
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() { modoAutomatico = false; calculou = false; }),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: !modoAutomatico ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.tune_rounded, size: 15, color: !modoAutomatico ? Color(0xFFFF6A00) : Colors.white70),
                        SizedBox(width: 5),
                        Text("Manual", style: TextStyle(color: !modoAutomatico ? Color(0xFFFF6A00) : Colors.white70, fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                    ),
                  )),
                ]),
              ),
            ]),
          ),
          Expanded(child: ListView(padding: EdgeInsets.all(20), children: [
            SizedBox(height: 8),
            if (modoAutomatico) ...[
              Row(children: [
                Icon(Icons.store_rounded, color: Color(0xFFFF6A00), size: 14),
                SizedBox(width: 6),
                Text("SHOPEE • CÁLCULO AUTOMÁTICO", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ]),
              SizedBox(height: 12),
              _campo(label: "Custo do Produto", hint: "Ex: 50.00", icone: Icons.inventory_2_rounded, controller: produtoController, cor: Color(0xFFFF6A00)),
              _campoLucro(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white24, size: 14),
                  SizedBox(width: 8),
                  Expanded(child: Text("Comissão e taxa fixa calculadas automaticamente pela tabela Shopee", style: TextStyle(color: Colors.white24, fontSize: 11))),
                ]),
              ),
            ] else ...[
              Text("CUSTOS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              SizedBox(height: 12),
              _campo(label: "Custo do Produto", hint: "Ex: 50.00", icone: Icons.inventory_2_rounded, controller: produtoController, cor: Color(0xFFFF6A00)),
              _campo(label: "Custo da Embalagem", hint: "Ex: 2.50", icone: Icons.redeem_rounded, controller: embalagemController, cor: Color(0xFFFF9A3C)),
              _campo(label: "Taxa Fixa", hint: "Ex: 5.00", icone: Icons.receipt_rounded, controller: taxaFixaController, cor: Color(0xFFFFBF80)),
              SizedBox(height: 8),
              Text("MARGENS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              SizedBox(height: 12),
              _campo(label: "Comissão (%)", hint: "Ex: 20", icone: Icons.percent_rounded, controller: comissaoController, cor: Color(0xFF64B5F6)),
              _campo(label: "Lucro Desejado (%)", hint: "Ex: 30", icone: Icons.trending_up_rounded, controller: lucroManualController, cor: Color(0xFF81C784)),
            ],
            SizedBox(height: 16),
            GestureDetector(
              onTap: calcular,
              child: Container(
                width: double.infinity, padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF9A3C)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Color(0xFFFF6A00).withOpacity(0.5), blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text("CALCULAR PREÇO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ]),
              ),
            ),
            if (calculou) ...[
              SizedBox(height: 28),
              Text("EM DESTAQUE", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              SizedBox(height: 12),
              _cardDestaque(titulo: "PREÇO DE VENDA", subtitulo: faixaAplicada.isNotEmpty ? "Faixa: $faixaAplicada" : "Valor sugerido ao cliente", valor: preco, icone: Icons.sell_rounded, gradiente: [Color(0xFFFF6A00), Color(0xFFFF9A3C)]),
              _cardDestaque(titulo: "SEU LUCRO", subtitulo: "Ganho sobre o custo do produto", valor: lucroReais, icone: Icons.trending_up_rounded, gradiente: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
              _cardDestaque(titulo: "VALOR A RECEBER", subtitulo: "Líquido após comissão e taxa", valor: liquido, icone: Icons.account_balance_wallet_rounded, gradiente: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
              SizedBox(height: 20),
              Text("DETALHES", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              SizedBox(height: 12),
              _cardPequeno(titulo: "CUSTO DO PRODUTO", valor: custoProduto, icone: Icons.inventory_2_rounded, cor: Color(0xFFFF6A00)),
              _cardPequeno(titulo: "COMISSÃO DE VENDA", valor: comissaoValor, icone: Icons.percent_rounded, cor: Color(0xFFEF5350), extra: "${comissaoPercentual.toStringAsFixed(0)}%"),
              _cardPequeno(titulo: "TAXA FIXA", valor: taxaFixaAplicada, icone: Icons.receipt_rounded, cor: Color(0xFFFFBF80)),
              _cardPequeno(titulo: "CUSTO DA EMBALAGEM", valor: modoAutomatico ? 1.0 : (double.tryParse(embalagemController.text) ?? 0), icone: Icons.redeem_rounded, cor: Color(0xFFFF9A3C)),
              _cardPequeno(titulo: "CUSTO TOTAL", valor: custoTotal, icone: Icons.receipt_long_rounded, cor: Color(0xFF78909C)),
              SizedBox(height: 80),
            ],
          ])),
        ]),
        if (mostrarCalc)
          Positioned(bottom: 0, left: 0, right: 0, child: _calculadora()),
      ]),
    );
  }
}
