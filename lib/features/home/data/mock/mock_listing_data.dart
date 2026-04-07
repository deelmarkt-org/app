import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

/// Sample image URL for mock listings.
const sampleImageUrl =
    'https://res.cloudinary.com/demo/image/upload/sample.jpg';

// ── Seller constants ──────────────────────────────────────────────────────────

const _user001 = 'user-001';
const _janDeVries = 'Jan de Vries';

const _user002 = 'user-002';
const _mariaJansen = 'Maria Jansen';

const _user003 = 'user-003';
const _pieterBakker = 'Pieter Bakker';

const _user004 = 'user-004';
const _sophieVisser = 'Sophie Visser';

const _user005 = 'user-005';
const _ahmedElAmrani = 'Ahmed El Amrani';

const _user006 = 'user-006';
const _henkDeGroot = 'Henk de Groot';

/// Mock listing data — 13 listings across categories.
final mockListings = [
  ListingEntity(
    id: 'listing-001',
    title: 'Giant Defy Advanced 2 Racefiets',
    description:
        'Carbon frame, Shimano 105 groepset. 2 jaar oud, weinig gereden.',
    priceInCents: 89500,
    sellerId: _user001,
    sellerName: _janDeVries,
    condition: ListingCondition.good,
    categoryId: 'cat-sport',
    imageUrls: const [sampleImageUrl],
    location: 'Amsterdam',
    distanceKm: 3.2,
    createdAt: DateTime(2026, 3, 20),
  ),
  ListingEntity(
    id: 'listing-002',
    title: 'iPhone 15 Pro 256GB',
    description: 'Inclusief originele doos en oplader. Geen kratjes.',
    priceInCents: 75000,
    sellerId: _user002,
    sellerName: _mariaJansen,
    condition: ListingCondition.likeNew,
    categoryId: 'cat-electronics',
    imageUrls: const [sampleImageUrl],
    location: 'Rotterdam',
    distanceKm: 12.5,
    status: ListingStatus.sold,
    createdAt: DateTime(2026, 3, 22),
  ),
  ListingEntity(
    id: 'listing-003',
    title: 'IKEA Kallax Kast 4x4',
    description: 'Wit, goede staat. Zelf ophalen in Utrecht.',
    priceInCents: 4500,
    sellerId: _user003,
    sellerName: _pieterBakker,
    condition: ListingCondition.fair,
    categoryId: 'cat-home',
    imageUrls: const [sampleImageUrl],
    location: 'Utrecht',
    distanceKm: 8.0,
    createdAt: DateTime(2026, 3, 24),
  ),
  ListingEntity(
    id: 'listing-004',
    title: 'Nike Air Max 90 maat 43',
    description:
        'Nieuw met labels, nooit gedragen. Cadeau gekregen maar verkeerde maat.',
    priceInCents: 8900,
    sellerId: _user004,
    sellerName: _sophieVisser,
    condition: ListingCondition.newWithTags,
    categoryId: 'cat-shoes',
    imageUrls: const [sampleImageUrl],
    location: 'Den Haag',
    distanceKm: 5.1,
    createdAt: DateTime(2026, 3, 25),
  ),
  ListingEntity(
    id: 'listing-005',
    title: 'Samsung Galaxy S24 Ultra 512GB',
    description: 'Titanium Black, compleet met doos en garantie tot december.',
    priceInCents: 95000,
    sellerId: _user005,
    sellerName: _ahmedElAmrani,
    condition: ListingCondition.likeNew,
    categoryId: 'cat-phones',
    imageUrls: const [sampleImageUrl],
    location: 'Amsterdam',
    distanceKm: 2.1,
    createdAt: DateTime(2026, 3, 26),
  ),
  ListingEntity(
    id: 'listing-006',
    title: 'Gazelle Ultimate T10 HMB E-bike',
    description: 'Elektrische fiets, 2 jaar oud, accu in goede staat.',
    priceInCents: 210000,
    sellerId: _user006,
    sellerName: _henkDeGroot,
    condition: ListingCondition.good,
    categoryId: 'cat-bikes',
    imageUrls: const [sampleImageUrl],
    location: 'Utrecht',
    distanceKm: 7.3,
    createdAt: DateTime(2026, 3, 27),
  ),
  ListingEntity(
    id: 'listing-007',
    title: 'Vintage IKEA Moments salontafel',
    description: 'Glazen tafel met metalen frame. Retro jaren 90 design.',
    priceInCents: 12500,
    sellerId: _user003,
    sellerName: _pieterBakker,
    condition: ListingCondition.good,
    categoryId: 'cat-furniture',
    imageUrls: const [sampleImageUrl],
    location: 'Rotterdam',
    distanceKm: 11.0,
    createdAt: DateTime(2026, 3, 28),
  ),
  ListingEntity(
    id: 'listing-008',
    title: 'PlayStation 5 Slim + 2 controllers',
    description: 'Digitale editie met extra controller en 3 games.',
    priceInCents: 42500,
    sellerId: _user002,
    sellerName: _mariaJansen,
    condition: ListingCondition.good,
    categoryId: 'cat-gaming',
    imageUrls: const [sampleImageUrl],
    location: 'Eindhoven',
    distanceKm: 1.5,
    createdAt: DateTime(2026, 3, 29),
  ),
  ListingEntity(
    id: 'listing-009',
    title: 'Dumbbells set 2x 20kg verstelbaar',
    description: 'Professionele set, nauwelijks gebruikt. Inclusief standaard.',
    priceInCents: 7500,
    sellerId: _user001,
    sellerName: _janDeVries,
    condition: ListingCondition.likeNew,
    categoryId: 'cat-fitness',
    imageUrls: const [sampleImageUrl],
    location: 'Amsterdam',
    distanceKm: 4.2,
    createdAt: DateTime(2026, 3, 30),
  ),
  ListingEntity(
    id: 'listing-010',
    title: 'LEGO Technic Porsche 911 GT3 RS',
    description: 'Compleet met doos en handleiding. Tentoongesteld geweest.',
    priceInCents: 28000,
    sellerId: _user004,
    sellerName: _sophieVisser,
    condition: ListingCondition.good,
    categoryId: 'cat-toys',
    imageUrls: const [sampleImageUrl],
    location: 'Den Haag',
    distanceKm: 6.0,
    createdAt: DateTime(2026, 3, 31),
  ),
  ListingEntity(
    id: 'listing-011',
    title: 'Rapha Core wielrenshirt maat M',
    description: 'Marineblauw, gedragen maar in prima staat.',
    priceInCents: 4500,
    sellerId: _user006,
    sellerName: _henkDeGroot,
    condition: ListingCondition.good,
    categoryId: 'cat-men',
    imageUrls: const [sampleImageUrl],
    location: 'Utrecht',
    distanceKm: 3.0,
    createdAt: DateTime(2026, 4),
  ),
  ListingEntity(
    id: 'listing-012',
    title: 'Sonos Era 100 speaker wit',
    description: 'Perfecte staat, werkt foutloos. Originele verpakking.',
    priceInCents: 22000,
    sellerId: _user005,
    sellerName: _ahmedElAmrani,
    condition: ListingCondition.likeNew,
    categoryId: 'cat-phones',
    imageUrls: const [sampleImageUrl],
    location: 'Eindhoven',
    distanceKm: 1.2,
    createdAt: DateTime(2026, 4, 2),
  ),
  ListingEntity(
    id: 'listing-013',
    title: 'Tuinset 4 stoelen + tafel',
    description: 'Teakhout, weerbestendig. Past op elk balkon of in de tuin.',
    priceInCents: 35000,
    sellerId: _user003,
    sellerName: _pieterBakker,
    condition: ListingCondition.fair,
    categoryId: 'cat-garden',
    imageUrls: const [sampleImageUrl],
    location: 'Haarlem',
    distanceKm: 15.0,
    createdAt: DateTime(2026, 4, 3),
  ),
];
