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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...borrowings.map(
              (borrowing) => Card(
                child: ListTile(
                  leading: Icon(
                    borrowing.returned ? Icons.check_circle : Icons.pending,
                    color: borrowing.returned ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    '${borrowing.customer} borrowed ${borrowing.item}',
                  ),
                  subtitle: Text(
                    'Amount: Rs. ${borrowing.amount} | Date: \'${borrowing.date.toLocal().toString().split(' ')[0]}\'',
                  ),
                  trailing: Text(borrowing.returned ? 'Returned' : 'Pending'),
                  onTap: () => _toggleReturned(borrowing),
                ),
              ),
            ),
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
      },
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
      title: Text('Add Borrowing'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Customer Name'),
                onSaved: (val) => customer = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter customer name' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Item'),
                onSaved: (val) => item = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter item' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onSaved: (val) => amount = val ?? '',
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Enter amount'
                    : null,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    date == null
                        ? 'Select Date'
                        : 'Date: \'${date!.toLocal().toString().split(' ')[0]}\'',
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          date = picked;
                        });
                      }
                    },
                    child: Text('Pick Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false && date != null) {
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
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
