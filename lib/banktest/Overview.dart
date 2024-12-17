import 'package:flutter/material.dart';

import 'all_widgets.dart';

class OverviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.91),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Overview",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundImage: AssetImage("assets/profile.jpg"),
          ),
          SizedBox(width: 16),
        ],
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:  EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SearchBar2(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:4.0, top:2),
                    child: Text("My Cards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left:4.0, top:2),
                    child: Text("See All", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              CardSection(),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left:4.0, top:2),
                child: Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              SizedBox(height: 10),
              RecentTransactionSection(),
              SizedBox(height: 20),
              WeeklyActivityGraph(),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left:4.0, top:2),
                child: Text("Expense Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ExpenseStatistics(),
              SizedBox(height: 20),

              QuickTransferPage(),
              SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}
