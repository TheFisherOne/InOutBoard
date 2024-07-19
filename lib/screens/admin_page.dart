import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_out_board/screens/main.dart';
import '../constants/constants.dart';
import 'dart:math';
import 'package:collection/collection.dart';

DocumentSnapshot<Object?>? selectedPlayerDoc;

AdministrationState? globalAdministration;
const List<String> globalAttrNames = [
  'Admins',
  'DisplayName',
  '',
  'FullName',
  'Room',
  'TravelWith',
  'Resident',
  'Staff',
];
// this should be same length and same order as globalAttrNames
const List<String> globalHelpText = [
  'Emails separated by commas',
  'Descriptive name of the building',
  '',
  'The full name of the customer',
  'The room where a resident resides',
  'Other people this customer will help. emails separated by commas',
  'This customer is a resident',
  'This customer is a staff member',
];
String admins = '';
String displayName = '';
String fullName = '';
String room = '';
String travelWith = '';
bool resident = false;
bool staff = false;
List<dynamic> globalStaticValues() {
  // print('globalStaticValues start');
  admins = buildingDoc!.get('Admins');
  displayName = buildingDoc!.get('DisplayName');
  fullName = selectedPlayerDoc!.get('FullName');
  room = selectedPlayerDoc!.get('Room');
  travelWith = selectedPlayerDoc!.get('TravelWith');
  resident = selectedPlayerDoc!.get('Resident');
  staff = selectedPlayerDoc!.get('Staff');
  // print('globalStaticValues end');
  return [
    admins,
    displayName,
    null,
    fullName,
    room,
    travelWith,
    resident,
    staff,
  ];
}
List<dynamic> initialValues =[];
void setGlobalAttribute(int row, String attrName, String value, List<String?> errorText){
  // print('setGlobalAttribute: attrName: $attrName, value: $value, selectedPlayerDoc.id: ${selectedPlayerDoc!.id}');
  errorText[row] = null;
  if (attrName == 'DisplayName'){
    displayName = value;
    FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId).update(
      { attrName : value });
  } else if (attrName == 'Admins'){
    admins = value;
    FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId).update(
        { attrName : value });
  } else if (attrName == 'FullName'){
    fullName = value;
    FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId)
        .collection('Customer').doc(selectedPlayerDoc!.id).update(
        { attrName : value });
  } else if (attrName == 'Room') {
    room = value;
    FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId)
        .collection('Customer').doc(selectedPlayerDoc!.id).update(
        { attrName: value});
  } else if (attrName == 'TravelWith') {
    travelWith = value;
    FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId)
        .collection('Customer').doc(selectedPlayerDoc!.id).update(
        { attrName: value});
  }else if (attrName == 'Resident') {

    resident = (value == 'true');
    initialValues[row] = resident;
    FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId)
        .collection('Customer').doc(selectedPlayerDoc!.id).update(
        { attrName: resident});
  }else if (attrName == 'Staff') {
    staff = (value == 'true');
    initialValues[row] = staff;
    FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId)
        .collection('Customer').doc(selectedPlayerDoc!.id).update(
        { attrName: staff});
  }
}
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) =>
    String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

class Administration extends StatefulWidget {
  final DocumentSnapshot<Object?>? adminCustomerDoc;
  const Administration( {super.key,required this.adminCustomerDoc});

  @override
  AdministrationState createState() => AdministrationState();
}

class AdministrationState extends State<Administration> {

  List<TextEditingController> editControllers = List.empty(growable: true);
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController ladderNameController = TextEditingController();
  final _emailKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormState>();
  String _newUserErrorMessage = '';

  List<String?> errorText = List.filled(globalHelpText.length, null);
  String? errorEmail;
  String? errorName;
  String? errorNewLadder;
  String? errorTestField;
  @override
  void initState() {
    super.initState();
    // print('admin_page, initState $loggedInUserDoc');
    selectedPlayerDoc = widget.adminCustomerDoc;
    initialValues = globalStaticValues();
    for (int i = 0; i < initialValues.length; i++) {
      if (initialValues[i].runtimeType == String) {
        editControllers.add(TextEditingController(text: initialValues[i]));
      } else {
        editControllers.add(TextEditingController(text: ''));
      }

    }
    selectedNameController.text = '';
    if (selectedPlayerDoc != null) {
      // print('admin_page initState: ${selectedPlayerDoc!.id}');
      selectedNameController.text = selectedPlayerDoc!.get('FullName');
    }
    globalAdministration = this;

    // print('selectedPlayerDoc: $selectedPlayerDoc');
  }

  void setErrorState(int row, String? value) {
    setState(() {
      errorText[row] = value;
    });
  }

  // void setNewLadderError(String? value) {
  //   setState(() {
  //     errorNewLadder = value;
  //   });
  // }

  void deleteCustomer(String email)async {
    print('delete user $email');
    await FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId)
        .collection('Customer').doc(email).delete();
    print('the actual authentication user with password can not be deleted here');

  }
  void createUser(String newEmail, String fullName) async {
    var foundUser = allDocs!.firstWhereOrNull((doc) => doc.id == newEmail);
    if (foundUser != null){
        print('createUser $newEmail but that user already exists');
        setState(() {
          _newUserErrorMessage = 'that email already in this ladder';
        });
        return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: newEmail,
        password: '123456', //getRandomString(10),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // this is ok as a player can be in more than 1 ladder
        if (kDebugMode) {
          print('The account already exists for that email.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      setState(() {
        _newUserErrorMessage = e.toString();
      });
      return;
    }
    try {
      await FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId)
          .collection('Customer').doc(newEmail).set({
        'FullName': fullName,
        'LastUpdatedBy': '',
        'Present': false,
        'Resident': false,
        'Staff': false,
        'Room': '',
        'TravelWith': '',
      }
      );

    } catch (e) {
      print('error creating new Customer doc $e');
    }


    // await UserName.buildUserDB();
    setState(() {
      _newUserErrorMessage = 'Player added';
    });
    // homeStateInstance!.setState(() {});
  }

  TextEditingController selectedNameController = TextEditingController();
  String? selectedNameErrorText;
  OutlinedButton makeDoubleConfirmationButton(
      {buttonText,
        buttonColor = Colors.blue,
        dialogTitle,
        dialogQuestion,
        disabled,
        onOk}) {
    // print('administration build ${Player.admin1Enabled}');
    return OutlinedButton(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black, backgroundColor: buttonColor),
        onPressed: disabled
            ? null
            : () => showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(dialogTitle),
              content: Text(dialogQuestion),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('cancel', style: nameStyle)),
                TextButton(
                    onPressed: () {
                      setState(() {
                        onOk();
                      });

                      Navigator.pop(context);
                    },
                    child: const Text('OK')),
              ],
            )),
        child: Text(buttonText));
  }
  @override
  Widget build(BuildContext context) {
    bool isAdmin = buildingDoc!.get('Admins').split(',').contains(loggedInUser);
    return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: const Text('Administration:'),
          backgroundColor: Colors.brown[400],
          elevation: 0.0,

        ),
        body: ListView(shrinkWrap: true, children: [
          const SizedBox(height: 10),
          Column(children: [
            const SizedBox(width: 10),
            ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                // separatorBuilder: (context, index) => const Divider(color: Colors.black),
                padding: const EdgeInsets.all(8),
                itemCount: globalAttrNames.length,
                itemBuilder: (BuildContext context, int row) {
                  if (initialValues[row]==null){
                    return Column(
                      children: [
                        const Divider(thickness: 5, color: Colors.black,),
                        Text('Email:${selectedPlayerDoc!.id}', style: nameStyle,),
                      ],
                    );
                  }
                  else if (initialValues[row].runtimeType == String) {
                    // print('row:$row, ${initialValues[row]}');
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        readOnly: (row<2)&&!isAdmin,
                        keyboardType: TextInputType.text,
                        controller: editControllers[row],
                        decoration: textFormFieldStandardDecoration.copyWith(
                          labelText: globalAttrNames[row],
                          helperText: globalHelpText[row],
                          errorText: errorText[row],
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  setGlobalAttribute(row, globalAttrNames[row],
                                      editControllers[row].text, errorText);
                                });
                              },
                              icon: const Icon(Icons.send)),
                        ),
                        onChanged: (value) {
                          setState(() {
                            errorText[row] = 'Not Saved';
                          });
                        },
                      ),
                    );
                  } else if (initialValues[row].runtimeType == bool)
                  {
                    // print('row: $row bool type: ${initialValues[row].runtimeType }');
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Checkbox(
                              value: initialValues[row],
                              onChanged:  isAdmin?(value) {
                                setGlobalAttribute(row, globalAttrNames[row],
                                    value.toString(), errorText);
                                setState(() {});
                              }:null),
                          Text(globalHelpText[row], style: nameStyle),
                        ],
                      ),
                    );
                  } else {
                    return const Text('ERROR unsupported data type');
                  }
                }),
            makeDoubleConfirmationButton(
              buttonText: 'DELETE Customer: ${selectedPlayerDoc!.id}\n ${selectedPlayerDoc!.get('FullName')}',
              buttonColor: Colors.red[100],
              dialogTitle: 'Delete a user completely',
              dialogQuestion: 'Are you sure you want to remove ${selectedPlayerDoc!.id} completely?',
              disabled: !isAdmin,
              onOk: () {
                deleteCustomer(selectedPlayerDoc!.id);
              }
            ),
            const Divider(
              color: Colors.black,
              thickness: 6.0,
            ),
              Text(
                'Add new User to ${buildingDoc!.get('DisplayName')}',
                style: nameStyle,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(width: 1000,  // to make the form take full width
                  child: Form(
                    key: _emailKey,
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      controller: emailController,
                      validator: isAdmin?(value) {
                        if (value == null) return null;
                        String newValue = value.trim().replaceAll(RegExp(r' \s+'), ' ');
                        if (value != newValue) {
                          emailController.text = newValue;
                        }
                        if (newValue.isValidEmail()) {
                          return null;
                        }
                        return "Not a valid email address";
                      }:null,
                      decoration: textFormFieldStandardDecoration.copyWith(
                        labelText: 'New User Email',
                        helperText: 'Email address for new user',
                        errorText: errorEmail,
                      ),
                      onChanged: (value) {
                        setState(() {
                          errorEmail = 'not saved';
                        });
                      },
                    ),
                  ),

                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container( width:1000,
                  child: Form(
                    key: _nameKey,
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      controller: nameController,
                      validator: (value) {
                        if (value == null) return null;
                        String newValue = value.trim().replaceAll(RegExp(r' \s+'), ' ');
                        if (value != newValue) {
                          nameController.text = newValue;
                        }
                        if (newValue.isValidName()) {
                          return null;
                        }
                        return "Not a valid name First Last";
                      },
                      decoration: textFormFieldStandardDecoration.copyWith(
                        labelText: 'New User Name',
                        helperText: 'First and Last Name of new user',
                        errorText: errorName,
                        suffixIcon: IconButton(
                            onPressed: () {
                              if (_emailKey.currentState!.validate() && _nameKey.currentState!.validate()) {
                                setState(() {
                                  print('create new user ${emailController.text} with name ${nameController.text}');
                                  createUser(emailController.text, nameController.text);
                                  errorEmail = null;
                                  errorName = null;
                                  // emailController.text='';
                                  // nameController.text='';
                                });
                              }
                            },
                            icon: const Icon(Icons.send)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          errorName = 'not saved';
                        });
                      },
                    ),
                  ),
                ),
              ),
              Text(_newUserErrorMessage, style: errorNameStyle),
              const Divider(
                color: Colors.black,
                thickness: 6.0,
              ),
          ])]));

  }
}
