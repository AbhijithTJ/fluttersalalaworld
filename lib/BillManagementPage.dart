
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import './EditBillPage.dart';

class BillManagementPage extends StatefulWidget {
  const BillManagementPage({Key? key}) : super(key: key);

  @override
  State<BillManagementPage> createState() => _BillManagementPageState();
}

class _BillManagementPageState extends State<BillManagementPage> {
  late Future<List<Map<String, dynamic>>> _billsFuture;
  List<Map<String, dynamic>> _allBills = [];
  List<Map<String, dynamic>> _filteredBills = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSelectionMode = false;
  final List<String> _selectedBillIds = [];

  @override
  void initState() {
    super.initState();
    _billsFuture = _fetchBills();
  }

  Future<List<Map<String, dynamic>>> _fetchBills() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('bills').get();
      List<Map<String, dynamic>> bills = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        bills.add(data);
      }
      _allBills = bills;
      _filteredBills = bills;
      return bills;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bills: \$e')),
      );
      return [];
    }
  }

  void _filterBills() {
    if (_startDate == null && _endDate == null) {
      setState(() {
        _filteredBills = _allBills;
      });
      return;
    }

    List<Map<String, dynamic>> filtered = _allBills.where((bill) {
      DateTime billDate;
      try {
        billDate = DateFormat('dd-MM-yyyy').parse(bill['date']);
      } catch (e) {
        return false;
      }

      if (_startDate != null && _endDate != null) {
        return billDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            billDate.isBefore(_endDate!.add(const Duration(days: 1)));
      } else if (_startDate != null) {
        return billDate.isAtSameMomentAs(_startDate!) || billDate.isAfter(_startDate!);
      } else if (_endDate != null) {
        return billDate.isAtSameMomentAs(_endDate!) || billDate.isBefore(_endDate!);
      }
      return false;
    }).toList();

    setState(() {
      _filteredBills = filtered;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now(),
      end: _endDate ?? DateTime.now(),
    );
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: initialDateRange,
    );

    if (newDateRange != null) {
      setState(() {
        _startDate = newDateRange.start;
        _endDate = newDateRange.end;
      });
      _filterBills();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _filterBills();
  }

  Future<void> _deleteBill(String billId) async {
    try {
      await FirebaseFirestore.instance.collection('bills').doc(billId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill deleted successfully')),
      );
      setState(() {
        _billsFuture = _fetchBills();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting bill: \$e')),
      );
    }
  }

  void _editBill(Map<String, dynamic> billData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBillPage(billData: billData),
      ),
    ).then((_) {
      // Refresh the bill list after editing
      setState(() {
        _billsFuture = _fetchBills();
      });
    });
  }

  void _deleteSelectedBills() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String billId in _selectedBillIds) {
        batch.delete(FirebaseFirestore.instance.collection('bills').doc(billId));
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedBillIds.length} bills deleted successfully')),
      );
      setState(() {
        _isSelectionMode = false;
        _selectedBillIds.clear();
        _billsFuture = _fetchBills();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting bills: $e')),
      );
    }
  }

  void _onBillLongPress(String billId) {
    setState(() {
      _isSelectionMode = true;
      _selectedBillIds.add(billId);
    });
  }

  void _onBillTap(String billId) {
    setState(() {
      if (_selectedBillIds.contains(billId)) {
        _selectedBillIds.remove(billId);
        if (_selectedBillIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedBillIds.add(billId);
      }
    });
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Bill Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: () => _selectDateRange(context),
        ),
        if (_startDate != null || _endDate != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearDateFilter,
          ),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedBillIds.length} selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedBillIds.clear();
          });
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _deleteSelectedBills,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
      body: Column(
        children: [
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Filtering from '
                '${DateFormat('dd/MM/yyyy').format(_startDate!)} to '
                '${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _billsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No bills found.'));
                }

                return ListView.builder(
                  itemCount: _filteredBills.length,
                  itemBuilder: (context, index) {
                    final bill = _filteredBills[index];
                    final isSelected = _selectedBillIds.contains(bill['id']);
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        onTap: () {
                          if (_isSelectionMode) {
                            _onBillTap(bill['id']);
                          } else {
                            _editBill(bill);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _onBillLongPress(bill['id']);
                          }
                        },
                        title: Text(bill['customerName'] ?? 'No Name'),
                        subtitle: Text(
                            'Bill No: ${bill['billNo']} - ${bill['date']}'),
                        trailing: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  _onBillTap(bill['id']);
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editBill(bill),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteBill(bill['id']),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
