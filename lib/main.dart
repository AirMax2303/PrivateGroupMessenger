import 'dart:async';

import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

//import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Private Group Messenger',
      home: HomePage(),
    );
  }
}

class GuestBookMessage {
  GuestBookMessage(
      {required this.name, required this.message, required this.timestamp});

  final String name;
  final String message;
  final int timestamp;
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum ApplicationLoginState {
  loggedout,
  emailAddress,
  register,
  password,
  loggedIn,
}

class _HomePageState extends State<HomePage> {
  ApplicationLoginState _loginState = ApplicationLoginState.loggedout;
  String _email = '';
  String _password = '';
  String _displayName = '';
  final _controllerEmail = TextEditingController();
  final _controllerPassword = TextEditingController();
  final _controllerUserName = TextEditingController();
  StreamSubscription<QuerySnapshot>? _guestBookSubscription;
  List<GuestBookMessage> _guestBookMessages = [];

  StreamSubscription<QuerySnapshot>? _ChatUserSubscription;
  List<ChatUser> _ChatUsers = [];
  List<ChatMessage> ChatMessages = [];

  String customPropertie = '';

// TODO: Переменные
  ChatUser chatUser = ChatUser(id: '');

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    print('Dispose used');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print('didChangeAppLifecycleState');
    switch (state) {
      case AppLifecycleState.resumed:
        print('resumed');

        break;
      case AppLifecycleState.inactive:
        print('inactive');
        break;
      case AppLifecycleState.paused:
        print('paused');
        break;
      case AppLifecycleState.detached:
        print('detached');
        break;
    }
  }

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginState = ApplicationLoginState.loggedIn;
        // Add from here
        _guestBookSubscription = FirebaseFirestore.instance
            .collection('guestbook')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          _guestBookMessages = [];
          for (final document in snapshot.docs) {
            _guestBookMessages.add(
              GuestBookMessage(
                name: document.data()['name'] as String,
                message: document.data()['text'] as String,
                timestamp: (document.data()['timestamp'] as int) * 1000,
              ),
            );
            print(document.data()['text'] as String);
          }
        });
        setState(() {});
      }
    });

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        // Add from here
        _ChatUserSubscription = FirebaseFirestore.instance
            .collection('ChatUser')
            .orderBy('name', descending: true)
            .snapshots()
            .listen((snapshot) {
          _ChatUsers = [];
          for (final document in snapshot.docs) {
            _ChatUsers.add(
              ChatUser(
                id: document.data()['name'] as String,
                profileImage: document.data()['profileImage'] as String,
                customProperties: {
                  '1': document.data()['customProperties'] as String
                },
                firstName: document.data()['firstName'] as String,
                lastName: document.data()['lastName'] as String,
              ),
            );
            print(document.data()['name'] as String);
          }
        });
        setState(() {});
      }
    });

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        // Add from here
        _ChatUserSubscription = FirebaseFirestore.instance
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
          setState(() {
            ChatMessages = [];
            for (final document in snapshot.docs) {
              ChatMessages.add(
                ChatMessage(
                  user: ChatUser(id: document.data()['user'] as String),
                  createdAt: DateTime.fromMicrosecondsSinceEpoch(
                      document.data()['createdAt'] as int),
                  //document.data()['createdAt'] as int,
                  text: (document.data()['user'] as String) +
                      (' - ') +
                      (document.data()['text'] as String),
                  medias: [],
                  //document.data()['medias'] as String,
                  quickReplies: [],
                  //document.data()['quickReplies'] as String,
                  customProperties: {},
                  //document.data()['customProperties'] as String,
                  mentions: [],
                  //document.data()['mentions'] as String,
                  status: MessageStatus.none,
                  //document.data()['status'] as String,
                  replyTo: ChatMessage(
                      createdAt: DateTime.now(), user: ChatUser(id: 'replyTo')),
                ),
              );
              print('------------------------------------');
              print(ChatMessages.length);
              print(document.data()['user'] as String);
            }
            print('------------for--------------');
            for (int i = 0; i < ChatMessages.length; i++) {
              print(ChatMessages[i].text);
            }
          });
        });
      }
    });
  }

  void setEmailState() {
    Future.delayed(const Duration(milliseconds: 450), () {
      setState(() {
        _loginState = ApplicationLoginState.emailAddress;
      });
    });
  }

  Future<void> verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      print('Start verifyEmail');
      var methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      print('Stop fetchSignInMethodsForEmail');
      if (methods.contains('password')) {
        _loginState = ApplicationLoginState.password;
      } else {
        _loginState = ApplicationLoginState.register;
      }
      setState(() {
        _email = email;
      });
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  Future<void> signInWithEmailAndPassword(
    String password,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: password,
      );
      String? s = FirebaseAuth.instance.currentUser!.displayName;
      _displayName = s ?? '';
      chatUser.id = _displayName;
      print(_displayName);
      setState(() {
        _password = password;
        _loginState = ApplicationLoginState.loggedIn;
      });
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  Future<void> registerAccount(String displayName, String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email, password: password);
      await credential.user!.updateDisplayName(displayName);
      chatUser.id = displayName;
      addChatUser(chatUser);
      setState(() {
        _password = password;
        _displayName = displayName;
        _loginState = ApplicationLoginState.loggedIn;
      });
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  //TODO: addChatUser
  Future<DocumentReference> addChatUser(ChatUser u) {
    if (_loginState != ApplicationLoginState.loggedIn) {
      throw Exception('Must be logged in');
    }
    print('Begin AddUserOK===============================');
    return FirebaseFirestore.instance
        .collection('ChatUser')
        .add(<String, dynamic>{
      'name': u.id,
      'profileImage': u.profileImage ?? '',
      'customProperties': '',
      'firstName': u.firstName ?? '',
      'lastName': u.lastName ?? '',
    });
    print('End AddUserOK===============================');
  }

  Future<void> addMessege(ChatMessage m) async {
    addMesseges(m);
    setState(() {
      ChatMessages.insert(0, m);
    });
  }

  // TODO addMesseges
  Future<DocumentReference> addMesseges(ChatMessage me) {
    if (_loginState != ApplicationLoginState.loggedIn) {
      throw Exception('Must be logged in');
    }
    String? userId = me.user.id;
    print('Begin addMessegesOK===============================');
    return FirebaseFirestore.instance
        .collection('messages')
        .add(<String, dynamic>{
      'user': userId ?? 'Bad_User',
      'createdAt': DateTime.now().microsecondsSinceEpoch, //me.createdAt.microsecondsSinceEpoch,
      'text': me.text ?? 'Wrong Message',
      'medias': '',
      'quickReplies': '',
      'customProperties': '',
      'mentions': '',
      'status': '',
      'replyTo': '',
    });
    print('End addMessegesOK===============================');
  }

  Future<void> saveTestmessage(ChatMessage me) async {
    FirebaseFirestore.instance.collection('messages').add(<String, dynamic>{
      'user': me.user.id ?? 'Bad_User',
      'createdAt': 12414,
      'text': me.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_loginState) {
      case ApplicationLoginState.loggedout:
        return Scaffold(
          body: Center(
            child: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.blue,
                  Colors.red,
                ],
              )),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PGM',
                        style: TextStyle(
                          fontSize: 48.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'КУБГУ. Летняя практика.',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        height: 1.0,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Максим Лысенко. ФКТиПМ группа 24/1',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        height: 100.0,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedButton(
                        //https://pub.dev/packages/flutter_animated_button
                        onPress: () {
                          setEmailState();
                        },
                        height: 52,
                        width: 200,
                        text: 'Login',
                        gradient: const LinearGradient(
                            colors: [Colors.red, Colors.orange]),
                        selectedGradientColor: const LinearGradient(
                            colors: [Colors.yellow, Colors.lightBlueAccent]),
                        //colors: [Colors.pinkAccent, Colors.purpleAccent]),
                        isReverse: true,
                        selectedTextColor: Colors.black,
                        transitionType: TransitionType.LEFT_CENTER_ROUNDER,
                        //borderColor: Colors.white,
                        borderWidth: 1,
                        borderRadius: 70,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            /*  Old Button
            TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.focused))
                        return Colors.grey;
                      return Colors.cyanAccent;
                    },
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black87), //- меняет цвет шрифта
              ),
              onPressed: () {
                setEmailState();
              },
              child: const Text('Login'),
            ),
            */
          ),
        );
// ApplicationLoginState.emailAddress----------------------------------------------------
      case ApplicationLoginState.emailAddress:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _controllerEmail,
                        decoration: const InputDecoration(
                          hintText: 'Введите Email...',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Введите Email-адрес для продолженя!';
                          }
                          return null;
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: () {
                              verifyEmail(
                                  _controllerEmail.text,
                                  (e) => _showErrorDialog(
                                      context, 'Invalid email', e));
                            },
                            child: const Text('Отправить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
// ApplicationLoginState.register----------------------------------------------------
      case ApplicationLoginState.register:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                child: Column(
                  children: <Widget>[
                    Text(_email),
                    const Divider(),
                    TextFormField(
                      controller: _controllerUserName,
                      decoration: const InputDecoration(
                        hintText: 'Введите имя пользователя',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Введите имя пользователя для продолжения!';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _controllerPassword,
                      decoration: const InputDecoration(
                        hintText: 'Введите пароль...',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Введите пароль для продолжения!';
                        }
                        return null;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: () {
                              registerAccount(
                                  _controllerUserName.text,
                                  _controllerPassword.text,
                                  (e) => _showErrorDialog(
                                      context,
                                      'Некорректные Имя пользователя или Пароль',
                                      e));
                            },
                            child: const Text('Отправить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
// ApplicationLoginState.password----------------------------------------------------
      case ApplicationLoginState.password:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                child: Column(
                  children: <Widget>[
                    Text(_email),
                    const Divider(),
                    TextFormField(
                      controller: _controllerPassword,
                      decoration: const InputDecoration(
                        hintText: 'Введите пароль...',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Введите пароль для продолжения!';
                        }
                        return null;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: () {
                              signInWithEmailAndPassword(
                                  _controllerPassword.text,
                                  (e) => _showErrorDialog(
                                      context, 'Invalid email', e));
                            },
                            child: const Text('Отправить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
// ApplicationLoginState.loggedIn----------------------------------------------------
      case ApplicationLoginState.loggedIn:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Private Group Messenger'),
            actions: [
              /*
              PopupMenuButton(
                icon: Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (context) {
                          return Scaffold(
                            appBar: AppBar(
                              title: const Text('Пользователи'),
                            ),
                            body: ListView.builder(
                                itemCount: _ChatUsers.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return const Text(
                                      'Тут будет список пользователей!');
                                }),
                          );
                        }));
                      },
                      icon: const Icon(Icons.account_box),
                    ),
                  ),
                ],
              ),
              */
              IconButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (context) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Пользователи'),
                      ),
                      body: ListView.builder(
                          itemCount: _ChatUsers.length,
                          itemBuilder: (BuildContext context, int index) {
                            return GestureDetector(
                              child: Card(
                                child: ListTile(
                                  leading: const FlutterLogo(),
                                  title: Text(_ChatUsers[index].id),
                                  subtitle: const Text('Сотрудник компании'),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return Scaffold(
                                    appBar: AppBar(
                                      title: Text(_ChatUsers[index].id),
                                    ),
                                    body: Text('Индекс $index'),
                                  );
                                }));
                              },
                            );
                          }),
                    );
                  }));
                },
                icon: const Icon(Icons.account_box),
              ),
            ],
          ),
          body: DashChat(
            messageOptions: MessageOptions(
              containerColor: Color(0x80EDFFFF),
            ),
            currentUser: chatUser,
            onSend: (ChatMessage m) {
              print('DashChat.onSend start');
              //saveTestmessage(m);
              addMessege(m);
              print('DashChat.onSend stop');
            },
            messages: ChatMessages,
            messageListOptions: MessageListOptions(
              onLoadEarlier: () async {
                print('------------------onLoadEarlier------------------');
                await Future.delayed(const Duration(seconds: 1));
              },
            ),
          ),
        );
      // TODO: ${DateTime.fromMicrosecondsSinceEpoch(_guestBookMessages[index].timestamp)}
// End--------------------------------------------------------------------------
    }
  }

  void _showErrorDialog(BuildContext context, String title, Exception e) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 24),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '${(e as dynamic).message}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {},
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );
  }
}
