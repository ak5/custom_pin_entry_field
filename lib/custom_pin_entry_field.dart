library custom_pin_entry_field;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomPinEntryField extends StatefulWidget {
  final String? lastPin;
  final int fields;
  final onSubmit;
  final double fieldWidth;
  final textStyle;
  final isTextObscure;
  final showFieldAsBox;
  final InputDecoration? decoration;
  final bool showCursor;
  final TextInputType keyboard;

  CustomPinEntryField(
      {this.lastPin,
      this.decoration,
      this.fields = 4,
      required this.onSubmit,
      this.fieldWidth = 40.0,
      this.textStyle = const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xff393e58),
        fontSize: 18.0,
      ),
      this.showCursor = false,
      this.isTextObscure = false,
      this.showFieldAsBox = false,
      this.keyboard = TextInputType.number})
      : assert(fields > 0);

  @override
  State createState() {
    return CustomPinEntryFieldState();
  }
}

class CustomPinEntryFieldState extends State<CustomPinEntryField> {
  late List<String?> _pin;
  late List<FocusNode?> _focusNodes;
  late List<TextEditingController?> _textControllers;

  Widget otpFields = Container();

  @override
  void initState() {
    super.initState();
    _pin = List<String?>.filled(widget.fields, null, growable: true);
    _focusNodes = List<FocusNode?>.filled(widget.fields, null, growable: true);
    _textControllers = List<TextEditingController?>.filled(widget.fields, null,
        growable: true);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        if (widget.lastPin != null) {
          for (var i = 0; i < widget.lastPin!.length; i++) {
            _pin[i] = widget.lastPin![i];
          }
        }
        otpFields = generateTextFields(context);
      });
    });
  }

  @override
  void dispose() {
    _textControllers.forEach((TextEditingController? t) => t!.dispose());
    super.dispose();
  }

  Widget generateTextFields(BuildContext context) {
    List<Widget> textFields = List.generate(widget.fields, (int i) {
      return buildTextField(i, context);
    });

    if (_pin.first != null) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        verticalDirection: VerticalDirection.down,
        children: textFields);
  }

  void clearTextFields() {
    _textControllers.forEach(
        (TextEditingController? tEditController) => tEditController!.clear());
    _pin.clear();
  }

  void _setField(int i, String value) {
    _textControllers[i]!.text = value;
    _pin[i] = value.isEmpty ? '' : value[0];
  }

  void _unsetField(int i) => _setField(i, '');

  void _submit() {
    if (_pin.every((String? digit) => digit != null && digit != '')) {
      _focusNodes.forEach((n) => n!.unfocus());
      widget.onSubmit(_pin.join());
    }
  }

  Widget buildTextField(int i, BuildContext context) {
    if (_focusNodes[i] == null) {
      _focusNodes[i] =
          FocusNode(onKeyEvent: (FocusNode focusNode, KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.backspace &&
            event is KeyDownEvent) {
          if (_textControllers[i]!.text.isEmpty) {
            if (i > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
              _unsetField(i - 1);
            }
          } else
            _unsetField(i);
        }
        return KeyEventResult.ignored;
      });
    }

    if (_textControllers[i] == null) {
      _textControllers[i] = TextEditingController();
      if (widget.lastPin != null) {
        _textControllers[i]!.text = widget.lastPin![i];
      }
    }

    _textControllers[i]!.addListener(() {
      // move focus to next field
      if (_textControllers[i]!.text.length > 0 && i + 1 < widget.fields) {
        FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
      }
      // handle paste/multichar input
      if (_textControllers[i]!.text.length > 1) {
        String rest = _textControllers[i]!.text.substring(1);
        _setField(i, _textControllers[i]!.text[0]);
        if (i < widget.fields) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
          if (rest.isNotEmpty) {
            _setField(i + 1, rest);
          }
        }
      }
    });

    _focusNodes[i]!.addListener(() {
      // when selecting a field, erase it
      if (_focusNodes[i]!.hasFocus) _unsetField(i);
    });

    return Container(
      height: widget.fieldWidth,
      width: widget.fieldWidth,
      margin: EdgeInsets.only(right: 10.0),
      child: TextField(
        maxLength: i + 1 == widget.fields ? 1 : null,
        autofocus: true,
        showCursor: widget.showCursor,
        controller: _textControllers[i],
        keyboardType: widget.keyboard,
        textAlign: TextAlign.center,
        style: widget.textStyle,
        focusNode: _focusNodes[i],
        obscureText: widget.isTextObscure,
        decoration: widget.decoration ??
            InputDecoration(
              counterText: "",
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Color(0xfff9ab65),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Color(0xffececec),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Color(0xffececec),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Color(0xffececec),
                ),
              ),
            ),
        onChanged: (String str) {
          _pin[i] = str;
          _submit();
        },
        onSubmitted: (String str) => _submit(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return otpFields;
  }
}
