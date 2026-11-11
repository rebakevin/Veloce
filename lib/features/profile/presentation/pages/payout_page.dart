import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/profile_bloc.dart';
import '../widgets/action_message_banner.dart';
import '../widgets/profile_action_listener.dart';
import '../widgets/profile_loaded_builder.dart';

/// `/profile/payout`: the owner's MTN MoMo number.
class PayoutPage extends StatelessWidget {
  const PayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment method')),
      body: ProfileActionListener(
        kind: ProfileActionKind.payout,
        successMessage: 'Payment method saved',
        child: ProfileLoadedBuilder(
          builder: (context, state) => _PayoutForm(state: state),
        ),
      ),
    );
  }
}

class _PayoutForm extends StatefulWidget {
  const _PayoutForm({required this.state});

  final ProfileLoaded state;

  @override
  State<_PayoutForm> createState() => _PayoutFormState();
}

class _PayoutFormState extends State<_PayoutForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.state.payout?.momoNumber);
    context.read<ProfileBloc>().add(const ProfileActionAcknowledged());
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(
      ProfilePayoutSubmitted(_number.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.state.payout?.momoNumber;
    final action = widget.state.action;
    return Form(
      key: _formKey,
      child: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
        children: [
          Text(
            current == null
                ? 'Add the MTN MoMo number where you receive your earnings.'
                : 'Current MoMo number: 0$current',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'MoMo number (the 9 digits after 0)',
            hint: '788123456',
            controller: _number,
            keyboardType: TextInputType.number,
            validator: Validators.momoNumber,
          ),
          const SizedBox(height: AppSpacing.lg),
          ActionMessageBanner(action: action, kind: ProfileActionKind.payout),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: current == null ? 'Save number' : 'Replace number',
            isLoading: action.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
