import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_data.dart';

/// Helper to reduce per-entry boilerplate and eliminate SonarCloud duplication.
CategoryEntity _sub(String id, String name, String icon, String parent) =>
    CategoryEntity(id: id, name: name, icon: icon, parentId: parent);

/// L2 subcategories for all 8 L1 categories.
final l2Categories = [
  // ── Voertuigen ──
  _sub('cat-cars', "Auto's", 'car', catVehicles),
  _sub('cat-motorcycles', 'Motoren', 'motorcycle', catVehicles),
  _sub('cat-scooters', 'Scooters', 'scooter', catVehicles),
  _sub('cat-parts', 'Onderdelen', 'wrench', catVehicles),
  // ── Elektronica ──
  _sub('cat-phones', 'Telefoons', 'phone', catElectronics),
  _sub('cat-laptops', 'Laptops', 'laptop', catElectronics),
  _sub('cat-gaming', 'Gaming', 'game-controller', catElectronics),
  // ── Huis & Meubels ──
  _sub('cat-furniture', 'Meubels', 'armchair', catHome),
  _sub('cat-kitchen', 'Keuken', 'cooking-pot', catHome),
  _sub('cat-garden', 'Tuin', 'flower', catHome),
  _sub('cat-decor', 'Decoratie', 'paint-roller', catHome),
  // ── Kleding & Mode ──
  _sub('cat-women', 'Dameskleding', 'dress', catClothing),
  _sub('cat-men', 'Herenkleding', 'pants', catClothing),
  _sub('cat-shoes', 'Schoenen', 'sneaker', catClothing),
  _sub('cat-accessories', 'Accessoires', 'handbag', catClothing),
  // ── Sport & Vrije tijd ──
  _sub('cat-bikes', 'Fietsen', 'bicycle', catSport),
  _sub('cat-fitness', 'Fitness', 'barbell', catSport),
  _sub('cat-football', 'Voetbal', 'soccer-ball', catSport),
  _sub('cat-tennis', 'Tennis', 'tennis-ball', catSport),
  _sub('cat-running', 'Hardlopen', 'running', catSport),
  _sub('cat-watersport', 'Watersport', 'waves', catSport),
  _sub('cat-wintersport', 'Wintersport', 'snowflake', catSport),
  // ── Kinderen & Baby's ──
  _sub('cat-toys', 'Speelgoed', 'toy-brick', catKids),
  _sub('cat-kids-clothing', 'Kinderkleding', 't-shirt', catKids),
  _sub('cat-strollers', 'Kinderwagens', 'baby-carriage', catKids),
  _sub('cat-school', 'Schoolspullen', 'backpack', catKids),
  // ── Diensten ──
  _sub('cat-handyman', 'Klussen', 'hammer', catServices),
  _sub('cat-tutoring', 'Les & Bijles', 'chalkboard-teacher', catServices),
  _sub('cat-moving', 'Verhuizen', 'truck', catServices),
  _sub('cat-services-other', 'Overig', 'dots-three', catServices),
  // ── Overig ──
  _sub('cat-collectibles', 'Verzamelingen', 'vinyl-record', catOther),
  _sub('cat-music', 'Muziek', 'music-notes', catOther),
  _sub('cat-art', 'Kunst', 'paint-brush', catOther),
  _sub('cat-misc', 'Diversen', 'dots-three', catOther),
];
