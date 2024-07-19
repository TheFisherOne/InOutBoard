import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/constants.dart';
import 'admin_page.dart';
import 'main.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String _nameMatch = '';
  String _emailMatch = '';
  String _roomMatch = '';
  bool? _presentMatch;
  bool? _residentMatch;
  bool? _staffMatch;
  List<QueryDocumentSnapshot<Object?>> filteredDocs = [];
  int numFilterRows = 6;
  int _selectedRow = -1;

  Widget buildRow(int row) {
    return Column(
      children: [
        InkWell(
            onTap: () {
              setState(() {
                if (_selectedRow == row) {
                  _selectedRow = -1;
                } else {
                  _selectedRow = row;
                }
              });
            },
            child: Text(' ${filteredDocs[row].get('FullName')}',
                style: (row == _selectedRow) ? errorNameStyle : nameStyle)),
        if (_selectedRow == row)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: filteredDocs[row].get('Present') ? Colors.blue : Colors.transparent, width: 8),
                    ),
                    child: IconButton(
                        iconSize: 70,
                        onPressed: () {
                          // print('CLICKED: present');
                          setState(() {
                            setPresent(filteredDocs[row], true);
                          });
                        },
                        icon: const Icon(Icons.house_outlined)),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: !filteredDocs[row].get('Present') ? Colors.blue : Colors.transparent, width: 8),
                    ),
                    child: IconButton(
                        iconSize: 70,
                        onPressed: () {
                          // print('CLICKED: away');
                          setState(() {
                            setPresent(filteredDocs[row], false);
                          });
                        },
                        icon: const Icon(Icons.exit_to_app)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: IconButton(
                  iconSize: 50,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Administration( adminCustomerDoc: filteredDocs[row])));
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  enableFeedback: true,
                  color: Colors.red,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<QueryDocumentSnapshot<Object?>>? listDocs;

    return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          title: Text('List View: ${buildingDoc!.get('DisplayName')}'),
          backgroundColor: Colors.blue[400],
          elevation: 0.0,
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(fireStoreCollectionName)
                .doc(buildingId)
                .collection('Customer')
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              listDocs = null;
              if (snapshot.error != null) {
                String error =
                    'Snapshot error: ${snapshot.error.toString()} on getting doc $buildingId / $loggedInUser';
                if (kDebugMode) {
                  print(error);
                }
                return Text(error);
              }
              // print('in StreamBuilder ladder 0');
              if (!snapshot.hasData) return const CircularProgressIndicator();

              if (snapshot.data == null) return const CircularProgressIndicator();
              if (snapshot.requireData.docs.length <= 1) return const CircularProgressIndicator();

              listDocs = snapshot.requireData.docs;
              // if (_nameMatch.isEmpty){
              //   filteredDocs = listDocs!;
              // } else {
              filteredDocs = listDocs!
                  .where((doc) =>
                      doc.get('FullName').toLowerCase().contains(_nameMatch) &&
                      doc.id.toLowerCase().contains(_emailMatch) &&
                      doc.get('Room').toLowerCase().contains(_roomMatch) &&
                      ((_presentMatch == null) || doc.get('Present') == _presentMatch) &&
                      ((_residentMatch == null) || doc.get('Resident') == _residentMatch) &&
                      ((_staffMatch == null) || doc.get('Staff') == _staffMatch))
                  .toList();
              // }

              return ListView.separated(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: filteredDocs.length + numFilterRows,
                  separatorBuilder: (context, index) => (index == (numFilterRows - 1))
                      ? const Divider(
                          thickness: 9,
                          color: Colors.blueAccent,
                        )
                      : const Divider(thickness: 4),
                  itemBuilder: (BuildContext context, int row) {
                    if (row == 0) {
                      return Row(
                        children: [
                          const Text(
                            'Name filter: ',
                            style: nameStyle,
                          ),
                          Expanded(
                            child: TextFormField(
                              onChanged: (newStr) {
                                setState(() {
                                  _nameMatch = newStr.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }
                    if (row == 1) {
                      return Row(
                        children: [
                          const Text(
                            'Email filter: ',
                            style: nameStyle,
                          ),
                          Expanded(
                            child: TextFormField(
                              onChanged: (newStr) {
                                setState(() {
                                  _emailMatch = newStr.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }
                    if (row == 2) {
                      return Row(
                        children: [
                          const Text(
                            'Room filter: ',
                            style: nameStyle,
                          ),
                          Expanded(
                            child: TextFormField(
                              onChanged: (newStr) {
                                setState(() {
                                  _roomMatch = newStr.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }
                    if (row == 3) {
                      return Row(children: [
                        const SizedBox(width: 15),
                        Row(children: [
                          SizedBox(
                              height: 50,
                              width: 50,
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Transform.scale(
                                    scale: 2.5,
                                    child: Checkbox(
                                        tristate: true,
                                        value: _presentMatch,
                                        onChanged: (value) {
                                          setState(() {
                                            _presentMatch = value;
                                          });
                                        }),
                                  ))),
                          const Text(
                            'Present filter',
                            style: nameStyle,
                          ),
                        ]),
                      ]);
                    }
                    if (row == 4) {
                      return Row(children: [
                        const SizedBox(width: 15),
                        Row(children: [
                          SizedBox(
                              height: 50,
                              width: 50,
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Transform.scale(
                                    scale: 2.5,
                                    child: Checkbox(
                                        tristate: true,
                                        value: _residentMatch,
                                        onChanged: (value) {
                                          setState(() {
                                            _residentMatch = value;
                                          });
                                        }),
                                  ))),
                          const Text(
                            'Resident filter',
                            style: nameStyle,
                          ),
                        ]),
                      ]);
                    }
                    if (row == 5) {
                      return Row(children: [
                        const SizedBox(width: 15),
                        Row(children: [
                          SizedBox(
                              height: 50,
                              width: 50,
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Transform.scale(
                                    scale: 2.5,
                                    child: Checkbox(
                                        tristate: true,
                                        value: _staffMatch,
                                        onChanged: (value) {
                                          setState(() {
                                            _staffMatch = value;
                                          });
                                        }),
                                  ))),
                          const Text(
                            'Staff filter',
                            style: nameStyle,
                          ),
                        ]),
                      ]);
                    }
                    return buildRow(row - numFilterRows);
                  });
            }));
  }
}
