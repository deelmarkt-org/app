# Screen-to-Spec Mapping

> Lookup table linking Flutter screen files to their design specs and design variants.
> Used by developers and AI agents to find the correct spec before implementing a UI task.
> Referenced by CLAUDE.md §7.1 — read the spec + check the designs before writing code.

| Screen File | Spec | Designs |
|:------------|:-----|:--------|
| `lib/features/onboarding/presentation/onboarding_screen.dart` | [01-onboarding.md](01-auth/01-onboarding.md) | `01-auth/designs/onboarding_*` (3) |
| `lib/features/auth/presentation/screens/register_screen.dart` | [02-registration.md](01-auth/02-registration.md) | `01-auth/designs/registration_*` (3) |
| `lib/features/auth/presentation/screens/login_screen.dart` | [03-login.md](01-auth/03-login.md) | `01-auth/designs/login_*` (4) |
| *(KYC modal — embedded in screens)* | [04-kyc-prompt.md](01-auth/04-kyc-prompt.md) | `01-auth/designs/kyc_*` (4) |
| *(Social login — embedded in login)* | [05-social-login.md](01-auth/05-social-login.md) | `01-auth/designs/social_*` (2) |
| `lib/features/home/presentation/home_screen.dart` | [01-home-buyer.md](02-home/01-home-buyer.md) | `02-home/designs/home_*` (5) |
| *(Seller mode toggle — same screen)* | [02-home-seller.md](02-home/02-home-seller.md) | `02-home/designs/seller_*` (2) |
| `lib/features/search/presentation/search_screen.dart` | [03-search.md](02-home/03-search.md) | `02-home/designs/search_*` (5) |
| `lib/features/home/presentation/screens/category_browse_screen.dart` | [04-category-browse.md](02-home/04-category-browse.md) | `02-home/designs/category_*` (7) |
| `lib/features/listing_detail/presentation/listing_detail_screen.dart` | [01-listing-detail.md](03-listings/01-listing-detail.md) | `03-listings/designs/product_*` (10) |
| `lib/features/sell/presentation/screens/listing_creation_screen.dart` | [02-listing-creation.md](03-listings/02-listing-creation.md) | `03-listings/designs/listing_*` (4) |
| `lib/features/home/presentation/screens/favourites_screen.dart` | [03-favourites.md](03-listings/03-favourites.md) | `03-listings/designs/favourites_*` (2) |
| *(Payment summary — embedded in flow)* | [01-payment-summary.md](04-payments/01-payment-summary.md) | `04-payments/designs/payment_*` (4) |
| `lib/features/transaction/presentation/screens/mollie_checkout_screen.dart` | [02-mollie-checkout.md](04-payments/02-mollie-checkout.md) | `04-payments/designs/checkout_*` (4) |
| `lib/features/transaction/presentation/screens/transaction_detail_screen.dart` | [03-transaction-detail.md](04-payments/03-transaction-detail.md) | `04-payments/designs/transaction_*` (4) |
| `lib/features/shipping/presentation/screens/shipping_qr_screen.dart` | [01-shipping-qr.md](05-shipping/01-shipping-qr.md) | `05-shipping/designs/qr_*` (3) |
| `lib/features/shipping/presentation/screens/tracking_screen.dart` | [02-tracking-timeline.md](05-shipping/02-tracking-timeline.md) | `05-shipping/designs/tracking_*` (4) |
| `lib/features/shipping/presentation/screens/parcel_shop_selector_screen.dart` | [03-parcel-shop-selector.md](05-shipping/03-parcel-shop-selector.md) | `05-shipping/designs/parcel_*` (4) |
| `lib/features/messages/presentation/screens/conversation_list_screen.dart` | [01-conversation-list.md](06-chat/01-conversation-list.md) | `06-chat/designs/messages_*` (4) |
| `lib/features/messages/presentation/screens/chat_thread_screen.dart` | [02-chat-thread.md](06-chat/02-chat-thread.md) | `06-chat/designs/chat_*` (6) |
| *(Scam alert — embedded widget)* | [03-scam-alert.md](06-chat/03-scam-alert.md) | `06-chat/designs/scam_*` (2) |
| `lib/features/profile/presentation/screens/own_profile_screen.dart` | [01-own-profile.md](07-profile/01-own-profile.md) | `07-profile/designs/own_*` (4) |
| `lib/features/profile/presentation/screens/public_profile_screen.dart` | [02-seller-profile.md](07-profile/02-seller-profile.md) | `07-profile/designs/public_*` (5) |
| `lib/features/profile/presentation/screens/settings_screen.dart` | [03-settings.md](07-profile/03-settings.md) | `07-profile/designs/settings_*` (4) |
| `lib/features/profile/presentation/screens/review_screen.dart` | [04-rating-review.md](07-profile/04-rating-review.md) | `07-profile/designs/rating_*` (4) |
| *(Admin panel — Retool, not Flutter)* | [01-admin-panel.md](08-admin/01-admin-panel.md) | `08-admin/designs/admin_*` (5) |
