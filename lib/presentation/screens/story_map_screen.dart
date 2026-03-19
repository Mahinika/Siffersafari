import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/story_progress_provider.dart';
import '../../core/utils/adaptive_layout.dart';
import '../../domain/entities/story_progress.dart';
import '../widgets/themed_background_scaffold.dart';

class StoryMapScreen extends ConsumerWidget {
  const StoryMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(storyProgressProvider);
    final themeCfg = ref.watch(appThemeConfigProvider);
    final size = MediaQuery.sizeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);
    final layout = AdaptiveLayoutInfo.fromConstraints(
      BoxConstraints(maxWidth: size.width, maxHeight: size.height),
    );

    if (story == null) {
      return ThemedBackgroundScaffold(
        appBar: AppBar(
          title: const Text('Djungelkartan'),
        ),
        body: Center(
          child: Text(
            'Ingen karta finns an.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    final currentNode = story.currentNode;
    final nextNode = _nextNode(story);

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: const Text('Djungelkartan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: layout.isExpandedWidth ? 860 : 720,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MapHeroCard(
                  story: story,
                  heroAsset: themeCfg.questHeroAsset,
                  backgroundAsset: themeCfg.backgroundAsset,
                  accentColor: scheme.secondary,
                  onPrimary: onPrimary,
                  mutedOnPrimary: mutedOnPrimary,
                  subtleOnPrimary: subtleOnPrimary,
                ),
                const SizedBox(height: AppConstants.largePadding),
                _NowAndNextPanel(
                  story: story,
                  currentNode: currentNode,
                  nextNode: nextNode,
                  accentColor: scheme.secondary,
                  onPrimary: onPrimary,
                  mutedOnPrimary: mutedOnPrimary,
                  onContinue: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: AppConstants.largePadding),
                _NearbyStopsPanel(
                  story: story,
                  currentNode: currentNode,
                  nextNode: nextNode,
                  accentColor: scheme.secondary,
                  onPrimary: onPrimary,
                  mutedOnPrimary: mutedOnPrimary,
                  subtleOnPrimary: subtleOnPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  StoryNode? _nextNode(StoryProgress story) {
    final nextIndex = story.currentNodeIndex + 1;
    if (nextIndex < 0 || nextIndex >= story.nodes.length) {
      return null;
    }
    return story.nodes[nextIndex];
  }
}

class _MapHeroCard extends StatelessWidget {
  const _MapHeroCard({
    required this.story,
    required this.heroAsset,
    required this.backgroundAsset,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.subtleOnPrimary,
  });

  final StoryProgress story;
  final String heroAsset;
  final String backgroundAsset;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color subtleOnPrimary;

  @override
  Widget build(BuildContext context) {
    final overallProgress =
        story.totalNodes == 0 ? 0.0 : story.completedNodes / story.totalNodes;
    final chapterNumber = (story.currentNodeIndex ~/ 5) + 1;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            onPrimary.withValues(alpha: 0.16),
            onPrimary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: accentColor.withValues(alpha: AppOpacities.borderSubtle),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppOpacities.shadowAmbient),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    heroAsset,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        backgroundAsset,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      );
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.44),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppConstants.defaultPadding,
                    bottom: AppConstants.defaultPadding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.smallPadding,
                        vertical: AppConstants.microSpacing6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Folj stigen steg for steg',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            story.worldTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppConstants.microSpacing6),
          Text(
            'Du ser bara det viktigaste: var du ar och vart du ska nu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtleOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Wrap(
            spacing: AppConstants.smallPadding,
            runSpacing: AppConstants.smallPadding,
            children: [
              _HeaderChip(
                label: 'Klara stopp',
                value: '${story.completedNodes}/${story.totalNodes}',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _HeaderChip(
                label: 'Del just nu',
                value: '$chapterNumber',
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
              _HeaderChip(
                label: 'Nasta mattegrej',
                value: story.currentObjectiveTitle,
                onPrimary: onPrimary,
                mutedOnPrimary: mutedOnPrimary,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hur langt du har kommit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Text(
                '${(overallProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: AppConstants.progressBarHeightSmall,
              backgroundColor: onPrimary.withValues(
                alpha: AppOpacities.progressTrackLight,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.value,
    required this.onPrimary,
    required this.mutedOnPrimary,
  });

  final String label;
  final String value;
  final Color onPrimary;
  final Color mutedOnPrimary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        decoration: BoxDecoration(
          color: onPrimary.withValues(alpha: AppOpacities.subtleFill),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: onPrimary.withValues(alpha: AppOpacities.hudBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: mutedOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppConstants.microSpacing4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowAndNextPanel extends StatelessWidget {
  const _NowAndNextPanel({
    required this.story,
    required this.currentNode,
    required this.nextNode,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.onContinue,
  });

  final StoryProgress story;
  final StoryNode? currentNode;
  final StoryNode? nextNode;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth < 620;
        final actionBody = nextNode == null
            ? 'Ga tillbaka och spela sista stoppet pa stigen.'
            : 'Ga tillbaka och tryck pa Spela nasta stopp for att resa mot ${nextNode!.landmark}.';
        final currentCard = _FocusCard(
          label: 'Du ar har',
          title: currentNode?.landmark ?? 'Starten',
          body: 'Nu: ${story.currentObjectiveTitle}',
          icon: Icons.place_rounded,
          color: accentColor,
          onPrimary: onPrimary,
        );
        final nextCard = _FocusCard(
          label: nextNode == null ? 'Mallet ar nara' : 'Nasta stopp',
          title: nextNode?.landmark ?? 'Sista stoppet',
          body: nextNode == null
              ? 'Du ar snart framme vid slutet av stigen.'
              : 'Sedan: ${nextNode!.title}',
          icon: nextNode == null ? Icons.emoji_events : Icons.flag_rounded,
          color: nextNode == null
              ? const Color(0xFFD39A2F)
              : accentColor.withValues(alpha: 0.92),
          onPrimary: onPrimary,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vad hander nu?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppConstants.microSpacing6),
            Text(
              'Titta pa de tva stora rutorna for att se var du ar och vart du ska.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (useColumns) ...[
              currentCard,
              const SizedBox(height: AppConstants.defaultPadding),
              nextCard,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: currentCard),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(child: nextCard),
                ],
              ),
            const SizedBox(height: AppConstants.defaultPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: AppOpacities.subtleFill),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: onPrimary.withValues(alpha: AppOpacities.hudBorder),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      actionBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mutedOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Tillbaka och spela'),
            ),
          ],
        );
      },
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.label,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.onPrimary,
  });

  final String label;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.72), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: onPrimary),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppConstants.microSpacing4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppConstants.microSpacing6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onPrimary.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
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

class _NearbyStopsPanel extends StatelessWidget {
  const _NearbyStopsPanel({
    required this.story,
    required this.currentNode,
    required this.nextNode,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.subtleOnPrimary,
  });

  final StoryProgress story;
  final StoryNode? currentNode;
  final StoryNode? nextNode;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color subtleOnPrimary;

  @override
  Widget build(BuildContext context) {
    final visibleNodes = _selectVisibleNodes(
      story.nodes,
      currentIndex: story.currentNodeIndex,
      windowSize: 5,
    );

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            onPrimary.withValues(alpha: 0.15),
            onPrimary.withValues(alpha: 0.09),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Stigen nara dig',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppConstants.microSpacing6),
          Text(
            'Las uppifran och nedat. Gront ar klart, gult ar du, gratt kommer senare.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          for (final node in visibleNodes) ...[
            _StopCard(
              node: node,
              isCurrent: currentNode?.id == node.id,
              isNext: nextNode?.id == node.id,
              accentColor: accentColor,
              onPrimary: onPrimary,
              mutedOnPrimary: mutedOnPrimary,
              subtleOnPrimary: subtleOnPrimary,
            ),
            if (node != visibleNodes.last)
              const SizedBox(height: AppConstants.smallPadding),
          ],
        ],
      ),
    );
  }

  List<StoryNode> _selectVisibleNodes(
    List<StoryNode> nodes, {
    required int currentIndex,
    required int windowSize,
  }) {
    if (nodes.length <= windowSize) {
      return nodes;
    }

    final safeWindow = windowSize.clamp(3, nodes.length);
    final start = (currentIndex - 1).clamp(0, nodes.length - safeWindow);
    final end = (start + safeWindow).clamp(0, nodes.length);
    return nodes.sublist(start, end);
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.node,
    required this.isCurrent,
    required this.isNext,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.subtleOnPrimary,
  });

  final StoryNode node;
  final bool isCurrent;
  final bool isNext;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color subtleOnPrimary;

  @override
  Widget build(BuildContext context) {
    final visual = _NodeVisual.forSceneTag(
      node.sceneTag,
      accentColor: accentColor,
    );

    final statusLabel = switch (node.state) {
      StoryNodeState.completed => 'Klar',
      StoryNodeState.current => 'Du ar har',
      StoryNodeState.upcoming => isNext ? 'Nasta' : 'Senare',
    };

    final borderColor = switch (node.state) {
      StoryNodeState.completed => const Color(0xFF7AAE3E),
      StoryNodeState.current => const Color(0xFFD39A2F),
      StoryNodeState.upcoming => mutedOnPrimary.withValues(alpha: 0.55),
    };

    final fillColor = switch (node.state) {
      StoryNodeState.completed =>
        const Color(0xFF7AAE3E).withValues(alpha: 0.18),
      StoryNodeState.current => const Color(0xFFD39A2F).withValues(alpha: 0.18),
      StoryNodeState.upcoming => onPrimary.withValues(alpha: 0.08),
    };

    final body = switch (node.state) {
      StoryNodeState.completed => 'Du har redan klarat det har stoppet.',
      StoryNodeState.current => 'Nu spelar du: ${node.title}',
      StoryNodeState.upcoming => isNext
          ? 'Sedan kommer: ${node.title}'
          : 'Detta stopp kommer senare pa stigen.',
    };

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: isCurrent ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(visual.icon, color: onPrimary),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stopp ${node.stepIndex + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: mutedOnPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppConstants.microSpacing4),
                          Text(
                            node.landmark,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    _StatusChip(
                      label: statusLabel,
                      color: borderColor,
                      onPrimary: onPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onPrimary.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (isCurrent || isNext) ...[
                  const SizedBox(height: AppConstants.microSpacing6),
                  Text(
                    node.landmarkHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtleOnPrimary,
                          fontWeight: FontWeight.w600,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.onPrimary,
  });

  final String label;
  final Color color;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.microSpacing6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _NodeVisual {
  const _NodeVisual({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  factory _NodeVisual.forSceneTag(
    String sceneTag, {
    required Color accentColor,
  }) {
    switch (sceneTag) {
      case 'baslager':
        return const _NodeVisual(
          icon: Icons.cabin,
          color: Color(0xFF7A5A34),
        );
      case 'frukt':
        return const _NodeVisual(
          icon: Icons.apple,
          color: Color(0xFF7AAE3E),
        );
      case 'skugga':
        return const _NodeVisual(
          icon: Icons.dark_mode,
          color: Color(0xFF56607A),
        );
      case 'bro':
        return const _NodeVisual(
          icon: Icons.linear_scale,
          color: Color(0xFF8A6C45),
        );
      case 'karta':
        return const _NodeVisual(
          icon: Icons.map,
          color: Color(0xFF3A8E8A),
        );
      case 'fors':
        return const _NodeVisual(
          icon: Icons.water,
          color: Color(0xFF3A7BC1),
        );
      case 'tempel':
        return const _NodeVisual(
          icon: Icons.account_balance,
          color: Color(0xFF8B6F42),
        );
      case 'soltempel':
        return const _NodeVisual(
          icon: Icons.wb_sunny,
          color: Color(0xFFD39A2F),
        );
      case 'skog':
        return const _NodeVisual(
          icon: Icons.park,
          color: Color(0xFF4E8B52),
        );
      case 'trumma':
        return const _NodeVisual(
          icon: Icons.music_note,
          color: Color(0xFF8C5632),
        );
      case 'port':
        return const _NodeVisual(
          icon: Icons.door_front_door,
          color: Color(0xFF6D667C),
        );
      case 'skatt':
        return const _NodeVisual(
          icon: Icons.workspace_premium,
          color: Color(0xFFB88C2E),
        );
    }

    return _NodeVisual(
      icon: Icons.explore,
      color: accentColor,
    );
  }
}
