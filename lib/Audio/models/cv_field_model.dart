class CVField {
  final String key;
  final String label;
  String? value;
  final String fieldType;
  final bool isRequired;
  final int order;

  CVField({
    required this.key,
    required this.label,
    this.value,
    this.fieldType = "text",
    this.isRequired = false,
    this.order = 0,
  });

  factory CVField.fromJson(Map<String, dynamic> json) => CVField(
    key: json['key'],
    label: json['label'],
    value: json['value'],
    fieldType: json['fieldType'] ?? 'text',
    isRequired: json['isRequired'] ?? false,
    order: json['order'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'value': value,
    'fieldType': fieldType,
    'isRequired': isRequired,
    'order': order,
  };
}
