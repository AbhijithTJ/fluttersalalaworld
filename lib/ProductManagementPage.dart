import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './BarcodeScannerPage.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({Key? key}) : super(key: key);

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _imei2Controller = TextEditingController(); // Second IMEI controller
  final TextEditingController _searchController = TextEditingController();
  String _selectedProductType = 'Other'; // 'Mobile' or 'Other'
  
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  bool _isAddingProduct = false;
  bool _isEditingProduct = false;
  String? _editingProductId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadProducts();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    _imeiController.dispose();
    _imei2Controller.dispose(); // Dispose of the second IMEI controller
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .get();

      List<Map<String, dynamic>> products = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        products.add(data);
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  Future<void> _addProduct() async {
    if (_productNameController.text.trim().isEmpty ||
        _productPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // For mobile products, IMEI is required
    if (_selectedProductType == 'Mobile' && _imeiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IMEI number is required for mobile products')),
      );
      return;
    }

    // Check if only one IMEI is filled - require both to be filled
    if (_selectedProductType == 'Mobile') {
      final imei1Filled = _imeiController.text.trim().isNotEmpty;
      final imei2Filled = _imei2Controller.text.trim().isNotEmpty;
      
      if (imei1Filled && !imei2Filled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill both IMEI numbers')),
        );
        return;
      }
      
      if (!imei1Filled && imei2Filled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill both IMEI numbers')),
        );
        return;
      }
    }

    // Check if IMEI already exists for mobile products
    if (_selectedProductType == 'Mobile') {
      final existingProduct = await FirebaseFirestore.instance
          .collection('products')
          .where('type', isEqualTo: 'Mobile')
          .where('imei', isEqualTo: _imeiController.text.trim())
          .get();
      
      if (existingProduct.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A mobile with this IMEI already exists')),
        );
        return;
      }

      // Also check if second IMEI already exists
      if (_imei2Controller.text.trim().isNotEmpty) {
        final existingProduct2 = await FirebaseFirestore.instance
            .collection('products')
            .where('type', isEqualTo: 'Mobile')
            .where('imei2', isEqualTo: _imei2Controller.text.trim())
            .get();
        
        if (existingProduct2.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A mobile with this second IMEI already exists')),
          );
          return;
        }
      }
    }

    setState(() {
      _isAddingProduct = true;
    });

    try {
      double price = double.parse(_productPriceController.text);
      
      Map<String, dynamic> productData = {
        'name': _productNameController.text.trim(),
        'price': price,
        'type': _selectedProductType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedProductType == 'Mobile') {
        productData['imei'] = _imeiController.text.trim();
        productData['imei2'] = _imei2Controller.text.trim(); // Add second IMEI
        productData['model'] = _productNameController.text.trim(); // Store as model for mobiles
      } else {
        productData['description'] = _productDescriptionController.text.trim();
      }
      
      await FirebaseFirestore.instance.collection('products').add(productData);

      _productNameController.clear();
      _productPriceController.clear();
      _productDescriptionController.clear();
      _imeiController.clear();
      _imei2Controller.clear(); // Clear the second IMEI controller
      _selectedProductType = 'Other';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Close the add product dialog
      _loadProducts(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    } finally {
      setState(() {
        _isAddingProduct = false;
      });
    }
  }

  Future<void> _editProduct() async {
    if (_productNameController.text.trim().isEmpty ||
        _productPriceController.text.trim().isEmpty ||
        _editingProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // For mobile products, IMEI is required
    if (_selectedProductType == 'Mobile' && _imeiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IMEI number is required for mobile products')),
      );
      return;
    }

    // Check if only one IMEI is filled - require both to be filled
    if (_selectedProductType == 'Mobile') {
      final imei1Filled = _imeiController.text.trim().isNotEmpty;
      final imei2Filled = _imei2Controller.text.trim().isNotEmpty;
      
      if (imei1Filled && !imei2Filled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill both IMEI numbers')),
        );
        return;
      }
      
      if (!imei1Filled && imei2Filled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill both IMEI numbers')),
        );
        return;
      }
    }

    // Check if IMEI already exists for mobile products (excluding current product)
    if (_selectedProductType == 'Mobile') {
      final existingProduct = await FirebaseFirestore.instance
          .collection('products')
          .where('type', isEqualTo: 'Mobile')
          .where('imei', isEqualTo: _imeiController.text.trim())
          .get();
      
      // Check if any existing product has this IMEI (excluding the current one being edited)
      final duplicateExists = existingProduct.docs.any((doc) => doc.id != _editingProductId);
      if (duplicateExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A mobile with this IMEI already exists')),
        );
        return;
      }
    }

    setState(() {
      _isEditingProduct = true;
    });

    try {
      double price = double.parse(_productPriceController.text);
      
      Map<String, dynamic> updateData = {
        'name': _productNameController.text.trim(),
        'price': price,
        'type': _selectedProductType,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_selectedProductType == 'Mobile') {
        updateData['imei'] = _imeiController.text.trim();
        updateData['imei2'] = _imei2Controller.text.trim(); // Update second IMEI
        updateData['model'] = _productNameController.text.trim();
        // Remove description field for mobile products
        updateData['description'] = FieldValue.delete();
      } else {
        updateData['description'] = _productDescriptionController.text.trim();
        // Remove mobile-specific fields for other products
        updateData['imei'] = FieldValue.delete();
        updateData['imei2'] = FieldValue.delete(); // Remove second IMEI
        updateData['model'] = FieldValue.delete();
      }
      
      await FirebaseFirestore.instance
          .collection('products')
          .doc(_editingProductId)
          .update(updateData);

      _productNameController.clear();
      _productPriceController.clear();
      _productDescriptionController.clear();
      _imeiController.clear();
      _imei2Controller.clear(); // Clear the second IMEI controller
      _editingProductId = null;
      _selectedProductType = 'Other';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Close the edit product dialog
      _loadProducts(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: $e')),
      );
    } finally {
      setState(() {
        _isEditingProduct = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Product deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _loadProducts(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  void _showAddProductDialog() {
    _selectedProductType = 'Other'; // Reset to default
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                  Colors.green.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade500],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Add New Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Type Selection
                        const Text(
                          'Product Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedProductType = 'Mobile';
                                    });
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      color: _selectedProductType == 'Mobile'
                                          ? Colors.green.shade100
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.smartphone,
                                          color: _selectedProductType == 'Mobile'
                                              ? Colors.green.shade700
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Mobile',
                                            style: TextStyle(
                                              color: _selectedProductType == 'Mobile'
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
                                              fontWeight: _selectedProductType == 'Mobile'
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.green.shade200,
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedProductType = 'Other';
                                    });
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      color: _selectedProductType == 'Other'
                                          ? Colors.green.shade100
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          color: _selectedProductType == 'Other'
                                              ? Colors.green.shade700
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Other',
                                            style: TextStyle(
                                              color: _selectedProductType == 'Other'
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
                                              fontWeight: _selectedProductType == 'Other'
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Product Name/Model
                        TextField(
                          controller: _productNameController,
                          decoration: InputDecoration(
                            labelText: _selectedProductType == 'Mobile' ? 'Mobile Model *' : 'Product Name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            prefixIcon: Icon(
                              _selectedProductType == 'Mobile' ? Icons.smartphone : Icons.inventory,
                              color: Colors.green.shade600,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // IMEI Fields (only for Mobile)
                        if (_selectedProductType == 'Mobile') ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _imeiController,
                                  decoration: InputDecoration(
                                    labelText: 'IMEI Number 1 *',
                                    hintText: 'Enter 15-digit IMEI',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blue.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blue.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.qr_code,
                                      color: Colors.blue.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    counterText: '',
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BarcodeScannerPage(
                                          onScanned: (String scannedCode) {
                                            setState(() {
                                              _imeiController.text = scannedCode;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Scan IMEI Barcode',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _imei2Controller,
                                  decoration: InputDecoration(
                                    labelText: 'IMEI Number 2 (Optional)',
                                    hintText: 'Enter 15-digit IMEI',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.qr_code,
                                      color: Colors.purple.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    counterText: '',
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BarcodeScannerPage(
                                          onScanned: (String scannedCode) {
                                            setState(() {
                                              _imei2Controller.text = scannedCode;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Scan IMEI Barcode',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Price
                        TextField(
                          controller: _productPriceController,
                          decoration: InputDecoration(
                            labelText: 'Price *',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                            ),
                            prefixIcon: Icon(
                              Icons.currency_rupee,
                              color: Colors.orange.shade600,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        // Description (only for Other products)
                        if (_selectedProductType == 'Other')
                          TextField(
                            controller: _productDescriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                              ),
                              prefixIcon: Icon(
                                Icons.description,
                                color: Colors.grey.shade600,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 3,
                          ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _productNameController.clear();
                            _productPriceController.clear();
                            _productDescriptionController.clear();
                            _imeiController.clear();
                            _imei2Controller.clear(); // Clear the second IMEI controller
                            _selectedProductType = 'Other';
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAddingProduct ? null : _addProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isAddingProduct
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Add Product',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    _editingProductId = product['id'];
    _selectedProductType = product['type'] ?? 'Other';
    _productNameController.text = product['name'] ?? '';
    _productPriceController.text = product['price']?.toString() ?? '';
    _productDescriptionController.text = product['description'] ?? '';
    _imeiController.text = product['imei'] ?? '';
    _imei2Controller.text = product['imei2'] ?? ''; // Set the second IMEI controller

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade500],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Edit Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Type Selection
                        const Text(
                          'Product Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedProductType = 'Mobile';
                                    });
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      color: _selectedProductType == 'Mobile'
                                          ? Colors.blue.shade100
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.smartphone,
                                          color: _selectedProductType == 'Mobile'
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Mobile Phone',
                                            style: TextStyle(
                                              color: _selectedProductType == 'Mobile'
                                                  ? Colors.blue.shade700
                                                  : Colors.grey.shade600,
                                              fontWeight: _selectedProductType == 'Mobile'
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.blue.shade200,
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedProductType = 'Other';
                                    });
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      color: _selectedProductType == 'Other'
                                          ? Colors.blue.shade100
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          color: _selectedProductType == 'Other'
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Other Product',
                                            style: TextStyle(
                                              color: _selectedProductType == 'Other'
                                                  ? Colors.blue.shade700
                                                  : Colors.grey.shade600,
                                              fontWeight: _selectedProductType == 'Other'
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Product Name/Model
                        TextField(
                          controller: _productNameController,
                          decoration: InputDecoration(
                            labelText: _selectedProductType == 'Mobile' ? 'Mobile Model *' : 'Product Name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                            ),
                            prefixIcon: Icon(
                              _selectedProductType == 'Mobile' ? Icons.smartphone : Icons.inventory,
                              color: Colors.blue.shade600,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // IMEI Fields (only for Mobile)
                        if (_selectedProductType == 'Mobile') ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _imeiController,
                                  decoration: InputDecoration(
                                    labelText: 'IMEI Number 1 *',
                                    hintText: 'Enter 15-digit IMEI',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.qr_code,
                                      color: Colors.purple.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    counterText: '',
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BarcodeScannerPage(
                                          onScanned: (String scannedCode) {
                                            setState(() {
                                              _imeiController.text = scannedCode;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Scan IMEI Barcode',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _imei2Controller,
                                  decoration: InputDecoration(
                                    labelText: 'IMEI Number 2 (Optional)',
                                    hintText: 'Enter 15-digit IMEI',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.qr_code,
                                      color: Colors.purple.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    counterText: '',
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BarcodeScannerPage(
                                          onScanned: (String scannedCode) {
                                            setState(() {
                                              _imei2Controller.text = scannedCode;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Scan IMEI Barcode',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Price
                        TextField(
                          controller: _productPriceController,
                          decoration: InputDecoration(
                            labelText: 'Price *',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                            ),
                            prefixIcon: Icon(
                              Icons.currency_rupee,
                              color: Colors.orange.shade600,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        // Description (only for Other products)
                        if (_selectedProductType == 'Other')
                          TextField(
                            controller: _productDescriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                              ),
                              prefixIcon: Icon(
                                Icons.description,
                                color: Colors.grey.shade600,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 3,
                          ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _productNameController.clear();
                            _productPriceController.clear();
                            _productDescriptionController.clear();
                            _imeiController.clear();
                            _imei2Controller.clear(); // Clear the second IMEI controller
                            _editingProductId = null;
                            _selectedProductType = 'Other';
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEditingProduct ? null : _editProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isEditingProduct
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Product',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    if (_searchController.text.isEmpty) {
      return _products;
    }
    
    String searchTerm = _searchController.text.toLowerCase();
    return _products.where((product) {
      String name = product['name']?.toString().toLowerCase() ?? '';
      String description = product['description']?.toString().toLowerCase() ?? '';
      return name.contains(searchTerm) || description.contains(searchTerm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredProducts = _getFilteredProducts();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.1),
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(context),
                
                // Search Bar
                _buildSearchBar(colorScheme),
                
                // Products List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildProductsList(filteredProducts, colorScheme),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new),
              color: Colors.green[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
                Text(
                  'Manage your product inventory',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[600]!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search, color: Colors.green[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildProductsList(List<Map<String, dynamic>> products, ColorScheme colorScheme) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.green[600]!.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Products Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first product to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green[600]!,
                            Colors.green[400]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'] ?? 'Unknown Product',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: product['type'] == 'Mobile' ? Colors.blue[100] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  product['type'] == 'Mobile' ? 'Mobile' : 'Other',
                                  style: TextStyle(
                                    color: product['type'] == 'Mobile' ? Colors.blue[700] : Colors.grey[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${product['price']?.toString() ?? '0'}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (product['type'] == 'Mobile' && product['imei'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'IMEI: ${product['imei']}',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (product['imei2'] != null)
                                  Text(
                                    'IMEI 2: ${product['imei2']}',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          if (product['type'] != 'Mobile' && product['description'] != null && product['description'].isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  product['description'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showEditProductDialog(product),
                          icon: const Icon(Icons.edit_outlined),
                          color: Colors.blue[600],
                          tooltip: 'Edit Product',
                        ),
                        IconButton(
                          onPressed: () => _deleteProduct(
                            product['id'],
                            product['name'] ?? 'Unknown Product',
                          ),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red[400],
                          tooltip: 'Delete Product',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
