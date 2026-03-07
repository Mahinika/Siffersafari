import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/story_progress.dart';

class StoryProgressCard extends StatelessWidget {
  const StoryProgressCard({
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
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: Stack(
                children: [
                  SizedBox(
                    height: 124,
                    width: double.infinity,
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
                  Positioned(
                    left: -18,
                    bottom: -22,
                    child: _HeroGlow(
                      size: 92,
                      color: accentColor.withValues(alpha: 0.22),
                    ),
                  ),
                  Positioned(
                    right: 58,
                    top: 10,
                    child: _HeroGlow(
                      size: 42,
                      color: onPrimary.withValues(alpha: 0.16),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.06),
                            Colors.black.withValues(alpha: 0.40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppConstants.defaultPadding,
                    top: AppConstants.defaultPadding,
                    child: _StoryBadge(
                      icon: Icons.terrain,
                      label: 'Aktiv stig',
                      accentColor: accentColor,
                      onPrimary: onPrimary,
                    ),
                  ),
                  Positioned(
                    right: AppConstants.defaultPadding,
                    top: AppConstants.defaultPadding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.smallPadding,
                        vertical: AppConstants.microSpacing6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: onPrimary.withValues(
                            alpha: AppOpacities.borderSubtle,
                          ),
                        ),
                      ),
                      child: Text(
                        '${story.completedNodes}/${story.totalNodes} checkpoints',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppConstants.defaultPadding,
                    right: 120,
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
                        border: Border.all(
                          color: onPrimary.withValues(
                            alpha: AppOpacities.borderSubtle,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            story.currentNode?.landmark ?? 'Djungelstigen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppConstants.microSpacing2),
                          Text(
                            'Ville spanar efter nästa ledtråd',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: onPrimary.withValues(alpha: 0.84),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Image.asset(
                        characterAsset,
                        height: 116,
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
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Icon(Icons.explore, color: accentColor),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    story.worldTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '${story.completedNodes}/${story.totalNodes}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.microSpacing6,
              children: [
                _StoryBadge(
                  icon: Icons.menu_book_outlined,
                  label: story.chapterTitle,
                  accentColor: accentColor,
                  onPrimary: onPrimary,
                ),
                _StoryBadge(
                  icon: Icons.place_outlined,
                  label: story.currentNode?.landmark ?? 'Stigen',
                  accentColor: accentColor,
                  onPrimary: onPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.microSpacing6),
            Text(
              story.worldSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subtleOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (story.currentNode != null) ...[
              const SizedBox(height: AppConstants.smallPadding),
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
                  children: [
                    Icon(Icons.forest, color: accentColor, size: 18),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        story.currentNode!.landmarkHint,
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
            _StoryPath(
              story: story,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              story.currentObjectiveTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              story.currentObjectiveDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subtleOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nästa checkpoint',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtleOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${(story.progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: LinearProgressIndicator(
                value: story.progress,
                minHeight: AppConstants.progressBarHeightSmall,
                backgroundColor: onPrimary.withValues(
                  alpha: AppOpacities.progressTrackLight,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: onStartQuest,
              child: const Text('Fortsätt genom djungeln'),
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
}

class _StoryBadge extends StatelessWidget {
  const _StoryBadge({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onPrimary,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.smallPadding,
          vertical: AppConstants.microSpacing6,
        ),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: AppOpacities.accentFillSubtle),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accentColor.withValues(alpha: AppOpacities.highlightStrong),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: onPrimary),
            const SizedBox(width: AppConstants.microSpacing6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: color.a * 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _StoryPath extends StatelessWidget {
  const _StoryPath({
    required this.story,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.faintOnPrimary,
  });

  final StoryProgress story;
  final Color accentColor;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color faintOnPrimary;

  @override
  Widget build(BuildContext context) {
    final nodes = _selectVisibleNodes(story.nodes, story.currentNodeIndex);

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < nodes.length; i++) ...[
              Expanded(
                child: _StoryNodeBadge(
                  node: nodes[i],
                  isCurrent: nodes[i].state == StoryNodeState.current,
                  accentColor: accentColor,
                  onPrimary: onPrimary,
                  mutedOnPrimary: mutedOnPrimary,
                  faintOnPrimary: faintOnPrimary,
                ),
              ),
              if (i < nodes.length - 1)
                Container(
                  width: 22,
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
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            Expanded(
              child: Text(
                'Ville är vid ${story.currentNode?.landmark ?? 'stigen'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: Text(
                'Nästa: ${story.currentNode?.title ?? story.currentObjectiveTitle}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: faintOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<StoryNode> _selectVisibleNodes(List<StoryNode> nodes, int currentIndex) {
    if (nodes.length <= 5) return nodes;

    final start = (currentIndex - 1).clamp(0, nodes.length - 5);
    final end = (start + 5).clamp(0, nodes.length);
    return nodes.sublist(start, end);
  }
}

class _StoryNodeBadge extends StatelessWidget {
  const _StoryNodeBadge({
    required this.node,
    required this.isCurrent,
    required this.accentColor,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.faintOnPrimary,
  });

  final StoryNode node;
  final bool isCurrent;
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
      StoryNodeState.current => onPrimary.withValues(
          alpha: AppOpacities.subtleFill,
        ),
      StoryNodeState.upcoming => Colors.transparent,
    };

    final borderColor = switch (node.state) {
      StoryNodeState.completed => accentColor,
      StoryNodeState.current =>
        onPrimary.withValues(alpha: AppOpacities.hudBorder),
      StoryNodeState.upcoming => faintOnPrimary,
    };

    final icon = switch (node.state) {
      StoryNodeState.completed => Icons.check,
      StoryNodeState.current => Icons.place,
      StoryNodeState.upcoming => Icons.circle_outlined,
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
            maxLines: 2,
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
