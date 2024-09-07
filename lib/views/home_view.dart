import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchases/extensions/string_extension.dart';
import 'package:in_app_purchases/models/account.dart';
import 'package:in_app_purchases/models/question.dart';
import 'package:in_app_purchases/services/auth_service.dart';
import 'package:in_app_purchases/views/history_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';

enum AppStatus { ready, waiting }

class HomeView extends StatefulWidget {
  final Account account;
  const HomeView({
    super.key,
    required this.account,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _answer = '';
  bool askButtonActive = false;
  final Question _question = Question();
  AppStatus? _appStatus;
  int tillnextFree = 0;
  final TextEditingController _questionController = TextEditingController();
  final CountdownController _countDownController = CountdownController();

  @override
  void initState() {
    super.initState();
    tillnextFree = widget.account.nextFreeQuestion
            ?.difference((DateTime.now()))
            .inSeconds ??
        0;

    _getFreeDecision(widget.account.bank, tillnextFree);
  }

  @override
  Widget build(BuildContext context) {
    _setAppStatus();
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text(
            "Decider",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HistoryView(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Decisions Left: ${widget.account.bank}"),
                ),
                nextFreeQuestionCountDown(),
                const Spacer(),
                _buildQuestionForm(),
                const Spacer(
                  flex: 3,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Account Type : Free"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "${context.read<AuthService>().currentUser?.uid}",
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionForm() {
    if (_appStatus == AppStatus.ready) {
      return Column(
        children: [
          const Text(
            "Should I",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 10.0, left: 30.0, right: 30.0),
            child: TextField(
              decoration: const InputDecoration(
                helperText: "Enter Question",
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              controller: _questionController,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  askButtonActive = true;
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: askButtonActive ? _answerQuestion : null,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Ask"),
          ),
          _questionAndAnswer(),
        ],
      );
    } else {
      return _questionAndAnswer();
    }
  }

  void _setAppStatus() {
    if (widget.account.bank > 0) {
      setState(() {
        _appStatus = AppStatus.ready;
      });
    } else {
      setState(() {
        _appStatus = AppStatus.waiting;
      });
    }
  }

  String _getAnswer() {
    var answerOptions = ['yes', "no", "definitely", "not right now"];
    return answerOptions[Random().nextInt(answerOptions.length)];
  }

  Widget _questionAndAnswer() {
    if (_answer.isNotEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Should I ${_questionController.text}?",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Asnwer : ${_answer.capitalize()}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  void _answerQuestion() async {
    setState(() {
      _answer = _getAnswer();
      askButtonActive = false;
    });

    _question.query = _questionController.text;
    _question.answer = _answer;
    _question.created = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(context.read<AuthService>().currentUser?.uid)
        .collection('question')
        .add(_question.toJson());

    widget.account.bank -= 1;
    widget.account.nextFreeQuestion = DateTime.now().add(
      const Duration(seconds: 25),
    );

    setState(() {
      tillnextFree = widget.account.nextFreeQuestion
              ?.difference((DateTime.now()))
              .inSeconds ??
          0;
      if (widget.account.bank == 0) {
        _appStatus = AppStatus.waiting;
      }
    });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(context.read<AuthService>().currentUser?.uid)
        .update(widget.account.toJson());
    _questionController.text = '';
    _answer = '';
  }

  Widget nextFreeQuestionCountDown() {
    if (_appStatus == AppStatus.waiting) {
      _countDownController.start();
      var format = NumberFormat("00", "en_US");
      return Column(
        children: [
          const Text("You will get one free decision in"),
          Countdown(
            controller: _countDownController,
            seconds: tillnextFree,
            build: (BuildContext context, double time) => Text(
                "${format.format(time ~/ 3600)}:${format.format((time % 3600) ~/ 60)}:${format.format(time.toInt() % 60)} "),
            interval: const Duration(seconds: 1),
            onFinished: () {
              _getFreeDecision(widget.account.bank, 0);
              setState(() {
                tillnextFree = 0;
                _appStatus = AppStatus.ready;
              });
            },
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  void _getFreeDecision(currentBank, time) {
    if (currentBank <= 0 && time <= 0) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(context.read<AuthService>().currentUser?.uid)
          .update({'bank': 1});
    }
  }
}
