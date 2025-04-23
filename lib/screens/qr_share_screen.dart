import 'dart:io'; // Added for HttpServer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../providers/app_state.dart';
import '../theme.dart';
import '../services/data_manager.dart';
import '../models/cart.dart';
import '../models/stock.dart';
import '../models/daily_record.dart';
import '../models/expense.dart';

class QrShareScreen extends StatefulWidget {
  const QrShareScreen({super.key});

  @override
  _QrShareScreenState createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MobileScannerController _scannerController;
  bool _isGeneratingQr = false;
  String _qrData = '';
  String? _errorMessage; // Added to handle errors separately
  bool _isScanning = false;
  String _scanResult = '';
  bool _isImporting = false;
  HttpServer? _server; // Store the server instance to manage it

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController();
    _generateQrCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    _server?.close(); // Ensure server is closed when widget is disposed
    super.dispose();
  }

  Future<String> _getDataToShare() async {
    final prefs = await SharedPreferences.getInstance();
    final dataToShare = {
      'carts': prefs.getString(DataManager.cartKey) ?? '[]',
      'stocks': prefs.getString(DataManager.stockKey) ?? '[]',
      'daily_records': prefs.getString(DataManager.dailyRecordKey) ?? '[]',
      'expenses': prefs.getString(DataManager.expenseKey) ?? '[]',
    };
    return jsonEncode(dataToShare); // Return raw JSON string
  }

  Future<void> _generateQrCode() async {
    setState(() {
      _isGeneratingQr = true;
      _qrData = '';
      _errorMessage = null; // Reset error message
    });

    try {
      // Close existing server if it exists
      if (_server != null) {
        await _server!.close();
        _server = null;
      }

      final data = await _getDataToShare();
      final info = NetworkInfo();
      String? wifiIP = await info.getWifiIP();

      // If wifiIP is null, try to get the hotspot IP
      wifiIP ??= await _getHotspotIP();

      if (wifiIP == null) {
        throw Exception('Impossible de trouver l\'adresse IP');
      }

      final token = Uuid().v4(); // Generate a unique token
      final url = 'http://$wifiIP:8080/data?token=$token';

      // Set up the server handler
      final handler = Pipeline().addMiddleware(logRequests()).addHandler((request) async {
        if (request.url.queryParameters['token'] == token) {
          final response = Response.ok(data, headers: {'Content-Type': 'application/json'});
          // Close the server after a short delay to ensure response is sent
          Future.delayed(Duration(seconds: 1), () {
            _server?.close();
          });
          return response;
        }
        return Response.forbidden('Invalid token');
      });

      // Start the server with shared: true to allow multiple bindings
      _server = await io.serve(handler, wifiIP, 8080, shared: true);

      setState(() {
        _qrData = url;
        _isGeneratingQr = false;
      });

      // Optional: Close server after 5 minutes if not accessed
      Future.delayed(Duration(minutes: 5), () {
        _server?.close();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isGeneratingQr = false;
      });
    }
  }

  Future<String?> _getHotspotIP() async {
    // For Android, the hotspot IP is usually 192.168.43.1
    // This is a simple check, a more robust solution may be needed
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (address.address.startsWith('192.168.')) {
            return address.address;
          }
        }
      }
    } catch (e) {
      print('Error getting hotspot IP: $e');
    }
    return null;
  }

  Future<void> _importData(String url) async {
    setState(() {
      _isImporting = true;
      _scanResult = 'Importation en cours...';
    });

    try {
      // Fetch data from the URL
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Échec de la récupération des données: ${response.statusCode}');
      }

      final appState = Provider.of<AppState>(context, listen: false);
      final dataManager = DataManager();
      final jsonString = response.body;
      final Map<String, dynamic> importedData = jsonDecode(jsonString);

      // Load current data
      List<Cart> currentCarts = await dataManager.getCarts();
      List<Stock> currentStocks = await dataManager.getStocks();
      List<DailyRecord> currentRecords = await dataManager.getDailyRecords();
      List<Expense> currentExpenses = await dataManager.getExpenses();

      // Parse imported data
      List<dynamic> importedCartsJson = jsonDecode(importedData['carts'] ?? '[]');
      List<dynamic> importedStocksJson = jsonDecode(importedData['stocks'] ?? '[]');
      List<dynamic> importedRecordsJson = jsonDecode(importedData['daily_records'] ?? '[]');
      List<dynamic> importedExpensesJson = jsonDecode(importedData['expenses'] ?? '[]');

      List<Cart> importedCarts = importedCartsJson.map((json) => Cart.fromJson(json)).toList();
      List<Stock> importedStocks = importedStocksJson.map((json) => Stock.fromJson(json)).toList();
      List<DailyRecord> importedRecords = importedRecordsJson.map((json) => DailyRecord.fromJson(json)).toList();
      List<Expense> importedExpenses = importedExpensesJson.map((json) => Expense.fromJson(json)).toList();

      // Merge data, avoiding duplicates by ID
      Set<String> currentCartIds = currentCarts.map((cart) => cart.id).toSet();
      Set<String> currentStockIds = currentStocks.map((stock) => stock.id).toSet();
      Set<String> currentRecordIds = currentRecords.map((record) => record.id).toSet();
      Set<String> currentExpenseIds = currentExpenses.map((expense) => expense.id).toSet();

      for (var cart in importedCarts) {
        if (!currentCartIds.contains(cart.id)) currentCarts.add(cart);
      }
      for (var stock in importedStocks) {
        if (!currentStockIds.contains(stock.id)) currentStocks.add(stock);
      }
      for (var record in importedRecords) {
        if (!currentRecordIds.contains(record.id)) currentRecords.add(record);
      }
      for (var expense in importedExpenses) {
        if (!currentExpenseIds.contains(expense.id)) currentExpenses.add(expense);
      }

      // Save merged data
      await dataManager.saveCarts(currentCarts);
      await dataManager.saveStocks(currentStocks);
      await dataManager.saveDailyRecords(currentRecords);
      await dataManager.saveExpenses(currentExpenses);

      await appState.loadAll();

      setState(() {
        _isImporting = false;
        _scanResult = 'Importation réussie!';
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _scanResult = 'Erreur d\'importation: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partage de Données'),
        backgroundColor: AppTheme.primaryColor,
        
        bottom: TabBar(
          labelColor: AppTheme.textOnPrimaryColor,
          unselectedLabelColor: AppTheme.textOnPrimaryColor,
          controller: _tabController,
          tabs: [
            Tab(text: 'Partager', icon: Icon(Icons.qr_code)),
            Tab(text: 'Scanner', icon: Icon(Icons.qr_code_scanner)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShareTab(),
          _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildShareTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Partager les données',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      'Montrez ce QR code à l\'autre appareil pour partager vos données.\n\n'
                      'Assurez-vous que votre hotspot est activé et que l\'autre appareil est connecté à votre hotspot.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  SizedBox(height: 30),
                  if (_isGeneratingQr)
                    CircularProgressIndicator()
                  else if (_qrData.isNotEmpty && _errorMessage == null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 280,
                        embeddedImage: NetworkImage(
                            "https://pixabay.com/get/g8489b41f4618ce5af3a75227878220170cdbf0d49bf561b7a5220f429062d81233aa222d788113986e7e84a1eeb8524bbc9a44112f51c9583bcab18a410011e9_1280.jpg"),
                        embeddedImageStyle: QrEmbeddedImageStyle(
                          size: Size(60, 60),
                        ),
                      ),
                    ),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _generateQrCode,
                    icon: Icon(Icons.refresh),
                    label: Text('Actualiser le QR code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Important',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pour partager vos données :\n'
                    '1. Activez votre hotspot.\n'
                    '2. Assurez-vous que l\'autre appareil est connecté à votre hotspot.\n'
                    '3. Montrez le QR code à l\'autre appareil pour qu\'il puisse scanner et importer les données.\n\n'
                    'Les données importées seront ajoutées à celles déjà présentes sur l\'autre appareil.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: _isScanning
                ? MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
                        final String? qrValue = barcodes[0].rawValue;
                        if (qrValue != null && qrValue.isNotEmpty) {
                          _scannerController.stop();
                          setState(() {
                            _isScanning = false;
                            _scanResult = 'QR Code détecté! Analyse des données...';
                          });
                          _importData(qrValue);
                        }
                      }
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Scanner un QR code',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Appuyez sur le bouton ci-dessous pour commencer',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              if (_scanResult.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _scanResult.contains('réussie')
                        ? Colors.green.withOpacity(0.1)
                        : _scanResult.contains('Erreur')
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _scanResult.contains('réussie')
                            ? Icons.check_circle
                            : _scanResult.contains('Erreur')
                                ? Icons.error
                                : Icons.info,
                        color: _scanResult.contains('réussie')
                            ? Colors.green
                            : _scanResult.contains('Erreur')
                                ? Colors.red
                                : Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _scanResult,
                          style: TextStyle(
                            color: _scanResult.contains('réussie')
                                ? Colors.green
                                : _scanResult.contains('Erreur')
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _isImporting
                    ? null
                    : () {
                        setState(() {
                          _isScanning = !_isScanning;
                          _scanResult = '';
                        });
                        if (_isScanning) {
                          _scannerController.start();
                        } else {
                          _scannerController.stop();
                        }
                      },
                icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                label: Text(_isScanning ? 'Arrêter le scan' : 'Commencer le scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.red : AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              if (_isImporting) ...[
                SizedBox(height: 16),
                LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}