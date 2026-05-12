# UI Audit - Shop App

## Current State Observations

### 1. General Style
- Uses default Flutter Material 3 seed color (Blue).
- Simple `ListView` or `Column` layouts.
- Basic `Card` and `ListTile` components.
- Navigation is mostly via `AppBar` icons.

### 2. HomeScreen
- `AppBar` is overloaded with icons (Cart, Chat, Notifications, Map, Profile, Logout).
- Product list is a simple vertical `ListView` of `ListTile`s.
- Images are small (50x50 in `leading`).

### 3. ProductDetailScreen
- Simple `PageView` for images.
- Basic `ChoiceChip` for sizes.
- Quantity selector is a simple `Row` with `IconButton`s.

### 4. CartScreen / CheckoutScreen
- Standard `ListView` of items.
- Basic `Form` fields.

## Problems to Solve
- **Overcrowded Header**: Too many icons in `HomeScreen`'s `AppBar`.
- **Dated Product List**: Vertical `ListTile`s don't showcase clothing well. A `GridView` is better.
- **Color Scheme**: The default blue is a bit generic for a "Clothing Shop".
- **Navigation**: Lack of a `BottomNavigationBar` makes it hard to switch between main areas (Home, Search/Categories, Cart, Profile).
- **Inconsistent Spacing**: Many screens use hardcoded padding/margin which might look different on various devices.

## Proposed Overhaul Strategy
1.  **Global Theme**: Switch to a more modern color palette (e.g., Deep Orange/Coral or a minimalist Black/White with accent).
2.  **Navigation**: Implement a `BottomNavigationBar` for primary navigation.
3.  **HomeScreen**:
    - Use a `GridView` for products to show larger images.
    - Add a "Featured" or "Banner" section at the top.
    - Category chips/tabs.
4.  **Product Card**: Modern card design with shadow, rounded corners, and clear price/rating.
5.  **Product Detail**: Improved image gallery, better size selection UI, and a more prominent "Add to Cart" button.
6.  **Typography**: Use a consistent font (standard Flutter or Google Fonts if allowed).
