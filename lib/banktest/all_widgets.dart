import 'package:flutter/material.dart';

/// Search Bar Widget
class SearchBar2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(Icons.search, color: Colors.grey),
        hintText: "Search for something",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Card Section Widget
class CardSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCard("5,756", "Eddy Cusuma", "12/22", "3778 **** **** 1234"),
          _buildCard("2,400", "Jane Smith", "11/23", "4213 **** **** 5678"),
        ],
      ),
    );
  }

  Widget _buildCard(
      String balance, String name, String validThru, String cardNumber) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 260,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Balance", style: TextStyle(color: Colors.white)),
            Text("\$$balance",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text("CARD HOLDER",
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text(name, style: TextStyle(color: Colors.white)),
                  ],
                ),
                SizedBox(height: 5),
                Column(
                  children: [
                    Text("VALID THRU",
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                    SizedBox(height: 5),
                    Text('12/26', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
                width: 236,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white24),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child:
                      Text(cardNumber, style: TextStyle(color: Colors.white)),
                )),
          ],
        ),
      ),
    );
  }
}

/// Recent Transaction Widget
class RecentTransactionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            // BoxShadow(
            //   color: Colors.black26,
            //   offset: Offset(2, 2)
            //
            // )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          _transactionTile("Deposit from My Bank", "-\$850", "28 January 2021"),
          _transactionTile("Deposit Paypal", "+\$2,500", "25 January 2021"),
          _transactionTile("Jemi Wilson", "+\$5,400", "21 January 2021"),
        ],
      ),
    );
  }

  Widget _transactionTile(String title, String amount, String date) {
    return ListTile(
      leading:
          Icon(Icons.account_balance_wallet_outlined, color: Colors.blueAccent),
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(
        amount,
        style: TextStyle(
          color: amount.contains('-') ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Weekly Activity Graph Widget
class WeeklyActivityGraph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Weekly Activity",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
          height: 200,
          color: Colors.grey[200], // Placeholder for actual graph
          child: Center(child: Text("Graph Placeholder")),
        ),
      ],
    );
  }
}

class ExpenseStatistics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text("Weekly Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
              color: Colors.white, // Placeholder for actual graph

              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text("BarChart Placeholder")),
        ),
      ],
    );
  }
}

class QuickTransferPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Quick Transfer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title

                  SizedBox(height: 20),

                  // Profile icons

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                            backgroundImage: AssetImage('assets/livia.jpg'),
                            radius: 30),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Livia Bator',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('CEO', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        SizedBox(width: 20),
                        CircleAvatar(
                            backgroundImage: AssetImage('assets/randy.jpg'),
                            radius: 30),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Randy Press',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Director',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        SizedBox(width: 20),
                        CircleAvatar(
                            backgroundImage: AssetImage('assets/workman.jpg'),
                            radius: 30),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Workman',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Designer',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Amount and action buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                        child: Text('Write Amount'),
                      ),
                      SizedBox(width: 10),
                      Text('525.50', style: TextStyle(fontSize: 24)),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                        child: Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Transactional extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for something',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),

          // Expense graph
          Text(
            'My Expense',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.blue[50],
            child:
                Center(child: Text('\$12,500', style: TextStyle(fontSize: 32))),
          ),
          SizedBox(height: 20),

          // Transaction list
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text('Spotify Subscription'),
                subtitle: Text('28 Jan, 12:30 AM'),
                trailing: Text('-\$2,500', style: TextStyle(color: Colors.red)),
              ),
              ListTile(
                title: Text('Freepik Sales'),
                subtitle: Text('25 Jan, 10:40 PM'),
                trailing: Text('\$750', style: TextStyle(color: Colors.green)),
              ),
              ListTile(
                title: Text('Mobile Service'),
                subtitle: Text('20 Jan, 10:40 PM'),
                trailing: Text('-\$150', style: TextStyle(color: Colors.red)),
              ),
              ListTile(
                title: Text('Wilson'),
                subtitle: Text('15 Jan, 03:29 PM'),
                trailing: Text('-\$1,050', style: TextStyle(color: Colors.red)),
              ),
              ListTile(
                title: Text('Emilly'),
                subtitle: Text('14 Jan, 10:40 PM'),
                trailing: Text('\$840', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AccountsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('My Balance',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$12,750', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Income',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$5,600', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Expense',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$3,460', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Total Saving',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$7,920', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // Last Transaction list
            Text(
              'Last Transaction',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: Text('Spotify Subscription'),
              subtitle: Text('25 Jan 2021'),
              trailing: Text('-\$150', style: TextStyle(color: Colors.red)),
            ),
            ListTile(
              title: Text('Mobile Service'),
              subtitle: Text('25 Jan 2021'),
              trailing: Text('-\$340', style: TextStyle(color: Colors.red)),
            ),
            ListTile(
              title: Text('Emilly Wilson'),
              subtitle: Text('25 Jan 2021'),
              trailing: Text('\$780', style: TextStyle(color: Colors.green)),
            ),
          ],
        ));
  }
}
