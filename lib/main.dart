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
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
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
          boxShadow: [
            BoxShadow(color: gradiente[0].withOpacity(0.35), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, 56, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6A00), Color(0xFFFF9A3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(color: Color(0xFFFF6A00).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8)),
              ],
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
                    Text("Precifica Fácil", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
                  SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
