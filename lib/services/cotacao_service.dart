import 'dart:convert';
import 'package:http/http.dart' as http;

class CotacaoService {
  static Future buscarDolar() async {
    final url = Uri.parse('https://economia.awesomeapi.com.br/json/last/USD-BRL');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dados = jsonDecode(response.body);
      final usdBrl = dados['USDBRL'];

      final valor = double.tryParse(usdBrl['bid'].toString()) ?? 0.0;
      final variacao = usdBrl['pctChange'].toString();

      return {
        'valor': 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
        'variacao': '$variacao%',
      };
    } else {
      throw Exception('Erro ao buscar cotação do Dólar.');
    }
  }
}
