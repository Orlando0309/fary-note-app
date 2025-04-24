import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Chariots'),
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
              child: appState.carts.isEmpty
                  ? _buildEmptyState(context)
                  : _buildCartsList(context, appState),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCartDialog(context),
        label: Text('Ajouter un chariot'),
        icon: Icon(Icons.add),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucun chariot ajouté',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Appuyez sur le bouton + pour ajouter un chariot',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditCartDialog(context),
            icon: Icon(Icons.add),
            label: Text('Ajouter un chariot'),
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

  Widget _buildCartsList(BuildContext context, AppState appState) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: appState.carts.length,
      itemBuilder: (context, index) {
        final cart = appState.carts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildCartCard(context, cart),
        );
      },
    );
  }

  Widget _buildCartCard(BuildContext context, Cart cart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cart.isActive ? AppTheme.successColor : AppTheme.errorColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 18,
                              color: AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                cart.operator,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cart.isActive
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cart.isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        color: cart.isActive ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (cart.description.isNotEmpty) ...[  
                SizedBox(height: 12),
                Text(
                  cart.description,
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
                      onPressed: () => _showAddEditCartDialog(context, cart),
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
                      onPressed: () => _deleteCart(context, cart),
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
  }

  void _showAddEditCartDialog(BuildContext context, [Cart? existingCart]) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController operatorController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    bool isActive = true;

    if (existingCart != null) {
      nameController.text = existingCart.name;
      operatorController.text = existingCart.operator;
      descriptionController.text = existingCart.description;
      isActive = existingCart.isActive;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingCart == null ? 'Ajouter un chariot' : 'Modifier le chariot'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du chariot',
                      hintText: 'Ex: Chariot 1',
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: operatorController,
                    decoration: InputDecoration(
                      labelText: 'Opérateur',
                      hintText: 'Ex: Jean Dupont',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      hintText: 'Ex: Chariot sité au marché central',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Statut du chariot'),
                    subtitle: Text(isActive ? 'Actif' : 'Inactif'),
                    value: isActive,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
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
                  if (nameController.text.trim().isEmpty ||
                      operatorController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                    );
                    return;
                  }

                  final cart = Cart(
                    id: existingCart?.id ?? '',
                    name: nameController.text.trim(),
                    operator: operatorController.text.trim(),
                    description: descriptionController.text.trim(),
                    isActive: isActive,
                  );

                  if (existingCart == null) {
                    Provider.of<AppState>(context, listen: false).addCart(cart);
                  } else {
                    Provider.of<AppState>(context, listen: false).updateCart(cart);
                  }

                  Navigator.pop(context);
                },
                child: Text(existingCart == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteCart(BuildContext context, Cart cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('êtes-vous sûr de vouloir supprimer le chariot "${cart.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).deleteCart(cart.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chariot supprimé avec succès')),
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