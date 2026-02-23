import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
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
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Color(0xFF0F0F1A),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final produtoController = TextEditingController();
  final embalagemController = TextEditingController();
  final taxaFixaController = TextEditingController();
  final comissaoController = TextEditingController();
  final lucroController = TextEditingController();

  double preco = 0;
  double lucroReais = 0;
  double comissaoValor = 0;
  double liquido = 0;
  double custoTotal = 0;
  bool calculou = false;
  bool mostrarCalc = false;

  String _display = '0';
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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void calcular() {
    double cp = double.tryParse(produtoController.text.replaceAll(',', '.')) ?? 0;
    double ce = double.tryParse(embalagemController.text.replaceAll(',', '.')) ?? 0;
    double tf = double.tryParse(taxaFixaController.text.replaceAll(',', '.')) ?? 0;
    double tc = (double.tryParse(comissaoController.text.replaceAll(',', '.')) ?? 0) / 100;
    double lc = (double.tryParse(lucroController.text.replaceAll(',', '.')) ?? 0) / 100;
    double lucroCalc = cp * lc;
    double base = cp + ce + tf + lucroCalc;
    double precoVenda = tc < 1 ? base / (1 - tc) : 0;
    double comissaoCalc = precoVenda * tc;
    double liquidoCalc = precoVenda - comissaoCalc;
    double custoCalc = cp + ce + tf;

    setState(() {
      preco = precoVenda;
      lucroReais = lucroCalc;
      comissaoValor = comissaoCalc;
      liquido = liquidoCalc;
      custoTotal = custoCalc;
      calculou = true;
    });
    _animController.reset();
    _animController.forward();
  }

  void _calcBotao(String valor) {
    setState(() {
      if (valor == 'AC') {
        _display = '0';
        _operando1 = '';
        _operador = '';
        _novoNumero = false;
      } else if (valor == '⌫') {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
      } else if (['+', '-', '×', '÷'].contains(valor)) {
        _operando1 = _display;
        _operador = valor;
        _novoNumero = true;
      } else if (valor == '=') {
        if (_operando1.isNotEmpty && _operador.isNotEmpty) {
          double a = double.tryParse(_operando1) ?? 0;
          double b = double.tryParse(_display) ?? 0;
          double resultado = 0;
          if (_operador == '+') resultado = a + b;
          if (_operador == '-') resultado = a - b;
          if (_operador == '×') resultado = a * b;
          if (_operador == '÷') resultado = b != 0 ? a / b : 0;
          _display = resultado % 1 == 0 ? resultado.toInt().toString() : resultado.toStringAsFixed(2);
          _operando1 = '';
          _operador = '';
          _novoNumero = false;
        }
      } else if (valor == '%') {
        double v = double.tryParse(_display) ?? 0;
        _display = (v / 100).toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      } else if (valor == ',') {
        if (!_display.contains('.')) _display += '.';
      } else {
        if (_novoNumero || _display == '0') {
          _display = valor;
          _novoNumero = false;
        } else {
          _display += valor;
        }
      }
    });
  }

  String moeda(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

  Widget _campo({
    required String label,
    required String hint,
    required IconData icone,
    required TextEditingController controller,
    required Color cor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.3), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
          labelStyle: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: cor, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _cardResultado({
    required String titulo,
    required String subtitulo,
    required double valor,
    required IconData icone,
    required List<Color> gradiente,
    bool destaque = false,
  }) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradiente, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradiente[0].withOpacity(0.35), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: Icon(icone, color: Colors.white, size: destaque ? 28 : 22),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  SizedBox(height: 4),
                  Text(moeda(valor), style: TextStyle(color: Colors.white, fontSize: destaque ? 26 : 20, fontWeight: FontWeight.bold)),
                  if (subtitulo.isNotEmpty)
                    Text(subtitulo, style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoCalc(String label, Color bg, Color fg) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _calcBotao(label),
        child: Container(
          margin: EdgeInsets.all(5),
          height: 64,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Text(label, style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _calculadora() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      padding: EdgeInsets.fromLTRB(12, 16, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Calculadora", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => setState(() => mostrarCalc = false),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 28),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(color: Color(0xFF0F0F1A), borderRadius: BorderRadius.circular(18)),
            child: Text(_display, textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 10),
          Row(children: [
            _botaoCalc('AC', Color(0xFF2A2A3E), Color(0xFFFF6A00)),
            _botaoCalc('⌫', Color(0xFF2A2A3E), Color(0xFFFF6A00)),
            _botaoCalc('%', Color(0xFF2A2A3E), Color(0xFFFF6A00)),
            _botaoCalc('÷', Color(0xFFFF6A00), Colors.white),
          ]),
          Row(children: [
            _botaoCalc('7', Color(0xFF252538), Colors.white),
            _botaoCalc('8', Color(0xFF252538), Colors.white),
            _botaoCalc('9', Color(0xFF252538), Colors.white),
            _botaoCalc('×', Color(0xFFFF6A00), Colors.white),
          ]),
          Row(children: [
            _botaoCalc('4', Color(0xFF252538), Colors.white),
            _botaoCalc('5', Color(0xFF252538), Colors.white),
            _botaoCalc('6', Color(0xFF252538), Colors.white),
            _botaoCalc('-', Color(0xFFFF6A00), Colors.white),
          ]),
          Row(children: [
            _botaoCalc('1', Color(0xFF252538), Colors.white),
            _botaoCalc('2', Color(0xFF252538), Colors.white),
            _botaoCalc('3', Color(0xFF252538), Colors.white),
            _botaoCalc('+', Color(0xFFFF6A00), Colors.white),
          ]),
          Row(children: [
            _botaoCalc('0', Color(0xFF252538), Colors.white),
            _botaoCalc(',', Color(0xFF252538), Colors.white),
            _botaoCalc('=', Color(0xFFFF6A00), Colors.white),
            _botaoCalc('=', Colors.transparent, Colors.transparent),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => mostrarCalc = !mostrarCalc),
        backgroundColor: Color(0xFFFF6A00),
        child: Icon(mostrarCalc ? Icons.close : Icons.calculate_rounded, color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(24, 56, 24, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF9A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Color(0xFFFF6A00).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Precifica Fácil", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text("Calcule seu preço ideal", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    SizedBox(height: 8),
                    Text("CUSTOS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    SizedBox(height: 12),
                    _campo(label: "Custo do Produto", hint: "Ex: 50.00", icone: Icons.inventory_2_rounded, controller: produtoController, cor: Color(0xFFFF6A00)),
                    _campo(label: "Custo da Embalagem", hint: "Ex: 2.50", icone: Icons.redeem_rounded, controller: embalagemController, cor: Color(0xFFFF9A3C)),
                    _campo(label: "Taxa Fixa", hint: "Ex: 5.00", icone: Icons.receipt_rounded, controller: taxaFixaController, cor: Color(0xFFFFBF80)),
                    SizedBox(height: 8),
                    Text("MARGENS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    SizedBox(height: 12),
                    _campo(label: "Comissão (%)", hint: "Ex: 20", icone: Icons.percent_rounded, controller: comissaoController, cor: Color(0xFF64B5F6)),
                    _campo(label: "Lucro Desejado (%)", hint: "Ex: 30", icone: Icons.trending_up_rounded, controller: lucroController, cor: Color(0xFF81C784)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: calcular,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF9A3C)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Color(0xFFFF6A00).withOpacity(0.5), blurRadius: 16, offset: Offset(0, 6))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text("CALCULAR PREÇO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                    ),
                    if (calculou) ...[
                      SizedBox(height: 28),
                      Text("RESULTADOS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                      SizedBox(height: 12),
                      _cardResultado(titulo: "PREÇO DE VENDA", subtitulo: "Valor sugerido ao cliente", valor: preco, icone: Icons.sell_rounded, gradiente: [Color(0xFFFF6A00), Color(0xFFFF9A3C)], destaque: true),
                      _cardResultado(titulo: "SEU LUCRO", subtitulo: "Ganho sobre o produto", valor: lucroReais, icone: Icons.trending_up_rounded, gradiente: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
                      _cardResultado(titulo: "VALOR LÍQUIDO", subtitulo: "Após descontar comissão", valor: liquido, icone: Icons.account_balance_wallet_rounded, gradiente: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                      _cardResultado(titulo: "COMISSÃO", subtitulo: "Taxa da plataforma", valor: comissaoValor, icone: Icons.percent_rounded, gradiente: [Color(0xFFC62828), Color(0xFFEF5350)]),
                      _cardResultado(titulo: "CUSTO TOTAL", subtitulo: "Produto + embalagem + taxa", valor: custoTotal, icone: Icons.receipt_long_rounded, gradiente: [Color(0xFF37474F), Color(0xFF78909C)]),
                      SizedBox(height: 80),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (mostrarCalc)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _calculadora(),
            ),
        ],
      ),
    );
  }
}