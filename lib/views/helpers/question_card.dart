import 'package:flutter/material.dart';
import 'package:in_app_purchases/extensions/string_extension.dart';
import 'package:in_app_purchases/models/question.dart';
import 'package:intl/intl.dart';

class QuestionCard extends StatelessWidget {
  final Question _question;
  const QuestionCard(this._question, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      "Should I ${_question.query}?",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _question.answer!.capitalize(),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat("MM/dd/yyyy")
                        .format(_question.created!)
                        .toString(),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
