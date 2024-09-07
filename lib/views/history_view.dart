import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchases/models/question.dart';
import 'package:in_app_purchases/services/auth_service.dart';
import 'package:in_app_purchases/views/helpers/question_card.dart';
import 'package:provider/provider.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<Object> _historyList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getUserQuestionList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          "Past Decisions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _historyList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  return QuestionCard(_historyList[index] as Question);
                },
              ),
      ),
    );
  }

  Future getUserQuestionList() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    var data = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection("question")
        .orderBy('created', descending: true)
        .get();

    setState(() {
      _historyList =
          List.from(data.docs.map((doc) => Question.fromSnapshot(doc)));
    });
  }
}
