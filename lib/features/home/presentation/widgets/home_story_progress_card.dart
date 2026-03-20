import 'package:flutter/material.dart';

import 'package:siffersafari/core/constants/app_constants.dart';
import 'package:siffersafari/domain/entities/story_progress.dart';

class HomeStoryProgressCard extends StatelessWidget {
  const HomeStoryProgressCard({
    required this.story,
    required this.heroAsset,
    required this.backgroundAsset,
    required this.characterAsset,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.subtleOnPrimary,
    required this.faintOnPrimary,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.onStartQuest,
    this.onOpenMap,
    super.key,
  });

  final StoryProgress story;
  final String heroAsset;
  final String backgroundAsset;
  final String characterAsset;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color subtleOnPrimary;
  final Color faintOnPrimary;
  final int cacheWidth;
  final int cacheHeight;
  final VoidCallback onStartQuest;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final currentNode = story.currentNode;
    final nextNode = _nextNode();
    final visibleNodes = _selectVisibleNodes();
    final overallProgress =
        story.totalNodes == 0 ? 0.0 : story.completedNodes / story.totalNodes;
    final actionHint = nextNode == null
        ? 'Ett sista stopp ar kvar pa den här stigen.'
        : 'Tryck pa knappen sa hjalper du maskoten vidare till ${nextNode.landmark}.';

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.only(top: AppConstants.defaultPadding),
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
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroBanner(
              story: story,
              heroAsset: heroAsset,
              backgroundAsset: backgroundAsset,
              characterAsset: characterAsset,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              onPrimary: onPrimary,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              story.worldTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppConstants.microSpacing6),
            Text(
              'Vad händer nu?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppConstants.microSpacing4),
            Text(
              'Börja med knappen Spela nästa stopp när du är redo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subtleOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: [
                _InfoChip(
                  label: 'Klara stopp',
                  value: '${story.completedNodes}/${story.totalNodes}',
                  onPrimary: onPrimary,
                  mutedOnPrimary: mutedOnPrimary,
                ),
                _InfoChip(
                  label: 'Del just nu',
                  value: '${(story.currentNodeIndex ~/ 5) + 1}',
                  onPrimary: onPrimary,
                  mutedOnPrimary: mutedOnPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _FocusCards(
              currentTitle: currentNode?.landmark ?? 'Starten',
              currentBody: 'Nu: ${story.currentObjectiveTitle}',
              nextTitle: nextNode?.landmark ?? 'Målet är nära',
              nextBody: nextNode == null
                  ? 'Du är snart framme vid slutet av stigen.'
                  : 'Sedan: ${nextNode.title}',
              accentColor: accentColor,
              onPrimary: onPrimary,
            ),
            if (currentNode != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: AppOpacities.subtleFill),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: onPrimary.withValues(alpha: AppOpacities.hudBorder),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.forest, color: accentColor, size: 18),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        currentNode.landmarkHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: mutedOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppConstants.defaultPadding),
            _StoryPathPreview(
              nodes: visibleNodes,
              currentNodeId: currentNode?.id,
              nextNodeId: nextNode?.id,
              accentColor: accentColor,
              onPrimary: onPrimary,
              mutedOnPrimary: mutedOnPrimary,
              faintOnPrimary: faintOnPrimary,
            ),
            if (story.notice != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: AppOpacities.subtleFill),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Text(
                  story.notice!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hur långt du har kommit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtleOnPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  '${(overallProgress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedOnPrimary,
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
            const SizedBox(height: AppConstants.defaultPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
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
                    Icons.play_circle_outline_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      actionHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mutedOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: onStartQuest,
              child: const Text('Spela nästa stopp'),
            ),
            if (onOpenMap != null) ...[
              const SizedBox(height: AppConstants.smallPadding),
              OutlinedButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Öppna kartan'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  StoryNode? _nextNode() {
    final nextIndex = story.currentNodeIndex + 1;
    if (nextIndex < 0 || nextIndex >= story.nodes.length) {
      return null;
    }
    return story.nodes[nextIndex];
  }

  List<StoryNode> _selectVisibleNodes() {
    if (story.nodes.length <= 4) {
      return story.nodes;
    }

    final start = (story.currentNodeIndex - 1).clamp(0, story.nodes.length - 4);
    final end = (start + 4).clamp(0, story.nodes.length);
    return story.nodes.sublist(start, end);
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.story,
    required this.heroAsset,
    required this.backgroundAsset,
    required this.characterAsset,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.onPrimary,
  });

  final StoryProgress story;
  final String heroAsset;
  final String backgroundAsset;
  final String characterAsset;
  final int cacheWidth;
  final int cacheHeight;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: SizedBox(
        height: 126,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                heroAsset,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    backgroundAsset,
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                    excludeFromSemantics: true,
                  );
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppConstants.defaultPadding,
              top: AppConstants.defaultPadding,
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
                  story.chapterTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            Positioned(
              left: AppConstants.defaultPadding,
              right: 112,
              bottom: AppConstants.defaultPadding,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.smallPadding,
                  vertical: AppConstants.microSpacing6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Text(
                  story.currentNode?.landmark ?? 'Djungelstigen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  characterAsset,
                  height: 112,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
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

class _FocusCards extends StatelessWidget {
  const _FocusCards({
    required this.currentTitle,
    required this.currentBody,
    required this.nextTitle,
    required this.nextBody,
    required this.accentColor,
    required this.onPrimary,
  });

  final String currentTitle;
  final String currentBody;
  final String nextTitle;
  final String nextBody;
  final Color accentColor;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackCards = constraints.maxWidth < 620;
        final currentCard = _FocusCard(
          label: 'Du är här',
          title: currentTitle,
          body: currentBody,
          icon: Icons.place_rounded,
          color: accentColor,
          onPrimary: onPrimary,
        );
        final nextCard = _FocusCard(
          label: 'Nasta stopp',
          title: nextTitle,
          body: nextBody,
          icon: Icons.flag_rounded,
          color: const Color(0xFFD39A2F),
          onPrimary: onPrimary,
        );

        if (stackCards) {
          return Column(
            children: [
              currentCard,
              const SizedBox(height: AppConstants.defaultPadding),
              nextCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: currentCard),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(child: nextCard),
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
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.72), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: onPrimary),
          ),
          const SizedBox(width: AppConstants.smallPadding),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppConstants.microSpacing4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _StoryPathPreview extends StatelessWidget {
  const _StoryPathPreview({
    required this.nodes,
    required this.currentNodeId,
    required this.nextNodeId,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.faintOnPrimary,
  });

  final List<StoryNode> nodes;
  final String? currentNodeId;
  final String? nextNodeId;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color faintOnPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Stigen nära dig',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            for (var i = 0; i < nodes.length; i++) ...[
              Expanded(
                child: _StoryNodeBadge(
                  node: nodes[i],
                  isCurrent: nodes[i].id == currentNodeId,
                  isNext: nodes[i].id == nextNodeId,
                  accentColor: accentColor,
                  onPrimary: onPrimary,
                  mutedOnPrimary: mutedOnPrimary,
                  faintOnPrimary: faintOnPrimary,
                ),
              ),
              if (i < nodes.length - 1)
                Container(
                  width: 20,
                  height: 4,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.microSpacing6,
                  ),
                  decoration: BoxDecoration(
                    color: nodes[i].state == StoryNodeState.completed
                        ? accentColor
                        : faintOnPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StoryNodeBadge extends StatelessWidget {
  const _StoryNodeBadge({
    required this.node,
    required this.isCurrent,
    required this.isNext,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.faintOnPrimary,
  });

  final StoryNode node;
  final bool isCurrent;
  final bool isNext;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color faintOnPrimary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (node.state) {
      StoryNodeState.completed => accentColor.withValues(
          alpha: AppOpacities.accentFillSubtle,
        ),
      StoryNodeState.current => const Color(0xFFD39A2F).withValues(alpha: 0.18),
      StoryNodeState.upcoming => Colors.transparent,
    };

    final borderColor = switch (node.state) {
      StoryNodeState.completed => accentColor,
      StoryNodeState.current => const Color(0xFFD39A2F),
      StoryNodeState.upcoming => isNext ? faintOnPrimary : mutedOnPrimary,
    };

    final icon = switch (node.state) {
      StoryNodeState.completed => Icons.check,
      StoryNodeState.current => Icons.place,
      StoryNodeState.upcoming =>
        isNext ? Icons.flag_outlined : Icons.circle_outlined,
    };

    final textColor = switch (node.state) {
      StoryNodeState.completed => onPrimary,
      StoryNodeState.current => onPrimary,
      StoryNodeState.upcoming => mutedOnPrimary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.microSpacing6,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: isCurrent ? 22 : 18),
          const SizedBox(height: AppConstants.microSpacing4),
          Text(
            node.landmark,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
