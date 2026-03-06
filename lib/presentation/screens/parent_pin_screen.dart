import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

      // Avoid focus/IME transitions overlapping with dialog + navigation.
      FocusManager.instance.primaryFocus?.unfocus();
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;

      // Set up security question for PIN recovery.
      final completed = await _showRecoverySetupDialog(context, pinService);
      if (!mounted) return;
      if (completed != null) {
        FocusManager.instance.primaryFocus?.unfocus();
        await _waitForKeyboardToClose(context);
        await Future<void>.delayed(kThemeAnimationDuration);
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        );
      }
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

  Future<void> _waitForKeyboardToClose(BuildContext context) async {
    // On real devices the IME/selection overlays can update for a few frames
    // after unfocus/pop. Navigating during that window has caused OverlayEntry
    // GlobalKey asserts in release builds.
    for (var i = 0; i < 20; i++) {
      if (!context.mounted) return;
      final viewInsets = MediaQuery.of(context).viewInsets;
      if (viewInsets.bottom <= 0) return;
      FocusManager.instance.primaryFocus?.unfocus();
      await SchedulerBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<bool?> _showRecoverySetupDialog(
    BuildContext context,
    ParentPinService pinService,
  ) async {
    final answerController = TextEditingController();
    var selectedQuestion = defaultSecurityQuestions.first;
    String? answerErrorText;
    var isLoading = false;
    Future<void> popSafely(BuildContext ctx, bool result) async {
      FocusScope.of(ctx).unfocus();
      await SchedulerBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await SchedulerBinding.instance.endOfFrame;
      if (!ctx.mounted) return;
      Navigator.of(ctx, rootNavigator: true).pop(result);
    }

    try {
      return await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            final scheme = Theme.of(ctx).colorScheme;
            final onPrimary = scheme.onPrimary;
            final mutedOnPrimary =
                onPrimary.withValues(alpha: AppOpacities.mutedText);
            final subtleOnPrimary =
                onPrimary.withValues(alpha: AppOpacities.subtleText);

            return AlertDialog(
              title: Text(
                'Sätt säkerhetsfråga',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Om du glömmer PIN kan du återställa den genom att svara på en säkerhetsfråga.',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: mutedOnPrimary,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Säkerhetsfråga',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: mutedOnPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: selectedQuestion,
                      onChanged: (value) {
                        if (isLoading || value == null) return;
                        setDialogState(() => selectedQuestion = value);
                      },
                      child: Column(
                        children: [
                          for (final q in defaultSecurityQuestions)
                            RadioListTile<String>(
                              value: q,
                              activeColor: scheme.secondary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                q,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerController,
                      enabled: !isLoading,
                      obscureText: true,
                      enableInteractiveSelection: false,
                      style: TextStyle(color: onPrimary),
                      decoration: InputDecoration(
                        labelText: 'Svar',
                        helperText: 'Skiftläge spelar ingen roll.',
                        labelStyle: TextStyle(color: mutedOnPrimary),
                        helperStyle: TextStyle(color: subtleOnPrimary),
                        filled: true,
                        fillColor: onPrimary.withValues(
                          alpha: AppOpacities.subtleFill,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                          borderSide: BorderSide(
                            color: onPrimary.withValues(
                              alpha: AppOpacities.borderSubtle,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                          borderSide: BorderSide(color: scheme.secondary),
                        ),
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
                              final messenger = ScaffoldMessenger.of(ctx);

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

                              final answer =
                                  InputValidators.sanitizeSecurityAnswer(
                                answerController.text,
                              );

                              setDialogState(() => isLoading = true);
                              try {
                                await pinService.setupPinRecovery(
                                  securityQuestion: selectedQuestion,
                                  securityAnswer: answer,
                                );

                                if (!ctx.mounted) return;
                                await popSafely(ctx, true);
                              } catch (e) {
                                if (!ctx.mounted) return;
                                setDialogState(() => isLoading = false);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Fel: $e')),
                                );
                              }
                            },
                      child: Text(
                        isLoading ? 'Sparar…' : 'Spara säkerhetsfråga',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              color: onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              await popSafely(ctx, false);
                            },
                      child: Text(
                        'Hoppa över',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              color: onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      // Give the dialog transition/IME a moment to settle before disposing.
      await Future<void>.delayed(kThemeAnimationDuration);
      answerController.dispose();
    }
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewInsets = MediaQuery.of(context).viewInsets;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppConstants.defaultPadding,
              AppConstants.defaultPadding,
              AppConstants.defaultPadding,
              AppConstants.defaultPadding + viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color:
                          onPrimary.withValues(alpha: AppOpacities.panelFill),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color:
                                    isLockedOut ? errorColor : mutedOnPrimary,
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
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius,
                              ),
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
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            _error!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
