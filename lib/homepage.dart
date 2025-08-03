import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:newuser/loginpage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logged out successfully")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _logout)],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, size: 100, color: Colors.blue),
                SizedBox(height: 30),
                Text(
                  'Welcome to Sandeep Stores!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                if (_user != null) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'User Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 10),
                          ListTile(
                            leading: Icon(Icons.email, color: Colors.blue),
                            title: Text('Email'),
                            subtitle: Text(_user!.email ?? 'No email'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.verified_user,
                              color: Colors.blue,
                            ),
                            title: Text('Email Verified'),
                            subtitle: Text(_user!.emailVerified ? 'Yes' : 'No'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.access_time,
                              color: Colors.blue,
                            ),
                            title: Text('Account Created'),
                            subtitle: Text(
                              _user!.metadata.creationTime?.toString().split(
                                    ' ',
                                  )[0] ??
                                  'Unknown',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 30),
                // Borrowings Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Borrowings Ledger',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                _BorrowingsSection(),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Borrowing data model
class Borrowing {
  final String id;
  final String customer;
  final String item;
  final double amount;
  final DateTime date;
  bool returned;

  Borrowing({
    required this.id,
    required this.customer,
    required this.item,
    required this.amount,
    required this.date,
    this.returned = false,
  });

  factory Borrowing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return Borrowing(
        id: doc.id,
        customer: '',
        item: '',
        amount: 0.0,
        date: DateTime.now(),
        returned: false,
      );
    }
    DateTime dateValue;
    try {
      if (data['date'] is Timestamp) {
        dateValue = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is DateTime) {
        dateValue = data['date'] as DateTime;
      } else if (data['date'] is String) {
        dateValue = DateTime.tryParse(data['date']) ?? DateTime.now();
      } else {
        dateValue = DateTime.now();
      }
    } catch (e) {
      dateValue = DateTime.now();
    }
    double amountValue;
    try {
      if (data['amount'] is int) {
        amountValue = (data['amount'] as int).toDouble();
      } else if (data['amount'] is double) {
        amountValue = data['amount'] as double;
      } else if (data['amount'] is String) {
        amountValue = double.tryParse(data['amount']) ?? 0.0;
      } else {
        amountValue = 0.0;
      }
    } catch (e) {
      amountValue = 0.0;
    }
    return Borrowing(
      id: doc.id,
      customer: data['customer'] ?? '',
      item: data['item'] ?? '',
      amount: amountValue,
      date: dateValue,
      returned: data['returned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer': customer,
      'item': item,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'returned': returned,
    };
  }
}

class _BorrowingsSection extends StatefulWidget {
  @override
  __BorrowingsSectionState createState() => __BorrowingsSectionState();
}

class __BorrowingsSectionState extends State<_BorrowingsSection> {
  final CollectionReference borrowersRef = FirebaseFirestore.instance
      .collection('borrowers');

  void _addBorrowing(Borrowing borrowing) async {
    try {
      await borrowersRef.add(borrowing.toMap());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Borrowing added successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add borrowing: $e')));
    }
  }

  void _toggleReturned(Borrowing borrowing) async {
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Text(
            'Confirm Status Change',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        content: Text(
          borrowing.returned
              ? 'Mark this borrowing as Pending again?'
              : 'Mark this borrowing as Returned?',
          style: TextStyle(color: Colors.blue.shade800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
    if (shouldUpdate == true) {
      try {
        await borrowersRef.doc(borrowing.id).update({
          'returned': !borrowing.returned,
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Borrowing status updated')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  void _deleteBorrowing(Borrowing borrowing) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Delete Borrowing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this borrowing?',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: ${borrowing.customer}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text('Item: ${borrowing.item}'),
                  Text('Amount: Rs. ${borrowing.amount.toStringAsFixed(2)}'),
                  Text(
                    'Date: ${borrowing.date.toLocal().toString().split(' ')[0]}',
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await borrowersRef.doc(borrowing.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Borrowing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete borrowing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddBorrowingDialog() async {
    final result = await showDialog<Borrowing>(
      context: context,
      builder: (context) => AddBorrowingDialog(),
    );
    if (result != null) {
      _addBorrowing(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: borrowersRef.orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              Text('No borrowings yet.'),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _showAddBorrowingDialog,
                icon: Icon(Icons.add),
                label: Text('Add Borrowing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }
        final borrowings = snapshot.data!.docs
            .map((doc) => Borrowing.fromFirestore(doc))
            .toList();

        // Calculate totals
        double totalAmount = borrowings.fold(
          0.0,
          (sum, borrowing) => sum + borrowing.amount,
        );
        double pendingAmount = borrowings
            .where((borrowing) => !borrowing.returned)
            .fold(0.0, (sum, borrowing) => sum + borrowing.amount);
        double returnedAmount = borrowings
            .where((borrowing) => borrowing.returned)
            .fold(0.0, (sum, borrowing) => sum + borrowing.amount);
        int totalBorrowings = borrowings.length;
        int pendingBorrowings = borrowings
            .where((borrowing) => !borrowing.returned)
            .length;
        int returnedBorrowings = borrowings
            .where((borrowing) => borrowing.returned)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Cards
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Borrowings Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryItem(
                            icon: Icons.account_balance_wallet,
                            title: 'Total Amount',
                            value: 'Rs. ${totalAmount.toStringAsFixed(2)}',
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _SummaryItem(
                            icon: Icons.pending,
                            title: 'Pending',
                            value: 'Rs. ${pendingAmount.toStringAsFixed(2)}',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryItem(
                            icon: Icons.check_circle,
                            title: 'Returned',
                            value: 'Rs. ${returnedAmount.toStringAsFixed(2)}',
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _SummaryItem(
                            icon: Icons.list_alt,
                            title: 'Total Items',
                            value: '$totalBorrowings',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryItem(
                            icon: Icons.pending_actions,
                            title: 'Pending Items',
                            value: '$pendingBorrowings',
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _SummaryItem(
                            icon: Icons.done_all,
                            title: 'Returned Items',
                            value: '$returnedBorrowings',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Borrowings List
            ...borrowings.map(
              (borrowing) => Card(
                margin: EdgeInsets.only(bottom: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: borrowing.returned
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      borrowing.returned ? Icons.check_circle : Icons.pending,
                      color: borrowing.returned ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${borrowing.customer} borrowed ${borrowing.item}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        'Amount: Rs. ${borrowing.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Date: ${borrowing.date.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: borrowing.returned
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          borrowing.returned ? 'Returned' : 'Pending',
                          style: TextStyle(
                            color: borrowing.returned
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteBorrowing(borrowing),
                        icon: Icon(Icons.delete, color: Colors.red.shade400),
                        tooltip: 'Delete borrowing',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _toggleReturned(borrowing),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddBorrowingDialog,
              icon: Icon(Icons.add),
              label: Text('Add Borrowing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AddBorrowingDialog extends StatefulWidget {
  @override
  _AddBorrowingDialogState createState() => _AddBorrowingDialogState();
}

class _AddBorrowingDialogState extends State<AddBorrowingDialog> {
  final _formKey = GlobalKey<FormState>();
  String customer = '';
  String item = '';
  String amount = '';
  DateTime? date;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'Add New Borrowing',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      content: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                // Customer Name Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                    ),
                    onSaved: (val) => customer = val ?? '',
                    validator: (val) => val == null || val.isEmpty
                        ? 'Enter customer name'
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                // Item Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Item',
                      prefixIcon: Icon(Icons.inventory, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                    ),
                    onSaved: (val) => item = val ?? '',
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter item' : null,
                  ),
                ),
                SizedBox(height: 16),
                // Amount Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Amount (Rs.)',
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        color: Colors.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => amount = val ?? '',
                    validator: (val) =>
                        val == null || double.tryParse(val) == null
                        ? 'Enter valid amount'
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                // Date Selection
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(Icons.calendar_today, color: Colors.blue),
                    title: Text(
                      date == null
                          ? 'Select Date'
                          : 'Date: ${date!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        color: date == null
                            ? Colors.grey
                            : Colors.blue.shade700,
                        fontWeight: date == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.blue.shade800,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            date = picked;
                          });
                        }
                      },
                      icon: Icon(Icons.date_range, size: 18),
                      label: Text('Pick Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ??
                        false && date != null) {
                      _formKey.currentState?.save();
                      Navigator.pop(
                        context,
                        Borrowing(
                          id: '', // Firestore will assign ID
                          customer: customer,
                          item: item,
                          amount: double.tryParse(amount) ?? 0,
                          date: date!,
                        ),
                      );
                    } else if (date == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a date'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Add Borrowing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
