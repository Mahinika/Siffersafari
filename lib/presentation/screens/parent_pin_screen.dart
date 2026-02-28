import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/local_storage_repository.dart';
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
  static const _pinKey = 'parent_pin';

  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _error;
  bool _isSettingNewPin = false;

  @override
  void initState() {
    super.initState();

    final repo = getIt<LocalStorageRepository>();
    final existingPin = repo.getSetting(_pinKey) as String?;
    _isSettingNewPin =
        widget.forceSetNewPin || existingPin == null || existingPin.isEmpty;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final repo = getIt<LocalStorageRepository>();
    final existingPin = repo.getSetting(_pinKey) as String?;

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

      await repo.saveSetting(_pinKey, pin);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      );
      return;
    }

    if (existingPin != pin) {
      setState(() => _error = 'Fel PIN');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryActionColor = Theme.of(context).colorScheme.primary;
    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: Text(_isSettingNewPin ? 'Skapa PIN' : 'Ange PIN'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSettingNewPin
                      ? 'Välj en PIN-kod för föräldraläge'
                      : 'Skriv PIN-koden för att öppna föräldraläge',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Bekräfta PIN',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
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
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: AppConstants.defaultPadding),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: Text(
                    _isSettingNewPin ? 'Spara PIN' : 'Öppna',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
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
