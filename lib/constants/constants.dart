import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String fireStoreCollectionName = "InOutBoard";

const appBarColor=Colors.pink;

const double appFontSize = 20;
const nameStyle = TextStyle(decoration: TextDecoration.none, fontSize: appFontSize, fontWeight: FontWeight.normal);
const errorNameStyle = TextStyle(
    color: Colors.red,
    decoration: TextDecoration.none,
    fontSize: appFontSize,
    fontWeight: FontWeight.bold);

const textFormFieldStandardDecoration = InputDecoration(
  contentPadding: EdgeInsets.all(16),
  floatingLabelBehavior: FloatingLabelBehavior.auto,
  constraints: BoxConstraints(maxWidth: 150),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.grey,
        width: 2.0,
      )),
  errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.red,
        width: 2.0,
      )),
  focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.grey,
        width: 2.0,
      )),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.blue,
        width: 2.0,
      )),
  disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.grey,
        width: 2.0,
      )),
);

class LowerCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

extension StringExtensions on String {
  bool isValidEmail() {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$'
    ).hasMatch(this);
  }

  bool isWhiteSpace() => trim().isEmpty;

  bool isValidDouble() => double.tryParse(this) != null;

  bool isValidInt()    =>    int.tryParse(this) != null;

  bool isValidName()  {
    return RegExp('^[A-Z][a-z]*[A-Z]?[a-z]*\\s[A-Z][a-z]*[A-Z]?[a-z]*\$').hasMatch(this);
  }
}