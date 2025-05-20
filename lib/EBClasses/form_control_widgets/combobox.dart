import 'package:flutter/material.dart';

class ComboBox extends StatefulWidget {
  //ComboBox({Key key}) : super(key: key);
  const ComboBox(this.x, this.y, this.options, this.value, this.onChange,
      {super.key});
  final double? x;
  final double? y;
  final List<String> options;
  final String? value;
  final Function onChange;

  @override
  _ComboBoxState createState() => _ComboBoxState();
}

class _ComboBoxState extends State<ComboBox> {
  List<DropdownMenuItem<String>>? _dropDownMenuItems;
  String? _currentOption;

  @override
  void initState() {
    _dropDownMenuItems = getDropDownMenuItems();
    _currentOption = widget.value;
    super.initState();
  }

  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    final items = <DropdownMenuItem<String>>[];
    for (var option in widget.options) {
      items.add(DropdownMenuItem(
          value: option,
          child: Text(option,
              style: TextStyle(
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ))));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: widget.x! * 72, top: widget.y! * 72),
        child: DropdownButton(
            isExpanded: true,
            underline: SizedBox(),
            dropdownColor: Colors.white,
            value: _currentOption,
            items: _dropDownMenuItems,
            onChanged: (dynamic value) {
              setState(() {
                _currentOption = value;
              });
              widget.onChange(value);
            } //changedDropDownItem,
            ));
  }

  void changedDropDownItem(String selectedOption) {
    setState(() {
      _currentOption = selectedOption;
    });
  }
}
