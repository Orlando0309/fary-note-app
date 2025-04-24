import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final amountFormat = NumberFormat('#,##0.00', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion du Stock'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_animation),
              child: Column(
                children: [
                  // Résumé du stock actuel
                  FutureBuilder<double>(
                    future: appState.getCurrentStockQuantity(),
                    builder: (context, snapshot) {
                      double currentStock = snapshot.data ?? 0;
                      return Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock Disponible',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${currentStock.toStringAsFixed(2)} kg',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: currentStock > 50 
                                    ? Colors.green.withOpacity(0.2) 
                                    : currentStock > 20 
                                        ? Colors.orange.withOpacity(0.2) 
                                        : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                currentStock > 50 
                                    ? 'élevé' 
                                    : currentStock > 20 
                                        ? 'Moyen' 
                                        : 'Bas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Liste des arrivages
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Historique des arrivages',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () => appState.loadStocks(),
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  
                  appState.stocks.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun arrivage enregistré',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ajoutez un nouvel arrivage de stock',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: appState.stocks.length,
                            itemBuilder: (context, index) {
                              final stock = appState.stocks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Arrivage du ${dateFormat.format(stock.arrivalDate)}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                '${stock.quantity.toStringAsFixed(2)} kg',
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildInfoItem(
                                                context,
                                                title: 'Prix d\'achat',
                                                value: '${amountFormat.format(stock.purchasePrice)} Ar',
                                                icon: Icons.monetization_on,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: _buildInfoItem(
                                                context,
                                                title: 'Fournisseur',
                                                value: stock.supplier.isEmpty ? 'Non spécifié' : stock.supplier,
                                                icon: Icons.person,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (stock.notes.isNotEmpty) ...[  
                                          SizedBox(height: 12),
                                          Text(
                                            'Remarques: ${stock.notes}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showAddEditStockDialog(context, stock),
                                                icon: Icon(Icons.edit, color: AppTheme.primaryColor),
                                                label: Text('Modifier'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _deleteStock(context, stock),
                                                icon: Icon(Icons.delete, color: AppTheme.errorColor),
                                                label: Text('Supprimer'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppTheme.errorColor,
                                                  side: BorderSide(color: AppTheme.errorColor),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditStockDialog(context),
        label: Text('Ajouter un arrivage'),
        icon: Icon(Icons.add),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddEditStockDialog(BuildContext context, [Stock? existingStock]) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController supplierController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    if (existingStock != null) {
      quantityController.text = existingStock.quantity.toString();
      priceController.text = existingStock.purchasePrice.toString();
      supplierController.text = existingStock.supplier;
      notesController.text = existingStock.notes;
      selectedDate = existingStock.arrivalDate;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingStock == null ? 'Ajouter un arrivage' : 'Modifier l\'arrivage'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Date d\'arrivage'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantité (kg)',
                      hintText: 'Ex: 100',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Prix d\'achat',
                      hintText: 'Ex: 50000',
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: supplierController,
                    decoration: InputDecoration(
                      labelText: 'Fournisseur (optionnel)',
                      hintText: 'Ex: Coopérative Canne Verte',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Remarques (optionnel)',
                      hintText: 'Ex: Qualité exceptionelle',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validation
                  if (quantityController.text.trim().isEmpty ||
                      priceController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                    );
                    return;
                  }

                  try {
                    final quantity = double.parse(quantityController.text.trim());
                    final price = double.parse(priceController.text.trim());

                    if (quantity <= 0 || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Les valeurs doivent u00eatre supérieures à zéro')),
                      );
                      return;
                    }

                    final stock = Stock(
                      id: existingStock?.id ?? '',
                      arrivalDate: selectedDate,
                      quantity: quantity,
                      purchasePrice: price,
                      supplier: supplierController.text.trim(),
                      notes: notesController.text.trim(),
                    );

                    if (existingStock == null) {
                      Provider.of<AppState>(context, listen: false).addStock(stock);
                    } else {
                      Provider.of<AppState>(context, listen: false).updateStock(stock);
                    }

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: Assurez-vous que les valeurs sont des nombres valides')),
                    );
                  }
                },
                child: Text(existingStock == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteStock(BuildContext context, Stock stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('êtes-vous sûr de vouloir supprimer cet arrivage de ${stock.quantity.toStringAsFixed(2)} kg ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).deleteStock(stock.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Arrivage supprimé avec succès')),
              );
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}