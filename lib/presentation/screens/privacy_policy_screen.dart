import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../widgets/themed_background_scaffold.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeCfg = ref.watch(appThemeConfigProvider);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: const Text('Sekretesspolicy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Container(
          decoration: BoxDecoration(
            color: onPrimary.withValues(alpha: AppOpacities.panelFill),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sekretesspolicy – ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding / 2),
              Text(
                'Senast uppdaterad: 4 mars 2026',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtleOnPrimary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildSection(
                context,
                title: 'Översikt',
                content:
                    '${AppConstants.appName} är ett mattespel för barn 6–12 år. Vi samlar INTE in, använder eller delar någon personlig information från barn eller föräldrar. All speldata sparas lokalt på din enhet.',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Data vi samlar in',
                content:
                    'Vi samlar INTE in någon personlig information som:\n\n'
                    '❌ Barnets namn, e-post, adress eller telefonnummer\n'
                    '❌ Förälders kontaktinformation\n'
                    '❌ Foton, videor eller ljudinspelningar\n'
                    '❌ Platsdata (GPS, adress)\n'
                    '❌ Beständiga enhetsidentifierare',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Data vi sparar lokalt',
                content:
                    'Följande information sparas ENDAST på din enhet med krypterad lokal lagring:\n\n'
                    '• Barnets profilnamn\n'
                    '• Quiz-resultat och framsteg\n'
                    '• Upplåsta svårighetsnivåer\n'
                    '• Föräldra-PIN (hashad med BCrypt)\n'
                    '• Sessionshistorik\n\n'
                    'All data stannar på din enhet. Vi synkroniserar INTE data till våra servrar.',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Data vi INTE samlar in',
                content: '❌ Inga serveruppladdningar - barnets data lämnar aldrig enheten\n'
                    '❌ Ingen analys - vi använder inte Google Analytics, Firebase eller liknande\n'
                    '❌ Ingen reklam - appen innehåller inga annonser\n'
                    '❌ Ingen spårning - vi spårar inte ditt barn mellan appar eller webbplatser\n'
                    '❌ Ingen datadelning - vi delar data med inga externa företag',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Hur du kontrollerar din data',
                content:
                    'Radera en barnprofil:\n1. Öppna ${AppConstants.appName}\n2. Gå till Inställningar\n3. Välj barnets profil\n4. Tryck på "Radera profil"\n5. Bekräfta borttagning\n\n'
                    'Radera all data:\n1. Öppna ${AppConstants.appName}\n2. Gå till Inställningar\n3. Tryck på "Radera all data"\n4. Bekräfta borttagning\n\n'
                    'All data raderas permanent från enheten.',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Datasäkerhet',
                content: 'Din data skyddas av:\n\n'
                    '• Lokal kryptering - Föräldra-PIN hashas med BCrypt\n'
                    '• Enhetslagring - Data sparas i krypterad Hive-databas\n'
                    '• Ingen nätverksöverföring - ingen data lämnar enheten\n'
                    '• Inget konto-system - ingen risk för kontointrång',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Barns integritet (COPPA)',
                content:
                    '${AppConstants.appName} är designad för barn under 13 år. Vi följer COPPA genom att:\n\n'
                    '1. Samla in noll personlig information från barn eller föräldrar\n'
                    '2. Spara data endast lokalt (inga molnservrar)\n'
                    '3. Tillhandahålla enkel dataradering\n'
                    '4. Ingen spårning eller profilering mellan enheter',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Tredjepartstjänster',
                content:
                    'Vi använder följande open source-bibliotek, alla fungerar offline på din enhet:\n\n'
                    '• Hive (lokal databas)\n'
                    '• Riverpod (state management)\n'
                    '• Just Audio (ljuduppspelning)\n'
                    '• BCrypt (lösenordshashning)\n\n'
                    'Inget av dessa bibliotek samlar in data.',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _buildSection(
                context,
                title: 'Dina rättigheter',
                content:
                    'Som förälder/vårdnadshavare har du rätt att:\n\n'
                    '✅ Veta vilken data appen sparar\n'
                    '✅ Radera ditt barns profil och all associerad data när som helst\n'
                    '✅ Begära att vi förklarar våra datametoder\n'
                    '✅ Kontakta oss med integritetsfrågor',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: themeCfg.accentColor.withValues(
                    alpha: AppOpacities.highlightStrong,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius / 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: themeCfg.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sammanfattning',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '✅ COPPA-kompatibel: Appen samlar in noll personlig information\n'
                      '✅ GDPR-vänlig: Ingen databehandling\n'
                      '✅ Barnsäker: Designad för barn 6–12 år\n'
                      '✅ Transparent: Den här policyn förklarar allt vi gör (och inte gör)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: onPrimary,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required Color onPrimary,
    required Color mutedOnPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
