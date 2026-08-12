import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Autocomplete with controller AND focusNode builds cleanly',
      (tester) async {
    final nameController = TextEditingController(text: 'Medicine A');
    final nameFocusNode = FocusNode();
    addTearDown(() {
      nameController.dispose();
      nameFocusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Autocomplete<String>(
            textEditingController: nameController,
            focusNode: nameFocusNode,
            displayStringForOption: (o) => o,
            optionsBuilder: (t) =>
                t.text.trim().isEmpty ? const Iterable<String>.empty() : const ['Medicine A'],
            onSelected: (_) {},
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => onFieldSubmitted(),
              );
            },
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}
