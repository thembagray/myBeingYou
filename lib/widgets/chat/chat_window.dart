import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_project/screens/login.dart';

import '../../helpers/chat_handler.dart';
import '../../stores/chat_store.dart';
import '../../stores/user_store.dart';
import 'chat_input.dart';
import 'chat_window_user.dart';
import 'common_chat_widgets.dart';

class ChatWindow extends StatefulWidget {
  const ChatWindow({Key? key}) : super(key: key);

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  late String id, peerId, peerName, myName, peerImage, myImage;

  late List<QueryDocumentSnapshot> listMessage = List.from([]);
  String groupChatId = '';
  late ChatStore chatStore;

  late ScrollController listScrollController;

  @override
  void initState() {
    UserStore userStore = Provider.of<UserStore>(context, listen: false);
    chatStore = Provider.of<ChatStore>(context, listen: false);

    listScrollController = chatStore.listScrollController;
    
    myName = userStore.user.name!;
    id = userStore.user.uid!;
    peerId = chatStore.peerId;
    peerName = chatStore.peerName;
    peerImage = chatStore.peerImage;
    myImage = chatStore.myImage;
    groupChatId = getGroupChatId(id, peerId);

  
    groupChatId = getGroupChatId(id, peerId);

    // if(id == 'testing' && peerId == 'testing' && peerName == 'testing'){
    //    Future.delayed(const Duration(seconds: 2),(){
    //   Navigator.pushNamed(context, Login.id);
    // });
        
    //  }

    super.initState();
  }

  Widget buildItem(int index, DocumentSnapshot document,) {
    if (document.get('idFrom') == id) {
      // Right (my message)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isFirstMessageUser(
                  index, document.get('content'), listMessage, peerId)
              ? const SizedBox(height: 10)
              : Container(),
          isFirstMessageUser(
                  index, document.get('content'), listMessage, peerId)
              ? chatItemHeader(myName, myImage, document, context)
              : Container(),
          showChatItemBasedOnType(document, context, myName),
        ],
      );
    } else {
      // Left (peer message)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isFirstMessageUser(index, document.get('content'), listMessage, id)
              ? const SizedBox(height: 10)
              : Container(),
          isFirstMessageUser(index, document.get('content'), listMessage, id)
              ? chatItemHeader(peerName, peerImage, document, context)
              : Container(),
          showChatItemBasedOnType(document, context, peerName),
        ],
      );
    }
  }

  Widget buildListMessage() {
    // The scrollable list of all messages
    // Note that you can add a limit to the messages fetched at a time
    // to reduce the number of documents read
    return Expanded(
      child: groupChatId == ''
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Messages')
                  .doc(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  listMessage = snapshot.data!.docs;
                  chatStore.chatMessages = [];
                  for (int i = listMessage.length - 1; i >= 0; i--) {
                    chatStore.addChatMessages(listMessage[i].get('content'),
                       listMessage[i].get('idFrom'));
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) =>
                          buildItem(index, (snapshot.data?.docs)![index]),
                      itemCount: snapshot.data?.docs.length,
                      reverse: true,
                      controller: listScrollController,
                    ),
                  );
                }
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // user intro
        const ChatWindowUser(),
        const Divider(),
        // add chat stuff here
        buildListMessage(),
        const ChatInput(),
      ],
    );
  }
}
