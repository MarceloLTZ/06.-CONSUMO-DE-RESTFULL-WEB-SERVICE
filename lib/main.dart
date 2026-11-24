import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/endereco.dart';
import 'services/via_cep_service.dart';
import 'services/cotacao_service.dart';

void main() {
  runApp(const CepApp());
}

class CepApp extends StatelessWidget {
  const CepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta CEP & Dólar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Exercício 02: Formatador de máscara visual no formato 00000-000
class CepMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numeros = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = numeros.length > 8 ? numeros.substring(0, 8) : numeros;

    final buffer = StringBuffer();
    for (int i = 0; i < limitado.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(limitado[i]);
    }

    final formatado = buffer.toString();
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cepController = TextEditingController();
  Endereco? _enderecoResult;
  bool _isLoading = false;
  String? _errorMessage;

  // Exercício 01: Histórico local das últimas buscas realizadas na tela
  final List<Endereco> _historicoBuscas = [];

  // Exercício 03: Dados da cotação do Dólar (AwesomeAPI)
  Map<String, String>? _cotacaoDolar;
  bool _isLoadingDolar = false;
  String? _erroDolar;

  @override
  void initState() {
    super.initState();
    _carregarCotacaoDolar();
  }

  /// Exercício 03: Busca a cotação do Dólar ao abrir o app
  Future<void> _carregarCotacaoDolar() async {
    setState(() {
      _isLoadingDolar = true;
      _erroDolar = null;
    });

    try {
      final dados = await CotacaoService.buscarDolar();
      setState(() {
        _cotacaoDolar = dados;
      });
    } catch (e) {
      setState(() {
        _erroDolar = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoadingDolar = false;
      });
    }
  }

  Future<void> _consultarCep() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _enderecoResult = null;
    });

    try {
      final resultado = await ViaCepService.buscarCep(_cepController.text);
      setState(() {
        _enderecoResult = resultado;

        // Exercício 01: Adiciona ao histórico local (move para o topo se já existir)
        _historicoBuscas.removeWhere((item) => item.cep == resultado.cep);
        _historicoBuscas.insert(0, resultado);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta CEP (ViaCEP API)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================================================================
            // EXERCÍCIO 03: Exibição da Cotação do Dólar (AwesomeAPI)
            // ================================================================
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cotação do Dólar (AwesomeAPI)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (_isLoadingDolar)
                          const Text('Carregando cotação...')
                        else if (_erroDolar != null)
                          Text(_erroDolar!, style: const TextStyle(color: Colors.red))
                        else if (_cotacaoDolar != null)
                          Text(
                            'USD 1,00 = ${_cotacaoDolar!['valor']} (${_cotacaoDolar!['variacao']})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: _isLoadingDolar ? null : _carregarCotacaoDolar,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Atualizar cotação',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ================================================================
            // EXERCÍCIO 02: TextField com máscara visual 00000-000
            // ================================================================
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CepMaskFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Informe o CEP',
                hintText: '00000-000',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _cepController,
                  builder: (context, value, _) {
                    final completo = value.text.length == 9;
                    return Icon(
                      completo ? Icons.check_circle : Icons.edit,
                      color: completo ? Colors.green : Colors.grey,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _consultarCep,
              icon: const Icon(Icons.search),
              label: const Text('Buscar Endereço'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            if (_enderecoResult != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _enderecoResult!.logradouro,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Bairro: ${_enderecoResult!.bairro}'),
                      Text('Cidade/UF: ${_enderecoResult!.localidade} - ${_enderecoResult!.uf}'),
                      Text('CEP: ${_enderecoResult!.cep}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ================================================================
            // EXERCÍCIO 01: Histórico local das últimas buscas realizadas
            // ================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Histórico das Últimas Buscas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_historicoBuscas.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _historicoBuscas.clear()),
                    child: const Text('Limpar'),
                  ),
              ],
            ),
            const Divider(),
            if (_historicoBuscas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhuma busca realizada ainda.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historicoBuscas.length,
                itemBuilder: (context, index) {
                  final item = _historicoBuscas[index];
                  return ListTile(
                    leading: const Icon(Icons.history, color: Colors.indigo),
                    title: Text('${item.cep} - ${item.logradouro}'),
                    subtitle: Text('${item.bairro}, ${item.localidade}/${item.uf}'),
                    onTap: () {
                      _cepController.text = item.cep;
                      _consultarCep();
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
