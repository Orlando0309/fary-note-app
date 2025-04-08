import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  // Période par défaut: ce mois
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  String _selectedPeriod = 'Mois';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
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

  void _setPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      
      switch (period) {
        case 'Aujourd\'hui':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Semaine':
          // Du lundi au dimanche
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
          _endDate = _startDate.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          break;
        case 'Mois':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Année':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de Bord'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return FadeTransition(
            opacity: _animation,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur de période
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Période',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildPeriodChip('Aujourd\'hui'),
                              SizedBox(width: 8),
                              _buildPeriodChip('Semaine'),
                              SizedBox(width: 8),
                              _buildPeriodChip('Mois'),
                              SizedBox(width: 8),
                              _buildPeriodChip('Année'),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Du ${DateFormat('dd/MM/yyyy').format(_startDate)} au ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cartes de résumé
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSummaryCards(context),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Graphique des dépenses par catégorie
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dépenses par Catégorie',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 40),
                            SizedBox(
                              height: 300,
                              child: FutureBuilder<Map<String, double>>(
                                future: appState.getExpensesByCategory(_startDate, _endDate),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Center(child: Text('Aucune dépense pour cette période'));
                                  }
                                  return _buildExpensePieChart(snapshot.data!);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Dernières activités
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dernières Activités',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildRecentActivitiesList(context, appState),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    bool isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(period),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) {
          _setPeriod(period);
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final amountFormat = NumberFormat('#,##0.00', 'fr_FR');
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FutureBuilder<double>(
                future: Provider.of<AppState>(context, listen: false).getTotalRevenue(_startDate, _endDate),
                builder: (context, snapshot) {
                  final revenue = snapshot.data ?? 0;
                  return _buildSummaryCard(
                    context,
                    title: 'Recettes',
                    value: '${amountFormat.format(revenue)} Ar',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: FutureBuilder<double>(
                future: Provider.of<AppState>(context, listen: false).getTotalExpenses(_startDate, _endDate),
                builder: (context, snapshot) {
                  final expenses = snapshot.data ?? 0;
                  return _buildSummaryCard(
                    context,
                    title: 'Dépenses',
                    value: '${amountFormat.format(expenses)} Ar',
                    icon: Icons.trending_down,
                    color: Colors.red,
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          
          children: [
            Expanded(
              child: FutureBuilder<List<double>>(
                future: Future.wait([
                  Provider.of<AppState>(context, listen: false).getTotalRevenue(_startDate, _endDate),
                  Provider.of<AppState>(context, listen: false).getTotalExpenses(_startDate, _endDate),
                ]),
                builder: (context, snapshot) {
                  double revenue = 0;
                  double expenses = 0;
                  if (snapshot.hasData) {
                    revenue = snapshot.data![0];
                    expenses = snapshot.data![1];
                  }
                  final profit = revenue - expenses;
                  return _buildSummaryCard(
                    context,
                    title: 'Bénéfice',
                    value: '${amountFormat.format(profit)} Ar',
                    icon: Icons.account_balance_wallet,
                    color: profit >= 0 ? Colors.blue : Colors.orange,
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Flexible(
  child: FutureBuilder<double>(
    future: Provider.of<AppState>(context, listen: false).getCurrentStockQuantity(),
    builder: (context, snapshot) {
      final stock = snapshot.data ?? 0;
      return _buildSummaryCard(
        context,
        title: 'Stock Actuel',
        value: '${stock.toStringAsFixed(2)} kg',
        icon: Icons.inventory_2,
        color: stock > 50 ? Colors.teal : stock > 20 ? Colors.amber : Colors.deepOrange,
      );
    },
  ),
)],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildExpensePieChart(Map<String, double> expensesByCategory) {
  final List<Color> colors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
  ];

  final List<PieChartSectionData> sections = [];
  final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);

  int colorIndex = 0;
  expensesByCategory.forEach((category, amount) {
    final percentage = total > 0 ? (amount / total * 100) : 0;
    final color = colors[colorIndex % colors.length];
    colorIndex++;

    sections.add(
      PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 100,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  });

  return Column(
    children: [
      SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
            sectionsSpace: 2,
            startDegreeOffset: -90,
          ),
        ),
      ),
      SizedBox(height: 16), // Reduced from 24 to 16 to give more space to legend
      SizedBox(
        height: 80, // Fixed height for the legend
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(expensesByCategory.length, (index) {
              final entry = expensesByCategory.entries.elementAt(index);
              final color = colors[index % colors.length];
              return _buildLegendItem(
                context,
                color: color,
                title: entry.key,
                value: '${NumberFormat('#,##0.00', 'fr_FR').format(entry.value)} Ar',
              );
            }),
          ),
        ),
      ),
    ],
  );
}
  Widget _buildLegendItem(BuildContext context, {
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '$title: $value',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesList(BuildContext context, AppState appState) {
    // Combiner les fiches journalières et les dépenses pour avoir une liste d'activités
    final dateFormat = DateFormat('dd/MM/yyyy');
    final amountFormat = NumberFormat('#,##0.00', 'fr_FR');
    
    List<Map<String, dynamic>> activities = [];
    
    // Ajouter les fiches journalières
    final records = appState.getDailyRecordsForPeriod(_startDate, _endDate);
    for (var record in records) {
      final cart = appState.getCartById(record.cartId);
      activities.add({
        'date': record.date,
        'type': 'record',
        'title': record.soldQuantity > 0 
            ? 'Vente: ${cart?.name ?? "Chariot inconnu"}' 
            : 'Attribution: ${cart?.name ?? "Chariot inconnu"}',
        'description': record.soldQuantity > 0 
            ? '${record.soldQuantity.toStringAsFixed(2)} kg vendus pour ${amountFormat.format(record.amountCollected)} Ar' 
            : '${record.assignedQuantity.toStringAsFixed(2)} kg attribués',
        'amount': record.soldQuantity > 0 ? record.amountCollected : 0,
        'icon': record.soldQuantity > 0 ? Icons.shopping_cart_checkout : Icons.inventory_2,
        'color': record.soldQuantity > 0 ? Colors.green : Colors.blue,
      });
    }
    
    // Ajouter les dépenses
    final expenses = appState.getExpensesForPeriod(_startDate, _endDate);
    for (var expense in expenses) {
      activities.add({
        'date': expense.date,
        'type': 'expense',
        'title': 'Dépense: ${expense.category}',
        'description': expense.description.isNotEmpty 
            ? expense.description 
            : '${amountFormat.format(expense.amount)} Ar',
        'amount': -expense.amount, // Négatif pour les dépenses
        'icon': Icons.money_off,
        'color': Colors.red,
      });
    }
    
    // Trier par date (plus récent d'abord)
    activities.sort((a, b) => b['date'].compareTo(a['date']));
    
    // Prendre les 10 dernières activités maximum
    final recentActivities = activities.take(10).toList();
    
    if (recentActivities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Aucune activité pour cette période',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: recentActivities.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final activity = recentActivities[index];
        return ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 24,
            ),
          ),
          title: Text(
            activity['title'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity['description']),
              SizedBox(height: 4),
              Text(
                dateFormat.format(activity['date']),
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          trailing: activity['amount'] != 0 
              ? Text(
                  activity['amount'] > 0 
                      ? '+${amountFormat.format(activity['amount'])} Ar' 
                      : '${amountFormat.format(activity['amount'])} Ar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: activity['amount'] > 0 ? Colors.green : Colors.red,
                  ),
                )
              : null,
        );
      },
    );
  }
}