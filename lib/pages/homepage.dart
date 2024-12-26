import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../Assistants/assistantMethods.dart';
import '../models/clientuser.dart';
import '../widget/mycards.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  @override
  void initState() {
    _getSalutation();
    // TODO: implement initState
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo(context);
    AssistantMethods.getCurrentAssetInfo(context);
  }

  String _getSalutation() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientprovider = Provider.of<clientusers>(context).userInfo;
    final Size size = MediaQuery.of(context).size;

    List<Widget> _widgetOptions = <Widget>[
      Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0, left: 18),
                    child: Text(
// '                       'Hi ' + '${clientProvider?.username ?? ""}!',
                      '                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)',
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, left: 22),
                        child: Text(
                          '${_getSalutation()}',
                          style: TextStyle(fontSize: 15, color: Colors.black26),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black, // Set border color to black
                  width: 4.0, // Set border thickness
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 18.0, left: 8),
                        child: Text('Welcome!', style: TextStyle(fontSize: 20)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0, left: 8),
                        child: Text(
                          'Build Your Dossier!',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 94, child: Image.asset(Cards.kcard4)),
                ],
              ),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(8.0),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyCard(),
                ViewAssetsCard(),
              ],
            ),
          ),
          SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0, left: 8),
                        child: Text(
                          'Build Your Dossier!',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 94, child: Image.asset(Cards.kcard4)),
                ],
              ),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(8.0),
            ),
          ),
        ],
      ),
      // Add more widgets for different tabs
      // Center(child: Text('Restaurant Menu')),
      // Center(child: Text('Bookmark')),
      // Center(child: Text('Notifications',style: TextStyle(color: Colors.black),)),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DOSSIER.",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(children: [
            Row(children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0, left: 18),
                    child: Text('Hi ' + '${clientprovider?.username ?? ""}!',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, left: 22),
                        child: Text('${_getSalutation()}',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black26)),
                      ),
                    ],
                  )
                ],
              ),
            ]),
            SizedBox(
              height: 26,
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black, // Set border color to black
                      width: 4.0, // Set border thickness
                    ),
                    borderRadius: BorderRadius.circular(20)),
                // Set the background color to black
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 18.0, left: 1),
                            child: Text('Welcome!',
                                style: TextStyle(fontSize: 20)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1.0, left: 8),
                            child: Text('Build Your Dossier!',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black54)),
                          ),
                        ],
                      ),

                      SizedBox(height: 94, child: Image.asset(Cards.kcard4)),

                      // Add your children widgets here
                    ],
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                // Set the width to match the screen size
                padding: EdgeInsets.all(
                    8.0), // Optional: Add padding to the container
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyCard(),
                    ViewAssetsCard(),
                  ]),
            ),
            SizedBox(
              height: 23,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black, // Set border color to black
                    width: 4.0, // Set border thickness
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                width: MediaQuery.of(context).size.width,
                // Match the screen width
                padding: EdgeInsets.all(8.0),
                // Add padding to the container
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Column
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1.0, left: 8),
                            child: Text(
                              'Upcoming Events!',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.black54),
                            ),
                          ),
                          SizedBox(height: 10), // Spacing
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10.0,
                                mainAxisSpacing: 6.0,
                              ),
                              itemCount: icons.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPage(
                                          title: icons[index]['title']!,
                                          contentBuilder: icons[index]
                                              ['contentBuilder'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircleAvatar(
                                          backgroundColor: Colors.amber,
                                          child: Icon(
                                            icons[index]['icon'],
                                            size: 25,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        icons[index]['title'],
                                        // Fixed to correctly access the title
                                        style: TextStyle(fontSize: 12),
                                        // Smaller font size for the text
                                        textAlign: TextAlign.center,
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Image
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        height: 94,
                        // Ensure the image fits within the layout
                        child: Image.asset(Cards.kcard4, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

// Icon data with unique content
  final List<Map<String, dynamic>> icons = [
    {
      'icon': Icons.monetization_on,
      'title': 'Savings',
      'contentBuilder': () => SavingsPage(),
    },
    {
      'icon': Icons.event,
      'title': 'Events',
      'contentBuilder': () => EventPage(),
    },
    {
      'icon': Icons.notifications,
      'title': 'Notifications',
      'contentBuilder': () => NotificationPage(),
    },
    {
      'icon': Icons.settings,
      'title': 'Settings',
      'contentBuilder': () => SettingsPage(),
    },
    {
      'icon': Icons.contact_page,
      'title': 'Contact Us',
      'contentBuilder': () => ContactUsPage(),
    },
  ];
}

class BNBCustomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    Path path = Path()..moveTo(0, 20);
    path.quadraticBezierTo(size.width * .20, 0, size.width * .35, 0);
    path.quadraticBezierTo(size.width * .40, 0, size.width * .40, 20);
    path.arcToPoint(Offset(size.width * .60, 20),
        radius: Radius.circular(10.0), clockwise: false);

    path.quadraticBezierTo(size.width * .60, 0, size.width * .65, 0);
    path.quadraticBezierTo(size.width * .80, 0, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 5, true);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Stateful Detail Page
class DetailPage extends StatefulWidget {
  final String title;
  final Widget Function() contentBuilder;

  const DetailPage(
      {Key? key, required this.title, required this.contentBuilder})
      : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: Text(widget.title),
      // ),
      body: widget.contentBuilder(),
    );
  }
}

class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  int _currentIndex = 0;

  // Define the pages to be displayed in the body
  final List<Widget> _pages = [
    HomeContent(),
    ActivityContent(),
    CardContent(),
    ProfileContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hi, John!',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.card_giftcard, color: Colors.green),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: _pages[_currentIndex], // Switch between pages
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Card',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Home Page Content
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),

                      blurRadius: 2
                  )
                ],
                color: Colors.amber,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$16,567.00',
                    style: TextStyle(color: Colors.black, fontSize: 24),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '+3.50% from last month',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '**** 1214',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Exp 02/15',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 19),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.black,
                        ),
                        child: Text('Add Money',style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // SizedBox(height: 20),

            SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.amber,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 3,
                                offset: Offset(1, 2),
                                color: Colors.black26,
                              )
                            ]),
                        height: 53,
                        width: 53,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add)],
                        ),
                      ),
                      SizedBox(
                        width: 23,
                      ),
                      Container(

                        height: 53,
                        width: 53,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.amber,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 3,
                              offset: Offset(1, 2),
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add_card)],
                        ),
                      ),
                      SizedBox(
                        width: 23,
                      ),
                      Container(

                        height: 53,
                        width: 53,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.amber,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 3,
                              offset: Offset(1, 2),
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.accessibility)],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 15,),

            // Transactions
            Text('Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15,),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.attach_money, color: Colors.blue),
                  title: Text('Top up'),
                  subtitle: Text('Today 1:53 PM'),
                  trailing:
                      Text('+\$100.00', style: TextStyle(color: Colors.green)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Activity Page Content
class ActivityContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Activity Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

// Card Page Content
class CardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Card Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

// Profile Page Content
class ProfileContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Upcoming Events will be displayed here.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'This is the Notifications Page.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Configure your settings here.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Get in touch with us here.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
