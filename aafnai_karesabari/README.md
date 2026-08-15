# 🌾 Aafnai Karesabari - Agricultural Marketplace

A Flutter-based agricultural marketplace connecting farmers (sellers) with buyers in Nepal. Built with Firebase, Firestore, and Riverpod state management.

---

## 📱 Features

### For Sellers (Farmers)
- ✅ Create & manage product listings
- ✅ Track inventory with quick-adjust buttons
- ✅ Accept/reject/complete orders
- ✅ View earnings dashboard
- ✅ Monitor order status
- ✅ Track seller ratings & reviews
- ✅ Manage seller profile

### For Buyers (Customers)
- ✅ Browse & search products
- ✅ Filter by category
- ✅ View product details with ratings
- ✅ Add to wishlist
- ✅ Shopping cart management
- ✅ Checkout & place orders
- ✅ Track order status
- ✅ Rate & review products
- ✅ View farmer profiles

### For Admins
- ✅ Approve/reject seller applications
- ✅ Monitor all orders
- ✅ View platform analytics
- ✅ Manage platform listings
- ✅ Track commissions & payouts

---

## 🚀 Quick Start (30 Minutes)

**See: [QUICK_START.md](QUICK_START.md)** - Fastest way to get running!

**Or detailed setup: [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)**

```bash
# 1. Clone repository
git clone <repo-url>
cd aafnai_karesabari

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (see QUICK_START.md)
flutterfire configure

# 4. Run the app
flutter run
```

---

## 📋 Documentation

| Guide | Purpose | Time |
|-------|---------|------|
| **[QUICK_START.md](QUICK_START.md)** | Get app running in 30 minutes | 30 min |
| **[FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)** | Detailed Firebase configuration | 1-2 hours |
| **[ADMIN_OPERATIONS_GUIDE.md](ADMIN_OPERATIONS_GUIDE.md)** | How to manage the platform | Reference |
| **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** | Pre-launch verification | Reference |

---

## 🏗️ Architecture

### Technology Stack
- **Frontend:** Flutter 3.x, Dart
- **State Management:** Riverpod (async notifiers)
- **Backend:** Firebase (Authentication, Firestore, Storage)
- **Database:** Firestore (NoSQL)
- **Routing:** GoRouter with deep linking
- **UI:** Material Design 3

### Project Structure
```
lib/
├── core/              # Theme, errors, utilities
├── data/
│   ├── models/        # Data classes (User, Order, Review, etc.)
│   ├── repositories/  # Local + Firebase data access
│   └── services/      # Business logic (OrderService, ReviewService, etc.)
├── features/
│   ├── admin/         # Admin dashboard & management
│   ├── consumer/      # Buyer experience (home, search, cart, checkout)
│   ├── onboarding/    # Auth & profile setup
│   ├── seller/        # Seller management (listings, orders, earnings)
│   └── shared/        # Shared screens (notifications, settings)
├── routing/           # GoRouter configuration
├── shared/            # Reusable components
└── main.dart          # App entry point
```

---

## 📊 Project Status

### ✅ COMPLETE (Production Ready)

| Phase | Feature | Status |
|-------|---------|--------|
| **Phase 1** | Project Setup | ✅ Complete |
| **Phase 2** | Authentication | ✅ Complete |
| **Phase 3** | Seller Listings | ✅ Complete |
| **Phase 4** | Seller Management | ✅ Complete |
| **Phase 5.1** | Buyer Experience (Core) | ✅ Complete |
| **Phase 5.2** | Ratings & Reviews | ✅ Complete |

### ⏳ COMING SOON (Post-Launch Enhancements)

- Order Details Page (full tracking timeline)
- Buyer Notifications (real-time order alerts)
- Advanced Filtering (price range, sorting)
- Admin Analytics Dashboard
- Seller Messaging
- Push Notifications (Firebase Cloud Messaging)

---

## 🧪 Testing & Quality

### Test Coverage
```
✅ 29/29 tests passing
✅ 0 compilation errors
⚠️  28 info lints (pre-existing deprecation warnings)
```

### Run Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

---

## 🔐 Security

### Firestore Rules
- ✅ Role-based access control (buyer/seller/admin)
- ✅ Sellers can only modify own listings
- ✅ Buyers can only view own orders
- ✅ Reviews tied to completed orders only
- ✅ Public read on active listings

### Authentication
- ✅ Firebase Auth with email/password
- ✅ OTP-based phone verification
- ✅ Session tokens secure (no localStorage)
- ✅ Role assignment at registration

### Storage
- ✅ Authenticated uploads only
- ✅ Seller authorization verified
- ✅ File deletion access controlled

---

## 🌍 Deployment

### Before Launch
1. **Firebase Setup:** Follow [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)
2. **Admin Setup:** See [ADMIN_OPERATIONS_GUIDE.md](ADMIN_OPERATIONS_GUIDE.md)
3. **Pre-Launch:** Review [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

### Build & Deploy
```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ipa --release

# Web
flutter build web --release
firebase deploy --only hosting
```

### Store Submission
- **Google Play Store:** 2-24 hours review
- **Apple App Store:** 1-3 days review
- **Firebase Hosting:** Instant deployment

---

## 📱 User Flows

### Buyer Flow
```
Register → Profile Setup → Browse Home → Search Products → 
View Details → Add to Cart → Checkout → Order Confirmation → 
Track Order → Leave Review
```

### Seller Flow
```
Register → Complete Profile → Wait for Approval → Create Listing → 
Receive Orders → Accept/Complete → View Earnings → See Ratings
```

### Admin Flow
```
Login → Dashboard → Approve Sellers → Monitor Orders → View Analytics
```

---

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies & app metadata |
| `lib/firebase_options.dart` | Firebase config (auto-generated) |
| `firestore.rules` | Firestore security rules |
| `android/app/google-services.json` | Android Firebase config |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config |

---

## 📊 Database Schema

### Collections
- **users/** - User profiles (buyers, sellers, admins)
- **listings/** - Product listings
- **orders/** - Purchase orders
- **reviews/** - Ratings & reviews
- **admin_users/** - Admin access control
- **notifications/** - In-app notifications
- **market_prices/** - Reference pricing data

---

## 🚨 Troubleshooting

### Firebase Not Connecting
```
1. Check google-services.json in android/app/
2. Check GoogleService-Info.plist in ios/Runner/
3. Run: flutterfire configure
4. Restart app
```

### Firestore Permission Denied
```
1. Go to Firebase Console → Firestore → Rules
2. Verify rules are PUBLISHED (green checkmark)
3. Check security rules include your auth checks
4. Logout/login to refresh auth token
```

### Admin Dashboard Not Showing
```
1. Verify admin_users collection exists in Firestore
2. Verify your user UID is in admin_users/{uid}
3. Check firestore.rules has isAdmin() function
4. Logout and login again
```

---


---

**Built with ❤️ for local farmers in Nepal**
