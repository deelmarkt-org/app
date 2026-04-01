import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';

/// Mock category repository — 8 L1 categories per design system.
class MockCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryEntity>> getTopLevel() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _l1Categories;
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final all = [..._l1Categories, ..._l2Categories];
    return all.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<CategoryEntity>> getSubcategories(String parentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _l2Categories.where((c) => c.parentId == parentId).toList();
  }
}

/// 8 L1 categories per docs/design-system/components.md §Categories.
const _l1Categories = [
  CategoryEntity(
    id: 'cat-vehicles',
    name: 'Voertuigen',
    icon: 'car',
    listingCount: 234,
  ),
  CategoryEntity(
    id: _catElectronics,
    name: 'Elektronica',
    icon: 'device-mobile',
    listingCount: 567,
  ),
  CategoryEntity(
    id: 'cat-home',
    name: 'Huis & Meubels',
    icon: 'house',
    listingCount: 345,
  ),
  CategoryEntity(
    id: 'cat-clothing',
    name: 'Kleding & Mode',
    icon: 't-shirt',
    listingCount: 891,
  ),
  CategoryEntity(
    id: _catSport,
    name: 'Sport & Vrije tijd',
    icon: 'bicycle',
    listingCount: 123,
  ),
  CategoryEntity(
    id: 'cat-kids',
    name: 'Kinderen & Baby\'s',
    icon: 'baby',
    listingCount: 456,
  ),
  CategoryEntity(
    id: 'cat-services',
    name: 'Diensten',
    icon: 'wrench',
    listingCount: 78,
  ),
  CategoryEntity(
    id: 'cat-other',
    name: 'Overig',
    icon: 'dots-three',
    listingCount: 234,
  ),
];

/// L1 category IDs referenced by L2 subcategories.
const _catElectronics = 'cat-electronics';
const _catSport = 'cat-sport';

const _l2Categories = [
  CategoryEntity(
    id: 'cat-phones',
    name: 'Telefoons',
    icon: 'phone',
    parentId: _catElectronics,
  ),
  CategoryEntity(
    id: 'cat-laptops',
    name: 'Laptops',
    icon: 'laptop',
    parentId: _catElectronics,
  ),
  CategoryEntity(
    id: 'cat-gaming',
    name: 'Gaming',
    icon: 'game-controller',
    parentId: _catElectronics,
  ),
  CategoryEntity(
    id: 'cat-bikes',
    name: 'Fietsen',
    icon: 'bicycle',
    parentId: _catSport,
  ),
  CategoryEntity(
    id: 'cat-fitness',
    name: 'Fitness',
    icon: 'barbell',
    parentId: _catSport,
  ),
];
