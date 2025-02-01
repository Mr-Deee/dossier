import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AccountDetailsPage extends StatefulWidget {
  final Map<dynamic, dynamic> accountData;

  AccountDetailsPage({required this.accountData});

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  TextEditingController amountController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  DatabaseReference _database = FirebaseDatabase.instance.ref().child("accounts");

  List<Map<String, dynamic>> allocations = [];

  @override
  void initState() {
    super.initState();
    allocations = List<Map<String, dynamic>>.from(widget.accountData["allocations"] ?? []);
  }

  void _allocateFunds() {
    String category = categoryController.text.trim();
    double amount = double.tryParse(amountController.text.trim()) ?? 0.0;

    if (category.isNotEmpty && amount > 0) {
      setState(() {
        allocations.add({"category": category, "amount": amount});
      });

      _database.child(widget.accountData["accountNumber"]).update({
        "allocations": allocations,
      });

      categoryController.clear();
      amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalBalance = double.tryParse(widget.accountData["balance"] ?? "0") ?? 0.0;
    double allocatedAmount = allocations.fold(0.0, (sum, item) => sum + item["amount"]);
    double remainingBalance = totalBalance - allocatedAmount;

    return Scaffold(
      appBar: AppBar(title: Text(widget.accountData["accountName"])),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Balance: \$${totalBalance.toStringAsFixed(2)}", style: TextStyle(fontSize: 20)),
            Text("Allocated: \$${allocatedAmount.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, color: Colors.red)),
            Text("Remaining: \$${remainingBalance.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, color: Colors.green)),

            SizedBox(height: 20),

            LinearProgressIndicator(
              value: allocatedAmount / totalBalance,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(Colors.blue),
            ),

            SizedBox(height: 20),

            Text("Allocate Funds", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: categoryController, decoration: InputDecoration(labelText: "Category (e.g., Rent, Clothes)")),
            TextField(controller: amountController, decoration: InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
            SizedBox(height: 10),

            ElevatedButton(onPressed: _allocateFunds, child: Text("Allocate")),

            SizedBox(height: 20),

            Text("Allocations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: allocations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(allocations[index]["category"]),
                    subtitle: Text("\$${allocations[index]["amount"].toStringAsFixed(2)}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
