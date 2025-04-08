import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/daily_record.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class DailyRecordScreen extends StatefulWidget {
  const DailyRecordScreen({super.key});

  @override
  _DailyRecordScreenState createState() => _DailyRecordScreenState();
}

class _DailyRecordScreenState extends State<DailyRecordScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedTabIndex = 0; // 0 = Attribution, 1 = Ventes

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Fiches Journalières'),
          backgroundColor: AppTheme.primaryColor,
          bottom: TabBar(
            labelColor: AppTheme.textOnPrimaryColor,
            unselectedLabelColor: AppTheme.textOnPrimaryColor,
            
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            
            tabs: [
              Tab(text: 'Attribution des Cannes'),
              Tab(text: 'Enregistrement des Ventes'),
            ],
          ),
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
                child: TabBarView(
                  children: [
                    // Tab 1: Attribution des cannes aux chariots
                    _buildAssignmentTabContent(context, appState),
                    
                    // Tab 2: Enregistrement des ventes des chariots
                    _buildSalesTabContent(context, appState),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: _selectedTabIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showAddAssignmentDialog(context),
                label: Text('Attribuer des cannes'),
                icon: Icon(Icons.add),
                backgroundColor: AppTheme.accentColor,
              )
            : FloatingActionButton.extended(
                onPressed: () => _showAddSalesDialog(context),
                label: Text('Enregistrer des ventes'),
                icon: Icon(Icons.attach_money),
                backgroundColor: AppTheme.accentColor,
              ),
      ),
    );
  }

  Widget _buildAssignmentTabContent(BuildContext context, AppState appState) {
    final assignmentRecords = appState.dailyRecords
        .where((record) => record.assignedQuantity > 0 && record.soldQuantity == 0)
        .toList();

    if (assignmentRecords.isEmpty) {
      return _buildEmptyState(
        context, 
        icon: Icons.assignment_outlined,
        title: 'Aucune attribution enregistrée',
        message: 'Attribuez des cannes à vos chariots',
      );
    }

    return _buildRecordsList(context, appState, assignmentRecords, isAssignment: true);
  }

  Widget _buildSalesTabContent(BuildContext context, AppState appState) {
    final salesRecords = appState.dailyRecords
        .where((record) => record.soldQuantity > 0)
        .toList();

    if (salesRecords.isEmpty) {
      return _buildEmptyState(
        context, 
        icon: Icons.monetization_on_outlined,
        title: 'Aucune vente enregistrée',
        message: 'Enregistrez les ventes de vos chariots',
      );
    }

    return _buildRecordsList(context, appState, salesRecords, isAssignment: false);
  }

  Widget _buildEmptyState(BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          _selectedTabIndex == 0
              ? ElevatedButton.icon(
                  onPressed: () => _showAddAssignmentDialog(context),
                  icon: Icon(Icons.add),
                  label: Text('Attribuer des cannes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () => _showAddSalesDialog(context),
                  icon: Icon(Icons.attach_money),
                  label: Text('Enregistrer des ventes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, AppState appState, List<DailyRecord> records, {required bool isAssignment}) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final amountFormat = NumberFormat('#,##0.00', 'fr_FR');

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final cart = appState.getCartById(record.cartId);
        
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cart?.name ?? 'Chariot inconnu',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Date: ${dateFormat.format(record.date)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAssignment
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isAssignment
                              ? 'Attribution'
                              : 'Ventes',
                          style: TextStyle(
                            color: isAssignment
                                ? AppTheme.primaryColor
                                : AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          title: 'Quantité attribuée',
                          value: '${record.assignedQuantity.toStringAsFixed(2)} kg',
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                        ),
                      ),
                      if (!isAssignment) ...[  
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            title: 'Quantité vendue',
                            value: '${record.soldQuantity.toStringAsFixed(2)} kg',
                            icon: Icons.shopping_cart_checkout,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isAssignment) ...[  
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            title: 'Montant versé',
                            value: '${amountFormat.format(record.amountCollected)} Ar',
                            icon: Icons.monetization_on,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            title: 'Rendement',
                            value: record.assignedQuantity > 0
                                ? '${(record.soldQuantity / record.assignedQuantity * 100).toStringAsFixed(0)}%'
                                : 'N/A',
                            icon: Icons.trending_up,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (record.remarks.isNotEmpty) ...[  
                    SizedBox(height: 12),
                    Text(
                      'Remarques: ${record.remarks}',
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
                          onPressed: () => isAssignment
                              ? _showAddAssignmentDialog(context, record)
                              : _showAddSalesDialog(context, record),
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
                          onPressed: () => _deleteRecord(context, record),
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

  void _showAddAssignmentDialog(BuildContext context, [DailyRecord? existingRecord]) {
    final appState = Provider.of<AppState>(context, listen: false);
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController remarksController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? selectedCartId;

    if (existingRecord != null) {
      quantityController.text = existingRecord.assignedQuantity.toString();
      remarksController.text = existingRecord.remarks;
      selectedDate = existingRecord.date;
      selectedCartId = existingRecord.cartId;
    }

    // Vérifier s'il y a des chariots disponibles
    if (appState.carts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ajoutez d\'abord des chariots avant d\'attribuer des cannes')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingRecord == null ? 'Attribuer des cannes' : 'Modifier l\'attribution'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Date'),
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
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Chariot',
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                    value: selectedCartId,
                    hint: Text('Sélectionnez un chariot'),
                    items: appState.carts
                        .where((cart) => cart.isActive)
                        .map((cart) => DropdownMenuItem(
                              value: cart.id,
                              child: Text(cart.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCartId = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantité de canne (kg)',
                      hintText: 'Ex: 50',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: 'Remarques (optionnel)',
                      hintText: 'Ex: Cannes fraiu00eechement coups',
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
                onPressed: () async {
                  // Validation
                  if (selectedCartId == null || quantityController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                    );
                    return;
                  }

                  try {
                    final quantity = double.parse(quantityController.text.trim());

                    if (quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('La quantité doit u00eatre supérieure à zéro')),
                      );
                      return;
                    }

                    // Vérifier s'il y a assez de stock disponible
                    final currentStock = await appState.getCurrentStockQuantity();
                    if (currentStock < quantity && existingRecord == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Stock insuffisant! Disponible: ${currentStock.toStringAsFixed(2)} kg')),
                      );
                      return;
                    }

                    final record = DailyRecord(
                      id: existingRecord?.id ?? '',
                      date: selectedDate,
                      cartId: selectedCartId!,
                      assignedQuantity: quantity,
                      soldQuantity: existingRecord?.soldQuantity ?? 0,
                      amountCollected: existingRecord?.amountCollected ?? 0,
                      remarks: remarksController.text.trim(),
                    );

                    if (existingRecord == null) {
                      await appState.addDailyRecord(record);
                    } else {
                      await appState.updateDailyRecord(record);
                    }

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: Assurez-vous que les valeurs sont des nombres valides')),
                    );
                  }
                },
                child: Text(existingRecord == null ? 'Attribuer' : 'Modifier'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSalesDialog(BuildContext context, [DailyRecord? existingRecord]) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Pour un nouvel enregistrement, nous devons d'abord choisir une attribution
    if (existingRecord == null) {
      _selectAssignmentFirst(context);
      return;
    }
    
    // Pour modifier un enregistrement existant
    final TextEditingController soldQuantityController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController remarksController = TextEditingController();
    
    soldQuantityController.text = existingRecord.soldQuantity.toString();
    amountController.text = existingRecord.amountCollected.toString();
    remarksController.text = existingRecord.remarks;
    
    final cart = appState.getCartById(existingRecord.cartId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enregistrer les ventes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Chariot'),
                subtitle: Text(cart?.name ?? 'Chariot inconnu'),
                leading: Icon(Icons.shopping_cart),
              ),
              Divider(),
              ListTile(
                title: Text('Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(existingRecord.date)),
                leading: Icon(Icons.calendar_today),
              ),
              Divider(),
              ListTile(
                title: Text('Quantité attribuée'),
                subtitle: Text('${existingRecord.assignedQuantity.toStringAsFixed(2)} kg'),
                leading: Icon(Icons.inventory_2),
              ),
              SizedBox(height: 16),
              TextField(
                controller: soldQuantityController,
                decoration: InputDecoration(
                  labelText: 'Quantité vendue (kg)',
                  hintText: 'Ex: 45',
                  prefixIcon: Icon(Icons.shopping_cart_checkout),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Montant versé',
                  hintText: 'Ex: 90000',
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(
                  labelText: 'Remarques (optionnel)',
                  hintText: 'Ex: Excellentes ventes au marché central',
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
              if (soldQuantityController.text.trim().isEmpty ||
                  amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                );
                return;
              }

              try {
                final soldQuantity = double.parse(soldQuantityController.text.trim());
                final amount = double.parse(amountController.text.trim());

                if (soldQuantity <= 0 || amount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Les valeurs doivent u00eatre positives')),
                  );
                  return;
                }

                if (soldQuantity > existingRecord.assignedQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('La quantité vendue ne peut pas dépasser la quantité attribuée')),
                  );
                  return;
                }

                final updatedRecord = existingRecord.copyWith(
                  soldQuantity: soldQuantity,
                  amountCollected: amount,
                  remarks: remarksController.text.trim(),
                );

                appState.updateDailyRecord(updatedRecord);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: Assurez-vous que les valeurs sont des nombres valides')),
                );
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _selectAssignmentFirst(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Récupérer les attributions qui n'ont pas encore de ventes enregistrées
    final pendingAssignments = appState.dailyRecords
        .where((record) => record.assignedQuantity > 0 && record.soldQuantity == 0)
        .toList();
    
    if (pendingAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attribuez d\'abord des cannes aux chariots avant d\'enregistrer des ventes')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sélectionner une attribution'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: pendingAssignments.map((record) {
              final cart = appState.getCartById(record.cartId);
              return ListTile(
                title: Text(cart?.name ?? 'Chariot inconnu'),
                subtitle: Text('${DateFormat('dd/MM/yyyy').format(record.date)} - ${record.assignedQuantity.toStringAsFixed(2)} kg'),
                leading: Icon(Icons.shopping_cart),
                onTap: () {
                  Navigator.pop(context);
                  _showSalesFormForAssignment(context, record);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showSalesFormForAssignment(BuildContext context, DailyRecord assignment) {
    final appState = Provider.of<AppState>(context, listen: false);
    final TextEditingController soldQuantityController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController remarksController = TextEditingController();
    
    // Par défaut, on sugguère la quantité attribuée comme quantité vendue
    soldQuantityController.text = assignment.assignedQuantity.toString();
    remarksController.text = assignment.remarks;
    
    final cart = appState.getCartById(assignment.cartId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enregistrer les ventes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Chariot'),
                subtitle: Text(cart?.name ?? 'Chariot inconnu'),
                leading: Icon(Icons.shopping_cart),
              ),
              Divider(),
              ListTile(
                title: Text('Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(assignment.date)),
                leading: Icon(Icons.calendar_today),
              ),
              Divider(),
              ListTile(
                title: Text('Quantité attribuée'),
                subtitle: Text('${assignment.assignedQuantity.toStringAsFixed(2)} kg'),
                leading: Icon(Icons.inventory_2),
              ),
              SizedBox(height: 16),
              TextField(
                controller: soldQuantityController,
                decoration: InputDecoration(
                  labelText: 'Quantité vendue (kg)',
                  hintText: 'Ex: 45',
                  prefixIcon: Icon(Icons.shopping_cart_checkout),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Montant versé',
                  hintText: 'Ex: 90000',
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(
                  labelText: 'Remarques (optionnel)',
                  hintText: 'Ex: Excellentes ventes au marché central',
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
              if (soldQuantityController.text.trim().isEmpty ||
                  amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                );
                return;
              }

              try {
                final soldQuantity = double.parse(soldQuantityController.text.trim());
                final amount = double.parse(amountController.text.trim());

                if (soldQuantity <= 0 || amount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Les valeurs doivent u00eatre positives')),
                  );
                  return;
                }

                if (soldQuantity > assignment.assignedQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('La quantité vendue ne peut pas dépasser la quantité attribuée')),
                  );
                  return;
                }

                final updatedRecord = assignment.copyWith(
                  soldQuantity: soldQuantity,
                  amountCollected: amount,
                  remarks: remarksController.text.trim(),
                );

                appState.updateDailyRecord(updatedRecord);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: Assurez-vous que les valeurs sont des nombres valides')),
                );
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deleteRecord(BuildContext context, DailyRecord record) {
    final appState = Provider.of<AppState>(context, listen: false);
    final cart = appState.getCartById(record.cartId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text(record.soldQuantity > 0
            ? 'u00cates-vous su00fbr de vouloir supprimer cet enregistrement de vente pour ${cart?.name ?? "chariot inconnu"} ?'
            : 'u00cates-vous su00fbr de vouloir supprimer cette attribution pour ${cart?.name ?? "chariot inconnu"} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              appState.deleteDailyRecord(record.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Enregistrement supprimé avec succès')),
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