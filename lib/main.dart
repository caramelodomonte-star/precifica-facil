
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:math_expressions/math_expressions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 600),
    center: true,
    minimumSize: Size(600, 400),
    title: "Precificador",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = "";
  String _result = "0";
  List<String> _history = [];

  void _onPressed(String value) {
    setState(() {
      if (value == 'AC') {
        _expression = "";
        _result = "0";
      } else if (value == '=') {
        _calculateFinal();
      } else if (value == '%') {
        _expression += "/100";
      } else if (value == '×') {
        _expression += "*";
      } else if (value == '÷') {
        _expression += "/";
      } else {
        _expression += value;
      }

      _calculatePreview();
    });
  }

  void _calculatePreview() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(_expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      _result = eval.toStringAsFixed(2);
    } catch (_) {}
  }

  void _calculateFinal() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(_expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      _history.insert(0, "$_expression = $eval");

      _result = eval.toStringAsFixed(2);
      _expression = _result;
    } catch (e) {
      _result = "Erro";
    }
  }

  Widget _buildButton(String text) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _onPressed(text),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              children: _history.map((e) => Text(e)).toList(),
            ),
          ),
          Text(_expression, style: TextStyle(fontSize: 20)),
          Text(_result, style: TextStyle(fontSize: 30)),
          Column(
            children: [
              Row(children: ["7","8","9","÷"].map(_buildButton).toList()),
              Row(children: ["4","5","6","×"].map(_buildButton).toList()),
              Row(children: ["1","2","3","-"].map(_buildButton).toList()),
              Row(children: ["0",".","%","+"].map(_buildButton).toList()),
              Row(children: ["AC","="].map(_buildButton).toList()),
            ],
          )
        ],
      ),
    );
  }
}
