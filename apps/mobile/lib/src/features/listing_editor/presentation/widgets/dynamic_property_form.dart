import 'package:flutter/material.dart';
import '../../domain/property_type_config.dart';

/// Titled card used to group form fields into a section.
class PropertySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const PropertySection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A single config-driven field: number / text / dropdown / boolean.
class PropertyField extends StatelessWidget {
  final FieldDef def;
  final TextEditingController? controller;
  final dynamic value;
  final String? error;
  final ValueChanged<String?>? onValueChanged;

  const PropertyField({
    super.key,
    required this.def,
    this.controller,
    this.value,
    this.error,
    this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (def.type) {
      case FieldType.boolean:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(def.label, style: Theme.of(context).textTheme.bodyLarge)),
              Switch(
                value: value == true,
                onChanged: (v) => onValueChanged?.call(v ? 'true' : 'false'),
              ),
            ],
          ),
        );
      case FieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: value != null && (def.options ?? []).contains(value) ? value as String : null,
            decoration: InputDecoration(
              labelText: def.label,
              errorText: error,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: (def.options ?? [])
                .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: onValueChanged,
          ),
        );
      case FieldType.number:
      case FieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            maxLines: def.maxLines,
            keyboardType: def.type == FieldType.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: def.label,
              hintText: def.unit != null ? 'in ${def.unit}' : null,
              suffixText: def.unit,
              errorText: error,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        );
      case FieldType.amenities:
        return const SizedBox.shrink();
    }
  }
}

/// Renders a property type's field config. Values are kept by the parent
/// (values map + controllers), so nothing is lost between steps or rebuilds.
class DynamicPropertyForm extends StatelessWidget {
  final List<FieldDef> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;
  final Map<String, String> errors;
  final void Function(String key, dynamic value) onValueChanged;
  final List<String> selectedAmenities;
  final void Function(String amenity, bool selected) onToggleAmenity;
  final bool showAmenities;

  const DynamicPropertyForm({
    super.key,
    required this.fields,
    required this.controllers,
    required this.values,
    required this.errors,
    required this.onValueChanged,
    required this.selectedAmenities,
    required this.onToggleAmenity,
    this.showAmenities = true,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (final f in fields) {
      if (f.type == FieldType.amenities) {
        if (!showAmenities) continue;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: availableAmenities.map((a) {
              final sel = selectedAmenities.contains(a);
              return FilterChip(
                label: Text(a),
                selected: sel,
                onSelected: (v) => onToggleAmenity(a, v),
              );
            }).toList(),
          ),
        ));
        continue;
      }
      widgets.add(PropertyField(
        def: f,
        controller: f.type == FieldType.number || f.type == FieldType.text
            ? controllers[f.key]
            : null,
        value: values[f.key],
        error: errors[f.key],
        onValueChanged: (v) => onValueChanged(f.key, v),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
