import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../authentication/widgets/auth_text_field.dart';
import '../../products/models/product_model.dart';
import 'product_form_field.dart';
import 'transaction_type_selector.dart';

class TransactionDetailsSection extends StatelessWidget {
  final TransactionType selectedTransactionType;
  final TextEditingController priceController;
  final String selectedSwapCategory;
  final Function(TransactionType) onTypeChanged;
  final Function(String?) onSwapCategoryChanged;

  const TransactionDetailsSection({
    super.key,
    required this.selectedTransactionType,
    required this.priceController,
    required this.selectedSwapCategory,
    required this.onTypeChanged,
    required this.onSwapCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionTypeSelector(
          selectedType: selectedTransactionType,
          onChanged: onTypeChanged,
        ),
        if (selectedTransactionType == TransactionType.sell) ...[
          SizedBox(height: 24.h),
          AuthTextField(
            label: 'Price',
            hint: 'Enter price (e.g., 100)',
            controller: priceController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (selectedTransactionType == TransactionType.sell) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
              }
              return null;
            },
          ),
        ],
        if (selectedTransactionType == TransactionType.barter) ...[
          SizedBox(height: 24.h),
          ProductCategoryDropdown(
            label: 'Desired Swap Category',
            hint: 'What category do you want to swap with?',
            value: selectedSwapCategory,
            onChanged: onSwapCategoryChanged,
          ),
        ],
      ],
    );
  }
}
