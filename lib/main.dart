import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(PrecificaApp());
}

class PrecificaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precifica Fácil',
      theme: ThemeData(
        primaryColor: Color(0xFFFF6A00),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  void calcular() {
    double cp = double.tryParse(produtoController.text) ?? 0;
    double ce = double.tryParse(embalagemController.text) ?? 0;
    double tf = double.tryParse(taxaFixaController.text) ?? 0;
    double tc = (double.tryParse(comissaoController.text) ?? 0) / 100;
    double lc = (double.tryParse(lucroController.text) ?? 0) / 100;

    double lucroCalc = cp * lc;
    double base = cp + ce + tf + lucroCalc;

    double precoVenda = base / (1 - tc);

    double comissaoCalc = precoVenda * tc;
    double liquidoCalc = precoVenda - comissaoCalc;
    double custoCalc = cp + ce + tf;

    setState(() {
      preco = precoVenda;
      lucroReais = lucroCalc;
      comissaoValor = comissaoCalc;
      liquido = liquidoCalc;
      custoTotal = custoCalc;
    });
  }

  Widget campo(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  String moeda(double valor) {
    return "R\$ ${valor.toStringAsFixed(2)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Precifica Fácil"),
        backgroundColor: Color(0xFFFF6A00),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            campo("Custo do Produto (R\$)", produtoController),
            campo("Custo Embalagem (R\$)", embalagemController),
            campo("Taxa Fixa (R\$)", taxaFixaController),
            campo("Comissão (%)", comissaoController),
            campo("Lucro (% sobre produto)", lucroController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: calcular,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6A00),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                "CALCULAR PREÇO",
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Text("Preço de Venda: ${moeda(preco)}",
                style: TextStyle(fontSize: 18)),
            Text("Lucro: ${moeda(lucroReais)}"),
            Text("Comissão: ${moeda(comissaoValor)}"),
            Text("Valor Líquido: ${moeda(liquido)}"),
            Text("Custo Total: ${moeda(custoTotal)}"),
          ],
        ),
      ),
    );
  }
}
