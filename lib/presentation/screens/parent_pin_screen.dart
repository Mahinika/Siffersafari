import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/parent_pin_service_provider.dart';
import '../../core/utils/input_validators.dart';
import '../../domain/entities/pin_recovery_config.dart';
import '../../domain/services/parent_pin_service.dart';
import '../widgets/themed_background_scaffold.dart';
import 'parent_dashboard_screen.dart';
import 'pin_recovery_screen.dart';

class ParentPinScreen extends ConsumerStatefulWidget {
  const ParentPinScreen({
    super.key,
    this.forceSetNewPin = false,
  });

  /// If true, the screen always shows the "create new PIN" flow.
  /// Useful when changing PIN from within parent mode.
  final bool forceSetNewPin;

  @override
  ConsumerState<ParentPinScreen> createState() => _ParentPinScreenState();
}

class _ParentPinScreenState extends ConsumerState<ParentPinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _error;
  bool _isSettingNewPin = false;
  int? _lockoutMinutes;

  @override
  void initState() {
    super.initState();

    final pinService = ref.read(parentPinServiceProvider);
    _isSettingNewPin = widget.forceSetNewPin || !pinService.hasPinSet();
    _lockoutMinutes = pinService.getLockoutRemainingMinutes();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _lockoutMinutes = null;
    });

    final pinService = ref.read(parentPinServiceProvider);

    // Validate and sanitize PIN
    final pinError = InputValidators.validatePin(_pinController.text);
    if (pinError != null) {
      setState(() => _error = pinError);
      return;
    }

    final pin = InputValidators.sanitizePin(_pinController.text.trim());

    if (_isSettingNewPin) {
      final confirmError = InputValidators.validatePin(_confirmController.text);
      if (confirmError != null) {
        setState(() => _error = confirmError);
        return;
      }

      final confirm =
          InputValidators.sanitizePin(_confirmController.text.trim());
      if (confirm != pin) {
        setState(() => _error = 'PIN-koderna matchar inte');
        return;
      }

      try {
        await pinService.setPin(pin);
      } catch (e) {
        setState(() => _error = 'Kunde inte spara PIN: $e');
        return;
      }

      if (!mounted) return;

      // Show backup codes setup dialog
      _showBackupCodesDialog(context, pinService);
      return;
    }

    // Verify existing PIN
    try {
      final isCorrect = await pinService.verifyPin(pin);

      if (!isCorrect) {
        final remaining = pinService.getRemainingAttempts();
        setState(
          () => _error =
              remaining > 0 ? 'Fel PIN. $remaining försök kvar.' : 'Fel PIN.',
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      );
    } on PinLockoutException catch (e) {
      setState(() {
        _error = e.toString();
        _lockoutMinutes = e.remainingMinutes;
      });
    } catch (e) {
      setState(() => _error = 'Ett fel uppstod: $e');
    }
  }

  void _showBackupCodesDialog(
    BuildContext context,
    ParentPinService pinService,
  ) {
    final answerController = TextEditingController();
    var selectedQuestion = defaultSecurityQuestions.first;
    String? answerErrorText;
    var isLoading = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Spara backup-koder'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vi rekommenderar att du sparar backup-koder på en säker plats (t.ex. en anteckningsbok) för att kunna återställa PIN om du glömmer det.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedQuestion),
                  initialValue: selectedQuestion,
                  items: defaultSecurityQuestions
                      .map(
                        (q) => DropdownMenuItem<String>(
                          value: q,
                          child: Text(
                            q,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedQuestion = value;
                          });
                        },
                  decoration: const InputDecoration(
                    labelText: 'Säkerhetsfråga',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerController,
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Svar',
                    helperText: 'Skiftläge spelar ingen roll.',
                    errorText: answerErrorText,
                  ),
                  onChanged: (_) {
                    if (answerErrorText == null) return;
                    setDialogState(() => answerErrorText = null);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);

                          final validationError =
                              InputValidators.validateSecurityAnswer(
                            answerController.text,
                          );
                          if (validationError != null) {
                            setDialogState(
                              () => answerErrorText = validationError,
                            );
                            return;
                          }

                          final answer = InputValidators.sanitizeSecurityAnswer(
                            answerController.text,
                          );

                          setDialogState(() => isLoading = true);
                          try {
                            final codes = await pinService.setupPinRecovery(
                              securityQuestion: selectedQuestion,
                              securityAnswer: answer,
                            );

                            if (!ctx.mounted) return;
                            _showCodesForCopying(ctx, codes, pinService);
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setDialogState(() => isLoading = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Fel: $e')),
                            );
                          }
                        },
                  child: Text(
                    isLoading ? 'Skapar…' : 'Skapa backup-koder',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(ctx).pop(); // Dismiss this dialog
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const ParentDashboardScreen(),
                            ),
                          );
                        },
                  child: const Text('Hoppa över'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(answerController.dispose);
  }

  void _showCodesForCopying(
    BuildContext context,
    List<String> codes,
    ParentPinService pinService,
  ) {
    Navigator.of(context).pop(); // Dismiss previous dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Dina backup-koder'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Spara dessa koder på en säker plats:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: codes
                      .map(
                        (code) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SelectableText(
                            code,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const ParentDashboardScreen(),
                ),
              );
            },
            child: const Text('Klar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLockedOut = _lockoutMinutes != null && _lockoutMinutes! > 0;
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final errorColor = scheme.error;

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: Text(_isSettingNewPin ? 'Skapa PIN' : 'Ange PIN'),
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: AppOpacities.panelFill),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSettingNewPin
                      ? 'Välj en PIN-kod för föräldraläge'
                      : isLockedOut
                          ? 'För många felaktiga försök. Vänta $_lockoutMinutes minut${_lockoutMinutes! != 1 ? 'er' : ''}.'
                          : 'Skriv PIN-koden för att öppna föräldraläge',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isLockedOut ? errorColor : mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  enabled: !isLockedOut,
                  style: TextStyle(color: onPrimary),
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    labelStyle: TextStyle(color: mutedOnPrimary),
                    filled: true,
                    fillColor: onPrimary.withValues(
                      alpha: AppOpacities.subtleFill,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_isSettingNewPin) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextField(
                    controller: _confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: TextStyle(color: onPrimary),
                    decoration: InputDecoration(
                      labelText: 'Bekräfta PIN',
                      labelStyle: TextStyle(color: mutedOnPrimary),
                      filled: true,
                      fillColor: onPrimary.withValues(
                        alpha: AppOpacities.subtleFill,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: AppConstants.defaultPadding),
                ElevatedButton(
                  onPressed: isLockedOut ? null : _submit,
                  child: Text(
                    _isSettingNewPin ? 'Spara PIN' : 'Öppna',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (!_isSettingNewPin &&
                    ref
                        .read(parentPinServiceProvider)
                        .hasRecoveryConfigured()) ...[
                  const SizedBox(height: AppConstants.smallPadding),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PinRecoveryScreen(
                            onRecoveryComplete: () {
                              _pinController.clear();
                              _confirmController.clear();
                              setState(() => _error = null);
                            },
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Glömt PIN?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
