import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

/// L1 category ID constants — used by L2 data and tests.
const catVehicles = 'cat-vehicles';
const catElectronics = 'cat-electronics';
const catHome = 'cat-home';
const catClothing = 'cat-clothing';
const catSport = 'cat-sport';
const catKids = 'cat-kids';
const catServices = 'cat-services';
const catOther = 'cat-other';

/// 8 L1 categories per docs/design-system/components.md §Categories.
const l1Categories = [
  CategoryEntity(
    id: catVehicles,
    name: 'Voertuigen',
    icon: 'car',
    listingCount: 234,
  ),
  CategoryEntity(
    id: catElectronics,
    name: 'Elektronica',
    icon: 'device-mobile',
    listingCount: 567,
  ),
  CategoryEntity(
    id: catHome,
    name: 'Huis & Meubels',
    icon: 'house',
    listingCount: 345,
  ),
  CategoryEntity(
    id: catClothing,
    name: 'Kleding & Mode',
    icon: 't-shirt',
    listingCount: 891,
  ),
  CategoryEntity(
    id: catSport,
    name: 'Sport & Vrije tijd',
    icon: 'bicycle',
    listingCount: 123,
  ),
  CategoryEntity(
    id: catKids,
    name: 'Kinderen & Baby\'s',
    icon: 'baby',
    listingCount: 456,
  ),
  CategoryEntity(
    id: catServices,
    name: 'Diensten',
    icon: 'wrench',
    listingCount: 78,
  ),
  CategoryEntity(
    id: catOther,
    name: 'Overig',
    icon: 'dots-three',
    listingCount: 234,
  ),
];
