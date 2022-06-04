import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chatting/allConstants/all_constants.dart';
import 'package:chatting/allWidgets/loading_view.dart';
import 'package:chatting/models/chat_user.dart';
import 'package:chatting/providers/auth_provider.dart';
import 'package:chatting/providers/home_provider.dart';
import 'package:chatting/screens/chat_page.dart';
import 'package:chatting/screens/login_page.dart';
import 'package:chatting/screens/profile_page.dart';
import 'package:chatting/utilities/debouncer.dart';
import 'package:chatting/utilities/keyboard_utils.dart';

import '../models/sticker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController scrollController = ScrollController();

  int _limit = 20;
  final int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;

  Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> buttonClearController = StreamController<bool>();
  TextEditingController searchTextEditingController = TextEditingController();

  Future<void> googleSignOut() async {
    authProvider.googleSignOut();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<void> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return SimpleDialog(
            backgroundColor: AppColors.burgundy,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Выход из приложения',
                  style: TextStyle(color: AppColors.white),
                ),
                Icon(
                  Icons.exit_to_app,
                  size: 25,
                  color: Colors.white,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Sizes.dimen_10),
            ),
            children: [
              vertical10,
              const Text(
                'Вы уверены?',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.white, fontSize: Sizes.dimen_16),
              ),
              vertical15,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 0);
                    },
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 1);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Sizes.dimen_8),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: const Text(
                        'Да',
                        style: TextStyle(color: AppColors.spaceCadet),
                      ),
                    ),
                  )
                ],
              )
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  void scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    buttonClearController.close();
  }

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();
    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false);
    }

    scrollController.addListener(scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: addSticker,
            icon: const Icon(Icons.add),
          ),
            centerTitle: true,
            title: const Text('Jingle Pectus'),
            actions: [
              IconButton(
                  onPressed: () => googleSignOut(),
                  icon: const Icon(Icons.logout)),
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()));
                  },
                  icon: const Icon(Icons.person)),
            ]),
        body: WillPopScope(
          onWillPop: onBackPress,
          child: Stack(
            children: [
              Column(
                children: [
                  buildSearchBar(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: homeProvider.getFirestoreData(
                          FirestoreConstants.pathUserCollection,
                          _limit,
                          _textSearch),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          if ((snapshot.data?.docs.length ?? 0) > 0) {
                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) => buildItem(
                                  context, snapshot.data?.docs[index]),
                              controller: scrollController,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(),
                            );
                          } else {
                            return const Center(
                              child: Text('No user found...', style: TextStyle(color: Colors.white70),),
                            );
                          }
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                child:
                    isLoading ? const LoadingView() : const SizedBox.shrink(),
              ),
            ],
          ),
        ));
  }

  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(Sizes.dimen_10),
      height: Sizes.dimen_50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: Sizes.dimen_10,
          ),
          const Icon(
            Icons.person_search,
            color: AppColors.white,
            size: Sizes.dimen_24,
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: searchTextEditingController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  buttonClearController.add(true);
                  setState(() {
                    _textSearch = value;
                  });
                } else {
                  buttonClearController.add(false);
                  setState(() {
                    _textSearch = "";
                  });
                }
              },
              decoration: const InputDecoration.collapsed(
                hintText: 'Поиск...',
                hintStyle: TextStyle(color: AppColors.white),
              ),
            ),
          ),
          StreamBuilder(
              stream: buttonClearController.stream,
              builder: (context, snapshot) {
                return snapshot.data == true
                    ? GestureDetector(
                        onTap: () {
                          searchTextEditingController.clear();
                          buttonClearController.add(false);
                          setState(() {
                            _textSearch = '';
                          });
                        },
                        child: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.greyColor,
                          size: 20,
                        ),
                      )
                    : const SizedBox.shrink();
              })
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Sizes.dimen_30),
        color: AppColors.spaceLight,
      ),
    );
  }


  void addSticker() async {
    XFile? imageResult;
    PlatformFile? audioFile;
    Sticker sticker = Sticker(img: '', name: '', tag: '');

    showDialog(context: context, builder: (c) => Center(
      child: Material(
        child: StatefulBuilder(
            builder: (context, ss) {
              return Container(
                padding: EdgeInsets.all(12.0),
                width: MediaQuery.of(context).size.width * 4/5,
                height: MediaQuery.of(context).size.height * 1/2,
                child: Column(
                  children: [
                    Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Имя'
                          ),
                          onChanged: (value) {
                            sticker.name = value;
                          },
                        ),
                        SizedBox(height: 8.0,),
                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Тег'
                          ),
                          onChanged: (value) {
                            sticker.tag = value.replaceAll('#', '');
                          },
                        ),
                        SizedBox(height: 8.0,),
                        Row(
                          children: [
                            TextButton(onPressed: () async {
                              imageResult = await ImagePicker().pickImage(
                                imageQuality: 70,
                                maxWidth: 1440,
                                source: ImageSource.gallery,
                              );
                              ss((){});
                            }, child: Text('Выберите стикер')),
                            Expanded(child: GestureDetector(
                                onTap: () => ss((){audioFile = null;}),
                                child: Text(imageResult?.name ?? '')))
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(onPressed: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles();
                              if (result != null && result.files.isNotEmpty) {
                                audioFile = result.files.first;
                              }
                              ss((){});
                            }, child: Text('Выберите звук')),
                            Expanded(child: GestureDetector(
                                onTap: () => ss((){audioFile = null;}),
                                child: Text(audioFile?.name ?? '')))
                          ],
                        ),
                      ],
                    ),
                    Expanded(
                      child:  TextButton(onPressed: () async {
                        if (imageResult != null) {
                          var imagePath = await uploadFile(PlatformFile(path: imageResult!.path, name: imageResult!.name, size: await imageResult!.length()), 'stickers');
                          sticker.img = imagePath;
                          if (audioFile != null) {
                            var soundPath = await uploadFile(audioFile!, 'stickers');
                            sticker.sound = soundPath;
                          }
                          await FirebaseFirestore.instance.collection('stickers').add(sticker.toJson());
                          Navigator.pop(context);
                        }
                      }, child: Text('Добавить')),
                    )
                  ],
                ),
              );
            }
        ),
      ),
    ));
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? documentSnapshot) {
    final firebaseAuth = FirebaseAuth.instance;
    if (documentSnapshot != null) {
      ChatUser userChat = ChatUser.fromDocument(documentSnapshot);
      if (userChat.id == currentUserId) {
        return const SizedBox.shrink();
      } else {
        return TextButton(
          onPressed: () {
            if (KeyboardUtils.isKeyboardShowing()) {
              KeyboardUtils.closeKeyboard(context);
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                          peerId: userChat.id,
                          peerAvatar: userChat.photoUrl,
                          peerNickname: userChat.displayName,
                          userAvatar: firebaseAuth.currentUser!.photoURL!,
                        )));
          },
          child: ListTile(
            leading: userChat.photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Sizes.dimen_30),
                    child: Image.network(
                      userChat.photoUrl,
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      loadingBuilder: (BuildContext ctx, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                                color: Colors.grey,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null),
                          );
                        }
                      },
                      errorBuilder: (context, object, stackTrace) {
                        return const Icon(Icons.account_circle, size: 50);
                      },
                    ),
                  )
                : const Icon(
                    Icons.account_circle,
                    size: 50,
                  ),
            title: Text(
              userChat.displayName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }
}
