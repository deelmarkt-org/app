import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Maps category icon string names to Phosphor duotone icons.
///
/// Extracted from [CategoryCarousel._iconFor] for reuse across
/// category browse, detail, and search screens.
///
/// Reference: docs/design-system/components.md - Categories
IconData categoryIconFor(String name) => switch (name) {
  // L1 categories
  'car' => PhosphorIcons.car(PhosphorIconsStyle.duotone),
  'device-mobile' ||
  'devices' => PhosphorIcons.devices(PhosphorIconsStyle.duotone),
  'house' || 'armchair' => PhosphorIcons.armchair(PhosphorIconsStyle.duotone),
  't-shirt' => PhosphorIcons.tShirt(PhosphorIconsStyle.duotone),
  'bicycle' => PhosphorIcons.bicycle(PhosphorIconsStyle.duotone),
  'baby' => PhosphorIcons.baby(PhosphorIconsStyle.duotone),
  'wrench' => PhosphorIcons.wrench(PhosphorIconsStyle.duotone),
  'dots-three' ||
  'package' => PhosphorIcons.package(PhosphorIconsStyle.duotone),

  // L2 subcategories
  'phone' => PhosphorIcons.phone(PhosphorIconsStyle.duotone),
  'laptop' => PhosphorIcons.laptop(PhosphorIconsStyle.duotone),
  'game-controller' => PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
  'motorcycle' => PhosphorIcons.motorcycle(PhosphorIconsStyle.duotone),
  'scooter' => PhosphorIcons.scooter(PhosphorIconsStyle.duotone),
  'cooking-pot' => PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
  'flower' => PhosphorIcons.flower(PhosphorIconsStyle.duotone),
  'paint-roller' => PhosphorIcons.paintRoller(PhosphorIconsStyle.duotone),
  'dress' => PhosphorIcons.dress(PhosphorIconsStyle.duotone),
  'pants' => PhosphorIcons.pants(PhosphorIconsStyle.duotone),
  'sneaker' => PhosphorIcons.sneaker(PhosphorIconsStyle.duotone),
  'handbag' => PhosphorIcons.handbag(PhosphorIconsStyle.duotone),
  'soccer-ball' => PhosphorIcons.soccerBall(PhosphorIconsStyle.duotone),
  'tennis-ball' => PhosphorIcons.tennisBall(PhosphorIconsStyle.duotone),
  'running' => PhosphorIcons.personSimpleRun(PhosphorIconsStyle.duotone),
  'waves' => PhosphorIcons.waves(PhosphorIconsStyle.duotone),
  'snowflake' => PhosphorIcons.snowflake(PhosphorIconsStyle.duotone),
  'toy-brick' => PhosphorIcons.lego(PhosphorIconsStyle.duotone),
  'baby-carriage' => PhosphorIcons.babyCarriage(PhosphorIconsStyle.duotone),
  'backpack' => PhosphorIcons.backpack(PhosphorIconsStyle.duotone),
  'hammer' => PhosphorIcons.hammer(PhosphorIconsStyle.duotone),
  'chalkboard-teacher' => PhosphorIcons.chalkboardTeacher(
    PhosphorIconsStyle.duotone,
  ),
  'truck' => PhosphorIcons.truck(PhosphorIconsStyle.duotone),
  'vinyl-record' => PhosphorIcons.vinylRecord(PhosphorIconsStyle.duotone),
  'music-notes' => PhosphorIcons.musicNotes(PhosphorIconsStyle.duotone),
  'paint-brush' => PhosphorIcons.paintBrush(PhosphorIconsStyle.duotone),
  'barbell' => PhosphorIcons.barbell(PhosphorIconsStyle.duotone),

  // Fallback
  _ => PhosphorIcons.tag(PhosphorIconsStyle.duotone),
};
