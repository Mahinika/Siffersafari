import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/parent_pin_service_provider.dart';
import '../../core/utils/input_validators.dart';
import '../../domain/services/parent_pin_service.dart';
import '../widgets/themed_background_scaffold.dart';

enum _RecoveryStep {
  questionInput,
  newPinInput,
  success,
}

class PinRecoveryScreen extends ConsumerStatefulWidget {
  const PinRecoveryScreen({super.key, required this.onRecoveryComplete});

  final VoidCallback onRecoveryComplete;

  @override
  ConsumerState<PinRecoveryScreen> createState() => _PinRecoveryScreenState();
}

class _PinRecoveryScreenState extends ConsumerState<PinRecoveryScreen> {
  late ParentPinService _pinService;
  _RecoveryStep _currentStep = _RecoveryStep.questionInput;

  String? _securityQuestion;
  final _answerController = TextEditingController();
  final _newPin1Controller = TextEditingController();
  final _newPin2Controller = TextEditingController();

  bool _showPin = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pinService = ref.read(parentPinServiceProvider);
    _securityQuestion = _pinService.getSecurityQuestion();

    if (_securityQuestion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showErrorDialog(
          'Ingen säkerhetsfråga är konfigurerad för denna profil.',
        );
      });
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _newPin1Controller.dispose();
    _newPin2Controller.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        final onPrimary = Theme.of(ctx).colorScheme.onPrimary;
        return AlertDialog(
          title: Text(
            'Fel',
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          content: Text(
            message,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: onPrimary),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (message.contains('Ingen säkerhetsfråga')) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifySecurityAnswer() async {
    final answerError =
        InputValidators.validateSecurityAnswer(_answerController.text);
    if (answerError != null) {
      setState(() => _errorMessage = answerError);
      return;
    }

    final answer =
        InputValidators.sanitizeSecurityAnswer(_answerController.text);

    setState(() => _isLoading = true);
    try {
      final isCorrect = await _pinService.verifySecurityAnswer(answer);
      if (!mounted) return;

      if (!isCorrect) {
        setState(() {
          _errorMessage = 'Felaktigt svar. Försök igen.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentStep = _RecoveryStep.newPinInput;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ett fel inträffade: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPin() async {
    final pin1Error = InputValidators.validatePin(_newPin1Controller.text);
    if (pin1Error != null) {
      setState(() => _errorMessage = pin1Error);
      return;
    }

    final pin2Error = InputValidators.validatePin(_newPin2Controller.text);
    if (pin2Error != null) {
      setState(() => _errorMessage = pin2Error);
      return;
    }

    final newPin1 = InputValidators.sanitizePin(_newPin1Controller.text.trim());
    final newPin2 = InputValidators.sanitizePin(_newPin2Controller.text.trim());

    if (newPin1 != newPin2) {
      setState(() => _errorMessage = 'PIN-koderna matchar inte');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _pinService.setPin(newPin1);

      if (!mounted) return;
      setState(() {
        _currentStep = _RecoveryStep.success;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ett fel inträffade: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: Text(
          'Återställ PIN',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        foregroundColor: onPrimary,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _securityQuestion == null
          ? Center(
              child: Text(
                'Ingen recovery-konfiguration',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: _buildCurrentStep(context),
            ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    return switch (_currentStep) {
      _RecoveryStep.questionInput => _buildQuestionStep(context),
      _RecoveryStep.newPinInput => _buildNewPinStep(context),
      _RecoveryStep.success => _buildSuccessStep(context),
    };
  }

  Widget _buildQuestionStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Säkerhetsfråga',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: onPrimary.withValues(alpha: AppOpacities.subtleFill),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
            ),
          ),
          child: Text(
            _securityQuestion!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _answerController,
          style: TextStyle(color: onPrimary),
          decoration: InputDecoration(
            labelText: 'Svar',
            hintText: 'Ange svar på säkerhetsfrågan',
            labelStyle: TextStyle(color: mutedOnPrimary),
            hintStyle: TextStyle(color: subtleOnPrimary),
            filled: true,
            fillColor: onPrimary.withValues(alpha: AppOpacities.subtleFill),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.secondary),
            ),
            errorText: _errorMessage,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifySecurityAnswer,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Verifiera svar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPinStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Välj ny PIN',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _newPin1Controller,
          obscureText: !_showPin,
          keyboardType: TextInputType.number,
          style: TextStyle(color: onPrimary),
          decoration: InputDecoration(
            labelText: 'Ny PIN',
            labelStyle: TextStyle(color: mutedOnPrimary),
            filled: true,
            fillColor: onPrimary.withValues(alpha: AppOpacities.subtleFill),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.secondary),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPin ? Icons.visibility_off : Icons.visibility,
                color: mutedOnPrimary,
              ),
              onPressed: () {
                setState(() => _showPin = !_showPin);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPin2Controller,
          obscureText: !_showPin,
          keyboardType: TextInputType.number,
          style: TextStyle(color: onPrimary),
          decoration: InputDecoration(
            labelText: 'Bekräfta PIN',
            labelStyle: TextStyle(color: mutedOnPrimary),
            filled: true,
            fillColor: onPrimary.withValues(alpha: AppOpacities.subtleFill),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.secondary),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPin ? Icons.visibility_off : Icons.visibility,
                color: mutedOnPrimary,
              ),
              onPressed: () {
                setState(() => _showPin = !_showPin);
              },
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  scheme.error.withValues(alpha: AppOpacities.highlightStrong),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.error),
            ),
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = _RecoveryStep.questionInput;
                    _errorMessage = null;
                  });
                },
                child: Text(
                  'Tillbaka',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Spara ny PIN',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.check_circle,
          color: Colors.green.shade600,
          size: 64,
        ),
        const SizedBox(height: 24),
        Text(
          'PIN återställd!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Din PIN har uppdaterats. Du kan nu logga in i föräldraläget med den nya PIN-koden.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedOnPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onRecoveryComplete();
              Navigator.of(context).pop();
            },
            child: Text(
              'Stäng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
