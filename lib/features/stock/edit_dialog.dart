import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/article.dart';
import '../../models/enums.dart';

/// Form dialog for the few editable fields of an article.
/// Editing never happens inside the table itself.
class EditArticleDialog extends StatefulWidget {
  const EditArticleDialog({super.key, required this.article});
  final Article article;

  static Future<bool?> show(BuildContext context, Article article) {
    return showDialog<bool>(
      context: context,
      builder: (_) => EditArticleDialog(article: article),
    );
  }

  @override
  State<EditArticleDialog> createState() => _EditArticleDialogState();
}

class _EditArticleDialogState extends State<EditArticleDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _making;
  late final TextEditingController _stoneCharges;
  late final TextEditingController _tagPrice;
  late ArticleStatus _status;

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    _description = TextEditingController(text: a.description);
    _making = TextEditingController(text: a.makingCharges.toString());
    _stoneCharges = TextEditingController(text: a.stoneCharges.toString());
    _tagPrice = TextEditingController(text: a.tagPrice.toString());
    _status = a.status;
  }

  @override
  void dispose() {
    _description.dispose();
    _making.dispose();
    _stoneCharges.dispose();
    _tagPrice.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppStore>().updateArticle(
          widget.article,
          description: _description.text.trim(),
          makingCharges: int.parse(_making.text),
          stoneCharges: int.parse(_stoneCharges.text),
          tagPrice: int.parse(_tagPrice.text),
          status: _status,
        );
    Navigator.of(context).pop(true);
  }

  Widget _moneyField(String label, TextEditingController controller, {bool positive = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, prefixText: 'PKR  '),
      validator: (String? value) {
        final n = int.tryParse(value ?? '');
        if (n == null) return 'Enter a whole number';
        if (positive && n <= 0) return 'Must be greater than 0';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.article.articleCode}'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (String? value) =>
                    (value ?? '').trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _moneyField('Making Charges', _making)),
                  const SizedBox(width: 12),
                  Expanded(child: _moneyField('Stone Charges', _stoneCharges)),
                ],
              ),
              const SizedBox(height: 14),
              _moneyField('Tag Price', _tagPrice, positive: true),
              const SizedBox(height: 14),
              DropdownButtonFormField<ArticleStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: <DropdownMenuItem<ArticleStatus>>[
                  for (final s in ArticleStatus.values)
                    DropdownMenuItem<ArticleStatus>(value: s, child: Text(s.label)),
                ],
                onChanged: (ArticleStatus? value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
