import 'package:flutter/material.dart';

class SearchableDropdownFormField extends StatelessWidget {
  const SearchableDropdownFormField({
    super.key,
    required this.options,
    required this.decoration,
    this.optionLabels = const {},
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.searchHint = 'Type to filter options',
  });

  final List<String> options;
  final InputDecoration decoration;
  final Map<String, String> optionLabels;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final String searchHint;

  Future<String?> _selectOption(
    BuildContext context,
    String? selectedValue,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = controller.text.trim().toLowerCase();
          final filtered = options
              .where(
                (option) =>
                    '${optionLabels[option] ?? option} $option'
                        .toLowerCase()
                        .contains(query),
              )
              .toList(growable: false);
          return AlertDialog(
            title: Text(decoration.labelText ?? 'Select an option'),
            content: SizedBox(
              width: 420,
              height: 360,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No matching options.'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              return ListTile(
                                dense: true,
                                selected: option == selectedValue,
                                title: Text(optionLabels[option] ?? option),
                                trailing: option == selectedValue
                                    ? const Icon(Icons.check, size: 18)
                                    : null,
                                onTap: () =>
                                    Navigator.of(dialogContext).pop(option),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: initialValue,
    validator: validator,
    builder: (field) {
      final selectedValue = field.value;
      final currentValue = selectedValue ?? '';
      return InkWell(
        onTap: enabled
            ? () async {
                final value = await _selectOption(context, selectedValue);
                if (value == null) return;
                field.didChange(value);
                onChanged?.call(value);
              }
            : null,
        child: InputDecorator(
          decoration: decoration.copyWith(errorText: field.errorText),
          isEmpty: selectedValue == null || selectedValue.isEmpty,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedValue?.isNotEmpty == true
                      ? optionLabels[currentValue] ?? currentValue
                      : decoration.hintText ?? 'Select an option',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: selectedValue?.isNotEmpty == true
                      ? null
                      : TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      );
    },
  );
}
