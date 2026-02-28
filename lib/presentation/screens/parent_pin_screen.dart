import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../domain/services/parent_pin_service.dart';
import '../widgets/themed_background_scaffold.dart';
import 'parent_dashboard_screen.dart';

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

    final pinService = getIt<ParentPinService>();
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

    final pinService = getIt<ParentPinService>();
    final pin = _pinController.text.trim();

    if (pin.length < 4) {
      setState(() => _error = 'PIN måste vara minst 4 siffror');
      return;
    }

    if (_isSettingNewPin) {
      final confirm = _confirmController.text.trim();
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      );
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

  @override
  Widget build(BuildContext context) {
    final isLockedOut = _lockoutMinutes != null && _lockoutMinutes! > 0;
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);
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
              color: onPrimary.withValues(alpha: 0.1),
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
                    fillColor: onPrimary.withValues(alpha: 0.08),
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
                      fillColor: onPrimary.withValues(alpha: 0.08),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
