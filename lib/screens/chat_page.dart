import 'dart:io';

import 'package:chatting/allConstants/all_constants.dart';
import 'package:chatting/allWidgets/common_widgets.dart';
import 'package:chatting/models/chat_messages.dart';
import 'package:chatting/providers/auth_provider.dart';
import 'package:chatting/providers/chat_provider.dart';
import 'package:chatting/providers/profile_provider.dart';
import 'package:chatting/screens/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sticker.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  final String userAvatar;

  const ChatPage(
      {Key? key,
      required this.peerNickname,
      required this.peerAvatar,
      required this.peerId,
      required this.userAvatar})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessages = [];

  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = '';

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  Map<String, Sticker> stickers = {};
  final player = AudioPlayer();
  String lastMessageId = '';
  List<String> audioQueue = [];
  int lastMessage = -1;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    focusNode.addListener(onFocusChanged);
    scrollController.addListener(_scrollListener);
    SharedPreferences.getInstance().then((value) {
      readMessages.addAll(value.getStringList(groupChatId) ?? <String>[]);
    });
    readLocal();
    loadStickers();
  }

  _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChanged() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false);
    }
    if (currentUserId.compareTo(widget.peerId) > 0) {
      groupChatId = '$currentUserId - ${widget.peerId}';
    } else {
      groupChatId = '${widget.peerId} - $currentUserId';
    }
    chatProvider.updateFirestoreData(FirestoreConstants.pathUserCollection,
        currentUserId, {FirestoreConstants.chattingWith: widget.peerId});
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadImageFile();
      }
    }
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future<bool> onBackPressed() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateFirestoreData(FirestoreConstants.pathUserCollection,
          currentUserId, {FirestoreConstants.chattingWith: null});
    }
    return Future.value(false);
  }

  void _callPhoneNumber(String phoneNumber) async {
    var url = 'tel://$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Error Occurred';
    }
  }

  void uploadImageFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadImageFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, MessageType.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content, int type,
      {Map<String, dynamic>? metadata}) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();

      if (type == MessageType.text &&
          content.startsWith('#') &&
          stickers[content.replaceFirst('#', '').trim().toLowerCase()] !=
              null) {
        sendSticker(
            stickers[content.replaceFirst('#', '').trim().toLowerCase()]!);
        return;
      }
      chatProvider.sendChatMessage(
          content, type, groupChatId, currentUserId, widget.peerId,
          metadata: metadata
      );
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Нечего отправить', backgroundColor: Colors.grey);
    }
  }

  Future<void> sendSticker(Sticker sticker) async {
    return onSendMessage(sticker.img, MessageType.sticker, metadata: {
      'sticker': sticker.tag,
      'sound': sticker.sound,
    });
  }

  // checking if received message
  bool isMessageReceived(int index) {
    if ((index > 0 &&
            listMessages[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  // checking if sent message
  bool isMessageSent(int index) {
    if ((index > 0 &&
            listMessages[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> loadStickers() async {
    var query = await FirebaseFirestore.instance.collection('stickers').get();
    for (var element in query.docs) {
      var sticker = Sticker.fromJson(element.data());
      stickers[sticker.tag] = sticker..preload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Чат с ${widget.peerNickname}'.trim()),
        actions: [
          IconButton(
            onPressed: () {
              ProfileProvider profileProvider;
              profileProvider = context.read<ProfileProvider>();
              String callPhoneNumber =
                  profileProvider.getPrefs(FirestoreConstants.phoneNumber) ??
                      "";
              _callPhoneNumber(callPhoneNumber);
            },
            icon: const Icon(Icons.phone),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.dimen_8),
          child: LayoutBuilder(builder: (context, c) {
            return Stack(
              children: [
                Column(
                  children: [
                    buildListMessage(),
                    SizedBox(
                      height: c.maxHeight / 10 * 1.1,
                    )
                  ],
                ),
                DraggableScrollableSheet(
                  initialChildSize: 56 / c.maxHeight,
                  minChildSize: 56 / c.maxHeight,
                  maxChildSize: 0.6,
                  controller: draggableScrollableController,
                  snap: true,
                  builder: (BuildContext context,
                      ScrollController scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        padding: EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.black.withOpacity(0.9),
                        ),
                        child: Column(
                          children: [
                            buildMessageInput(),
                            SizedBox(
                              height: 0.5 * c.maxHeight,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: LayoutBuilder(
                                  builder: (BuildContext context,
                                          BoxConstraints constraints) =>
                                      SingleChildScrollView(
                                    child: Wrap(
                                      alignment: WrapAlignment.start,
                                      runSpacing: 8.0,
                                      spacing: 8.0,
                                      children: [
                                        ...stickers.values.map((e) =>
                                            GestureDetector(
                                              onTap: () {
                                                sendSticker(e);
                                                draggableScrollableController
                                                    .reset();
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: SizedBox(
                                                    width:
                                                        constraints.maxWidth /
                                                            4,
                                                    height:
                                                        constraints.maxWidth /
                                                            4,
                                                    child: Image.network(
                                                      e.img,
                                                      fit: BoxFit.fill,
                                                    )),
                                              ),
                                            ))
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget buildMessageInput() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: Sizes.dimen_4),
            decoration: BoxDecoration(
              color: AppColors.burgundy,
              borderRadius: BorderRadius.circular(Sizes.dimen_30),
            ),
            child: IconButton(
              onPressed: getImage,
              icon: const Icon(
                Icons.camera_alt,
                size: Sizes.dimen_28,
              ),
              color: AppColors.white,
            ),
          ),
          Flexible(
              child: TextField(
            focusNode: focusNode,
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: textEditingController,
            style: TextStyle(color: Colors.white),
            decoration: kTextInputDecoration.copyWith(
              hintText: 'Напишите здесь...',
              hintStyle: TextStyle(color: Colors.white70),
            ),
            onSubmitted: (value) {
              onSendMessage(textEditingController.text, MessageType.text);
            },
          )),
          Container(
            margin: const EdgeInsets.only(left: Sizes.dimen_4),
            decoration: BoxDecoration(
              color: AppColors.burgundy,
              borderRadius: BorderRadius.circular(Sizes.dimen_30),
            ),
            child: IconButton(
              onPressed: () {
                onSendMessage(textEditingController.text, MessageType.text);
              },
              icon: const Icon(Icons.send_rounded),
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(int index, ChatMessages chatMessages) {
    if (true) {
      if (chatMessages.idFrom == currentUserId) {
        // right side (my message)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                chatMessages.type == MessageType.text
                    ? messageBubble(
                        chatContent: chatMessages.content,
                        color: AppColors.spaceLight,
                        textColor: AppColors.white,
                        margin: const EdgeInsets.only(right: Sizes.dimen_10),
                      )
                    : chatMessages.type == MessageType.image
                        ? Container(
                            margin: const EdgeInsets.only(
                                right: Sizes.dimen_10, top: Sizes.dimen_10),
                            child: chatImage(
                                imageSrc: chatMessages.content, onTap: () {}),
                          )
                        : chatMessages.type == MessageType.sticker
                            ? Container(
                                margin: const EdgeInsets.only(
                                    right: Sizes.dimen_10, top: Sizes.dimen_10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(Sizes.dimen_16),
                                  child: chatImage(
                                    imageSrc: chatMessages.content,
                                    onTap: () {
                                      play(stickers[chatMessages.metadata?['sticker']]);
                                    },
                                    size: const Size(Sizes.dimen_100, Sizes.dimen_100),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                isMessageSent(index)
                    ? Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Sizes.dimen_20),
                        ),
                        child: Image.network(
                          widget.userAvatar,
                          width: Sizes.dimen_40,
                          height: Sizes.dimen_40,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext ctx, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.burgundy,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 35,
                              color: AppColors.greyColor,
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 35,
                      ),
              ],
            ),
            isMessageSent(index)
                ? Container(
                    margin: const EdgeInsets.only(
                        right: Sizes.dimen_50,
                        top: Sizes.dimen_6,
                        bottom: Sizes.dimen_8),
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(chatMessages.timestamp),
                        ),
                      ),
                      style: const TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: Sizes.dimen_12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(
              height: 6.0,
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                isMessageReceived(index)
                    // left side (received message)
                    ? Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Sizes.dimen_20),
                        ),
                        child: Image.network(
                          widget.peerAvatar,
                          width: Sizes.dimen_40,
                          height: Sizes.dimen_40,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext ctx, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.burgundy,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 35,
                              color: AppColors.greyColor,
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 35,
                      ),
                chatMessages.type == MessageType.text
                    ? messageBubble(
                        color: AppColors.burgundy,
                        textColor: AppColors.white,
                        chatContent: chatMessages.content,
                        margin: const EdgeInsets.only(left: Sizes.dimen_10),
                      )
                    : chatMessages.type == MessageType.image
                        ? Container(
                            margin: const EdgeInsets.only(
                                left: Sizes.dimen_10, top: Sizes.dimen_10),
                            child: chatImage(
                                imageSrc: chatMessages.content, onTap: () {}),
                          )
                        : chatMessages.type == MessageType.sticker
                    ? Container(
                  margin: const EdgeInsets.only(
                      left: Sizes.dimen_10, top: Sizes.dimen_10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Sizes.dimen_16),
                    child: chatImage(
                        imageSrc: chatMessages.content, onTap: () {
                          play(stickers[chatMessages.metadata?['sticker']]);
                    },
                      size: Size(Sizes.dimen_100, Sizes.dimen_100)
                    ),
                  ),
                ) : const SizedBox.shrink(),
              ],
            ),
            isMessageReceived(index)
                ? Container(
                    margin: const EdgeInsets.only(
                        left: Sizes.dimen_50,
                        top: Sizes.dimen_6,
                        bottom: Sizes.dimen_8),
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(chatMessages.timestamp),
                        ),
                      ),
                      style: const TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: Sizes.dimen_12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<void> play(Sticker? sticker, [debug = '']) async {
    print('play sticker: $debug ${sticker?.toJson()}');
    if (sticker == null) return;
    if (sticker.audioCache != null) {
      player.setFilePath(sticker.audioCache!).then((value) => player.play());
    } else if (sticker.sound != null) {
      player.setUrl(sticker.sound!).then((value) => player.play());
    }
  }

  Set<String> readMessages = {};

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatMessage(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessages = snapshot.data!.docs;
                  if (listMessages.isNotEmpty) {
                    var chatMessages = listMessages
                        .map((e) => ChatMessages.fromDocument(e))
                        .toList();

                    var filteredMessages = chatMessages
                        .where((element) =>
                    (element.metadata?.containsKey('sticker') ?? false) &&
                        (element.metadata!.containsKey('sound')) &&
                        (element.metadata!['sound'] != null) &&
                        (!readMessages.contains(element.timestamp))
                    );

                    audioQueue.addAll(filteredMessages.map((e) {
                      return e.metadata!['sticker'];
                    }));

                    var readNow = filteredMessages.map((e) => e.timestamp);
                    readMessages.addAll(readNow);
                    SharedPreferences.getInstance().then((value) {
                      value.setStringList(groupChatId,
                          (value.getStringList(currentUserId) ?? <String>[])
                            ..addAll(
                              readNow
                            )
                      );
                    });

                    if (audioQueue.isNotEmpty) {
                      var sticker = stickers[audioQueue.last];
                      audioQueue.clear();
                      if (sticker != null) {
                        play(sticker);
                      }
                    }

                    return ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: snapshot.data?.docs.length,
                        reverse: true,
                        controller: scrollController,
                        itemBuilder: (context, index) =>
                            buildItem(index, chatMessages[index]));
                  } else {
                    return const Center(
                      child: Text('Нет сообщений...'),
                    );
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.burgundy,
                    ),
                  );
                }
              })
          : const Center(
              child: CircularProgressIndicator(
                color: AppColors.burgundy,
              ),
            ),
    );
  }
}
