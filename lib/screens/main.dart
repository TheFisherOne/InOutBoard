import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../constants/firebase_setup.dart';
import 'admin_page.dart';


String loggedInUser = '';
DocumentSnapshot<Object?>? loggedInUserDoc;

String? buildingId;
String? inputPresent;
DocumentSnapshot<Object?>? buildingDoc;
List<QueryDocumentSnapshot<Object?>>? allDocs;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: myFirebaseOptions);
  runApp(const InOutBoardApp());
}

class InOutBoardApp extends StatelessWidget {
  const InOutBoardApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InOutBoard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appBarColor),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'InOutBoard $buildingId'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   Map? _uriParameters;
  bool _existingUserChecked = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  initState() {
    super.initState();
    // extract the site number from the URL
    _uriParameters = Uri.base.queryParameters;

    // this will always be lowercase
    if ((_uriParameters != null) && (_uriParameters!.containsKey('s'))) {
      print('initial building number is: ${_uriParameters!['s']}');
      buildingId = _uriParameters!['s'];
    } else {
      print('BUILD: no building specified in URL $_uriParameters');
      buildingId = null;
    }

    if ((_uriParameters != null) && (_uriParameters!.containsKey('p'))) {
      inputPresent = _uriParameters!['p'];
      print('initial Present is: "$inputPresent"');
      if ((inputPresent != '0') && (inputPresent != '1')) {
        print('URL error: p= must be either 0 or 1');
        inputPresent = null;
      }
    } else {
      inputPresent = null;
      print('BUILD: no Initial Present in URL $_uriParameters which is OK\nit can be specified with &&p=0 or &&p=1');
    }
  }

  bool _inGetBuildingDoc = false;
  bool _buildingIdNotFound = false;
  void getBuildingDoc() async {
    if (buildingDoc != null) return;
    if (_inGetBuildingDoc){
      print('ERROR: reentering getBuildingDoc');
      return;
    }
    _inGetBuildingDoc = true;

    print('getting $fireStoreCollectionName / $buildingId');
    var buildingDocRef = FirebaseFirestore.instance.collection(fireStoreCollectionName).doc(buildingId);

    buildingDocRef.get().then((doc) {
      if (doc.exists) {
        setState(() {
          buildingDoc = doc;
          print('getBuildingDoc:  DisplayName: Name: ${doc.get('DisplayName')} Admins:${doc.get('Admins')}  ');
        });
      }
      _inGetBuildingDoc = false;
    }, onError: (e) {
      print('ERROR: specified building doc $buildingId does not exist $e');
      setState(() {
        buildingDoc = null;
        _inGetBuildingDoc = false;
        _buildingIdNotFound = true;
      });
    });
  }

  bool _inGetUserDoc = false;
  Future<DocumentSnapshot?> getUserDoc(String testUser) async {
    if (_inGetUserDoc) {
      print('trying to reenter getUserDoc');
      return null;
    }

    if (testUser.trim().isEmpty) return null;
    _inGetUserDoc = true;
    var userDocRef = FirebaseFirestore.instance
        .collection(fireStoreCollectionName)
        .doc(buildingId)
        .collection('Customer')
        .doc(testUser);
    DocumentSnapshot doc = await userDocRef.get();
    print('getUserDoc: $testUser Exists: ${doc.exists} ');
    // print('getUserDoc: $testUser ${doc.exists}  DisplayName: ${doc.get('DisplayName')} Admins:${doc.get('Admins')}  ');
    if (doc.exists) {
      _inGetUserDoc = false;
      return doc;
    }

    print('ERROR: specified user doc $testUser does not exist');
    buildingDoc = null;
    _inGetUserDoc = false;
    return null;
  }

  void asyncGetUserDoc(String newUser) async {
    loggedInUserDoc = await getUserDoc(newUser);
  }

  void setLoggedInUser(String newUser) {
    asyncGetUserDoc(newUser);
    setState(() {
      loggedInUser = newUser;
    });
  }

  bool _inHandleStayedSignedIn = false;
  String _loginErrorString = '';

  _handleStayedSignedIn() async {
    if (_inHandleStayedSignedIn) {
      print('Trying to enter _handleStayedSignedIn more than once');
      return;
    }
    _inHandleStayedSignedIn = true;
    _existingUserChecked = false;
    String recoveredEmail = FirebaseAuth.instance.currentUser!.email!.toLowerCase();
    // print('_handleStayedSignedIn: $recoveredEmail');

    DocumentSnapshot<Object?>? userDoc = await getUserDoc(recoveredEmail);
    // print('_handleStayedSignedIn: userDoc $recoveredEmail $userDoc');
    if (userDoc == null) {
      setState(() {
        _loginErrorString = ' $recoveredEmail is not a valid user in building: $buildingId ';
      });
      print(_loginErrorString);
      FirebaseAuth.instance.signOut();
      setLoggedInUser('');
      _inHandleStayedSignedIn = false;
      return;
    }
    loggedInUserDoc = userDoc;
    // print('_handleStayedSignedIn: $userDoc  ${userDoc.get('FullName')}');

    setLoggedInUser(recoveredEmail);
    if (kDebugMode) {
      print('logged in with email: $loggedInUser');
    }
    _existingUserChecked = true;
    _inHandleStayedSignedIn = false;
  }

  void _signInWithEmailAndPassword() async {
    _loginErrorString = '';
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.toLowerCase(),
        password: _passwordController.text,
      );
      // print('LOGIN: have credential');
      if (userCredential.user == null) {
        setState(() {
          _loginErrorString = 'error signInWithEmail no user';
        });

        // print(_loginErrorString);
        return;
      }
      if (userCredential.user!.email == null) {
        setState(() {
          _loginErrorString = 'error signInWithEmail no user email';
        });
        // print(_loginErrorString);
        return;
      }
      // print('LOGIN: have email: ${userCredential.user!.email}');
      DocumentSnapshot<Object?>? userDoc = await getUserDoc(userCredential.user!.email!);
      if (userDoc == null) {
        setState(() {
          _loginErrorString = '${userCredential.user!.email!} is not a valid user in building $buildingId ';
        });
        // print(_loginErrorString);
        FirebaseAuth.instance.signOut();
        setLoggedInUser('');
        return;
      }
      setState(() {
        loggedInUserDoc = userDoc;
        loggedInUser = userCredential.user!.email!;
        // print('_signInWithEmailAndPassword: $userDoc  ${userDoc.get('FullName')}');
      });

      // setLoggedInUser(userCredential.user!.email!.toLowerCase());
      if (kDebugMode) {
        print('logged in with email: $loggedInUser');
      }
      return;
    } catch (e) {
      setState(() {
        _loginErrorString = 'Error: $e';
      });
      if (kDebugMode) {
        print(_loginErrorString);
      }
      return;
    }
  }

  Widget buildLoginPage() {
    return Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
              //
              // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
              // action in the IDE, or press "p" in the console), to see the
              // wireframe for each widget.
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  decoration: textFormFieldStandardDecoration.copyWith(labelText: 'Email'),
                  inputFormatters: [LowerCaseTextInputFormatter()],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: textFormFieldStandardDecoration.copyWith(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signInWithEmailAndPassword,
                  child: const Text('Sign in with Email'),
                ),
                // const SizedBox(height: 20),
                // SignInButton(Buttons.google,
                //   onPressed: _signInWithGoogle,),
                // const SizedBox(height: 20),
                // SignInButton(Buttons.facebook,
                //   onPressed: _signInWithFacebook,),
                const SizedBox(height: 20),
                Text(
                  _loginErrorString,
                  style: nameStyle,
                ),
              ],
            ),
          ),
        ));
  }

  void setPresent(DocumentSnapshot<Object?> user, bool state) async {
    if (state == user.get('Present')) return;
    await FirebaseFirestore.instance
        .collection(fireStoreCollectionName)
        .doc(buildingId)
        .collection('Customer')
        .doc(user.id)
        .update({
      'Present': state,
      'LastUpdatedBy': loggedInUser,
    });
  }

  Widget showInOut(DocumentSnapshot<Object?> userDoc) {
    return Column(children: [
      // const Divider(
      //   thickness: 2,
      // ),
      Text(
        "${userDoc.get('FullName')}",
        style: nameStyle,
      ),
      if (userDoc.get('Resident'))
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: userDoc.get('Present') ? Colors.blue : Colors.transparent, width: 8),
                  ),
                  child: IconButton(
                      iconSize: 70,
                      onPressed: () {
                        // print('CLICKED: present');
                        setState(() {
                          setPresent(userDoc, true);
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
                    border: Border.all(color: !userDoc.get('Present') ? Colors.blue : Colors.transparent, width: 8),
                  ),
                  child: IconButton(
                      iconSize: 70,
                      onPressed: () {
                        // print('CLICKED: away');
                        setState(() {
                          setPresent(userDoc, false);
                        });
                      },
                      icon: const Icon(Icons.exit_to_app)),
                ),

              ],
            ),
          ],
        ),
      if (!userDoc.get('Resident'))
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: userDoc.get('Present') ? Colors.green : Colors.transparent, width: 8),
                  ),
                  child: IconButton(
                      iconSize: 70,
                      onPressed: () {
                        // print('CLICKED: present');
                        setState(() {
                          setPresent(userDoc, true);
                        });
                      },
                      icon: const Icon(Icons.insert_emoticon)),
                ),

              ],
            ),
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: !userDoc.get('Present') ? Colors.green : Colors.transparent, width: 8),
                  ),
                  child: IconButton(
                      iconSize: 70,
                      onPressed: () {
                        // print('CLICKED: away');
                        setState(() {
                          setPresent(userDoc, false);
                        });
                      },
                      icon: const Icon(Icons.exit_to_app)),
                ),

              ],
            ),
          ],
        ),
      // const Divider(
      // const Divider(
      //   thickness: 2,
      // ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    TextButton makeDoubleConfirmationButton(
        {buttonText, buttonColor = Colors.blue, dialogTitle, dialogQuestion, disabled, onOk}) {
      // print('home.dart build ${FirebaseAuth.instance.currentUser?.email}');
      return TextButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: appBarColor),
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
                              child: const Text('cancel')),
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

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    if (buildingId == null) {
      return const Text('You must specify the building number with:\n https://in-out-board.web.app/?s=1234',
          style: nameStyle);
    }

    if ((FirebaseAuth.instance.currentUser == null) || (FirebaseAuth.instance.currentUser!.email == null)) {
      loggedInUser = "";
      // print('No User Logged In');
    } else {
      if (!_existingUserChecked) {
        print('checking existing user ${FirebaseAuth.instance.currentUser!.email} loggedInUser: $loggedInUser');
        _handleStayedSignedIn();
        return const CircularProgressIndicator();
      }
    }
    // print('LOGGED IN USER1: $loggedInUser');
    if (loggedInUser.isEmpty) {
      return buildLoginPage();
    }

    if (inputPresent != null) {
      print('inputPresent: "$inputPresent"');
      setPresent(loggedInUserDoc!, inputPresent == '1');
      inputPresent = null;
    }
    // print('LOGGED IN USER: $loggedInUser');
    // can't check building until someone is logged in
    if (_buildingIdNotFound) {
      //error case, can not continue
      return Text('ERROR invalid site number specified "$buildingId" in URL', style: nameStyle);
    }
    getBuildingDoc();
    if (buildingDoc == null) {
      print('waiting for buildingDoc to be read');
      return const CircularProgressIndicator();
    }

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(fireStoreCollectionName)
            .doc(buildingId)
            .collection('Customer')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          loggedInUserDoc = null;
          allDocs = null;
          if (snapshot.error != null) {
            String error = 'Snapshot error: ${snapshot.error.toString()} on getting doc $buildingId / $loggedInUser';
            if (kDebugMode) {
              print(error);
            }
            return Text(error);
          }
          // print('in StreamBuilder ladder 0');
          if (!snapshot.hasData) return const CircularProgressIndicator();

          if (snapshot.data == null) return const CircularProgressIndicator();
          if (snapshot.requireData.docs.length<=1) return const CircularProgressIndicator();

          allDocs = snapshot.requireData.docs;
          // print('allDocs1: ${allDocs![0].id}');
          // print('allDocs2: ${allDocs!.length} ');
          loggedInUserDoc = allDocs!.firstWhere((doc) => doc.id == loggedInUser);

          if (loggedInUserDoc == null) return Text('Cannot find a customer with email $loggedInUser');


          List<String> travelWith = loggedInUserDoc!.get('TravelWith').split(',');

          return Scaffold(
            appBar: AppBar(
                // TRY THIS: Try changing the color here to a specific color (to
                // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
                // change color while the other colors stay the same.
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                // Here we take the value from the MyHomePage object that was created by
                // the App.build method, and use it to set our appbar title.
                title: Text(widget.title),
                actions: <Widget>[
                  if (buildingDoc?.get('Admins').split(',').contains(loggedInUserDoc?.id)||
                  loggedInUserDoc!.get('Staff'))
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Administration()));
                      },
                      icon: const Icon(Icons.admin_panel_settings),
                      enableFeedback: true,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: makeDoubleConfirmationButton(
                        buttonText: 'Log\nOut',
                        dialogTitle: 'You will have to enter your password again',
                        dialogQuestion: 'Are you sure you want to logout?',
                        disabled: false,
                        onOk: () {
                          FirebaseAuth.instance.signOut();
                          setLoggedInUser('');
                        }),
                  ),
                ]),
            body: loggedInUser.isEmpty
                ? buildLoginPage()
                : Center(
                    // Center is a layout widget. It takes a single child and positions it
                    // in the middle of the parent.
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            "BUILDING: ${buildingDoc!.get('DisplayName')}",
                            style: nameStyle,
                          ),
                          showInOut(loggedInUserDoc!),
                          Text(
                            "EMAIL: $loggedInUser",
                            style: nameStyle,
                          ),
                          Text(
                            "ROOM: ${loggedInUserDoc!.get('Room')}",
                            style: nameStyle,
                          ),
                          if (loggedInUserDoc!.get('Staff'))
                            Text(
                              "STAFF: ${loggedInUserDoc!.get('Staff')}",
                              style: nameStyle,
                            ),
                          const Divider(thickness: 5,),
                          if ((travelWith.length>1) ||  (travelWith[0].isNotEmpty))
                          const Text('Friends', style: nameStyle,),
                          const Divider(thickness: 5,),
                          ListView.separated(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: travelWith.length,
                            separatorBuilder: (context, index) => const Divider(thickness: 5),
                            itemBuilder: (BuildContext context, int row) {
                              DocumentSnapshot<Object?>? thisDoc;
                              if (travelWith[row].isEmpty) return const Text(' ');
                              try {
                                thisDoc = allDocs!.firstWhere((doc) => doc.id == travelWith[row]);
                              } catch(e) {
                                return Text('Friend: ${travelWith[row]} invalid', style: nameStyle,);
                              }

                              return showInOut(thisDoc);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        });
  }
}
