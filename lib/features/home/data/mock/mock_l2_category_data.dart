import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_data.dart';

/// L2 subcategories for all 8 L1 categories.
const l2Categories = [
  // ── Voertuigen ──
  CategoryEntity(
    id: 'cat-cars',
    name: "Auto's",
    icon: 'car',
    parentId: catVehicles,
  ),
  CategoryEntity(
    id: 'cat-motorcycles',
    name: 'Motoren',
    icon: 'motorcycle',
    parentId: catVehicles,
  ),
  CategoryEntity(
    id: 'cat-scooters',
    name: 'Scooters',
    icon: 'scooter',
    parentId: catVehicles,
  ),
  CategoryEntity(
    id: 'cat-parts',
    name: 'Onderdelen',
    icon: 'wrench',
    parentId: catVehicles,
  ),
  // ── Elektronica ──
  CategoryEntity(
    id: 'cat-phones',
    name: 'Telefoons',
    icon: 'phone',
    parentId: catElectronics,
  ),
  CategoryEntity(
    id: 'cat-laptops',
    name: 'Laptops',
    icon: 'laptop',
    parentId: catElectronics,
  ),
  CategoryEntity(
    id: 'cat-gaming',
    name: 'Gaming',
    icon: 'game-controller',
    parentId: catElectronics,
  ),
  // ── Huis & Meubels ──
  CategoryEntity(
    id: 'cat-furniture',
    name: 'Meubels',
    icon: 'armchair',
    parentId: catHome,
  ),
  CategoryEntity(
    id: 'cat-kitchen',
    name: 'Keuken',
    icon: 'cooking-pot',
    parentId: catHome,
  ),
  CategoryEntity(
    id: 'cat-garden',
    name: 'Tuin',
    icon: 'flower',
    parentId: catHome,
  ),
  CategoryEntity(
    id: 'cat-decor',
    name: 'Decoratie',
    icon: 'paint-roller',
    parentId: catHome,
  ),
  // ── Kleding & Mode ──
  CategoryEntity(
    id: 'cat-women',
    name: 'Dameskleding',
    icon: 'dress',
    parentId: catClothing,
  ),
  CategoryEntity(
    id: 'cat-men',
    name: 'Herenkleding',
    icon: 'pants',
    parentId: catClothing,
  ),
  CategoryEntity(
    id: 'cat-shoes',
    name: 'Schoenen',
    icon: 'sneaker',
    parentId: catClothing,
  ),
  CategoryEntity(
    id: 'cat-accessories',
    name: 'Accessoires',
    icon: 'handbag',
    parentId: catClothing,
  ),
  // ── Sport & Vrije tijd ──
  CategoryEntity(
    id: 'cat-bikes',
    name: 'Fietsen',
    icon: 'bicycle',
    parentId: catSport,
  ),
  CategoryEntity(
    id: 'cat-fitness',
    name: 'Fitness',
    icon: 'barbell',
    parentId: catSport,
  ),
  CategoryEntity(
    id: 'cat-football',
    name: 'Voetbal',
    icon: 'soccer-ball',
    parentId: catSport,
  ),
  CategoryEntity(
    id: 'cat-tennis',
    name: 'Tennis',
    icon: 'tennis-ball',
    parentId: catSport,
  ),
  CategoryEntity(
    id: 'cat-running',
    name: 'Hardlopen',
    icon: 'running',
    parentId: catSport,
  ),
  CategoryEntity(
    id: 'cat-watersport',
    name: 'Watersport',
    icon: 'waves',
    parentId: catSport,
  ),
  CategoryEntity(
    id: 'cat-wintersport',
    name: 'Wintersport',
    icon: 'snowflake',
    parentId: catSport,
  ),
  // ── Kinderen & Baby's ──
  CategoryEntity(
    id: 'cat-toys',
    name: 'Speelgoed',
    icon: 'toy-brick',
    parentId: catKids,
  ),
  CategoryEntity(
    id: 'cat-kids-clothing',
    name: 'Kinderkleding',
    icon: 't-shirt',
    parentId: catKids,
  ),
  CategoryEntity(
    id: 'cat-strollers',
    name: 'Kinderwagens',
    icon: 'baby-carriage',
    parentId: catKids,
  ),
  CategoryEntity(
    id: 'cat-school',
    name: 'Schoolspullen',
    icon: 'backpack',
    parentId: catKids,
  ),
  // ── Diensten ──
  CategoryEntity(
    id: 'cat-handyman',
    name: 'Klussen',
    icon: 'hammer',
    parentId: catServices,
  ),
  CategoryEntity(
    id: 'cat-tutoring',
    name: 'Les & Bijles',
    icon: 'chalkboard-teacher',
    parentId: catServices,
  ),
  CategoryEntity(
    id: 'cat-moving',
    name: 'Verhuizen',
    icon: 'truck',
    parentId: catServices,
  ),
  CategoryEntity(
    id: 'cat-services-other',
    name: 'Overig',
    icon: 'dots-three',
    parentId: catServices,
  ),
  // ── Overig ──
  CategoryEntity(
    id: 'cat-collectibles',
    name: 'Verzamelingen',
    icon: 'vinyl-record',
    parentId: catOther,
  ),
  CategoryEntity(
    id: 'cat-music',
    name: 'Muziek',
    icon: 'music-notes',
    parentId: catOther,
  ),
  CategoryEntity(
    id: 'cat-art',
    name: 'Kunst',
    icon: 'paint-brush',
    parentId: catOther,
  ),
  CategoryEntity(
    id: 'cat-misc',
    name: 'Diversen',
    icon: 'dots-three',
    parentId: catOther,
  ),
];
