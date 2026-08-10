# ⚡ Quick Start - 30 Minutes to Production

**Fast-track guide to get Firebase running and launch the app.**

---

## 🎯 OBJECTIVE

Get **Aafnai Karesabari** running with Firebase in 30 minutes.

---

## ⏱️ 5 MIN: Create Firebase Project

```bash
1. Go to https://console.firebase.google.com/
2. Click "Create a project"
3. Name: "Aafnai Karesabari"
4. Enable Google Analytics (optional)
5. Click "Create project" and wait 3 minutes
```

**✅ Note your Project ID** (shown on next screen)

---

## ⏱️ 5 MIN: Configure Authentication

```
1. Firebase Console → "Authentication"
2. Click "Get started" → "Sign-in method" tab
3. Enable "Email/Password" → Save
4. Enable "Phone" → Save
```

**✅ Done!** Users can now register.

---

## ⏱️ 5 MIN: Create Firestore Database

```
1. Firebase Console → "Firestore Database"
2. Click "Create database"
3. Location: "Asia Southeast 1" (for Nepal)
4. Security: Choose "Start in production mode"
5. Click "Create"
6. Wait 2 minutes for initialization
```

**✅ Database created!**

---

## ⏱️ 10 MIN: Deploy Security Rules

```bash
# In your project folder:
cd "D:/FINAL YEAR PROJECT/Aafnai Karesabari/aafnai_karesabari"

# Copy firestore rules file
copy firestore.rules rules.txt

# Go to Firebase Console → Firestore → "Rules" tab
# Copy all text from rules.txt
# Paste into Firebase Console Rules editor
# Click "Publish"
```

**✅ Security rules deployed!**

---

## ⏱️ 5 MIN: Get Firebase Config

### For Android:
```
1. Firebase Console → "Project Settings" (gear icon)
2. Click "Android"
3. Click "Add app" if no Android app exists
   Package name: com.example.aafnai_karesabari
   Click "Register"
4. Download google-services.json
5. Move to: android/app/google-services.json
```

### For iOS:
```
1. Firebase Console → "Project Settings" → "iOS"
2. Click "Add app" if no iOS app exists
   Bundle ID: com.example.aafnaiKaresabari
   Click "Register"
3. Download GoogleService-Info.plist
4. Move to: ios/Runner/GoogleService-Info.plist
```

**✅ Config files in place!**

---

## ⏱️ 5 MIN: Run FlutterFire Config

```bash
# Activate CLI (one-time)
dart pub global activate flutterfire_cli

# Configure project
flutterfire configure

# Select:
# - Your Firebase project
# - Platforms: Android, iOS, Web
```

**✅ Firebase connected to Flutter!**

---

## ⏱️ CREATE ADMIN ACCOUNT

```
1. Firebase Console → "Authentication" → "Users"
2. Click "Create user"
   Email: admin@aafnai.com
   Password: (strong password)
3. Click "Create"
4. Copy the UID (click user, see "User UID")

5. Go to Firestore → Collections
6. Create new collection: "admin_users"
7. Add document with ID = (the UID you copied)
   Fields:
   - role: "admin"
   - email: "admin@aafnai.com"
   - created_at: (current time)
8. Click "Save"
```

**✅ Admin account created!**

---

## ✅ RUN THE APP

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run on device/emulator
flutter run

# Or specific platform
flutter run -d android
flutter run -d ios
```

**You should see the app start!**

---

## 🧪 TEST THE APP

### 1. Register as Buyer
- Click "Sign up"
- Enter email + password
- Select "Buyer" role
- Complete profile
- See home screen ✅

### 2. Register as Seller
- Click "Sign up"
- Enter email + password
- Select "Seller" role
- Complete profile
- **WAIT** - Admin must approve

### 3. Login as Admin
- Click "Log in"
- Email: `admin@aafnai.com`
- Password: (the one you set)
- Should see "Admin Dashboard" tab ✅

### 4. Approve Seller
- Go to Admin Dashboard
- See pending seller
- Click "Approve" ✅

### 5. Create Listing (as seller)
- Logout, login as seller
- Go to "Seller" tab → "Listings"
- Click "Add Listing"
- Fill: name, price, quantity, location
- Click "Create" ✅

### 6. Buy Product (as buyer)
- Logout, login as buyer
- See listing on home screen
- Click it → "Add to basket"
- Go to cart → "Checkout"
- Place order ✅

### 7. Complete Order (as seller)
- Logout, login as seller
- Go to "Orders" tab
- Accept order
- Mark as completed ✅

### 8. Leave Review (as buyer)
- Logout, login as buyer
- Go to "Orders" tab
- View completed order
- Go back to product
- Scroll down → "Add review"
- Rate 5 stars + comment
- Submit ✅

---

## 📊 VERIFY DATA IN FIREBASE

```
1. Firebase Console → "Firestore" tab
2. Check collections:
   ✅ users/         (registered accounts)
   ✅ listings/      (products created)
   ✅ orders/        (purchases made)
   ✅ reviews/       (ratings & reviews)
   ✅ admin_users/   (admin account)
```

---

## ✨ YOU'RE DONE! 

### Summary of what's ready:
- ✅ User authentication (buyer + seller + admin)
- ✅ Seller listings (create/edit/delete)
- ✅ Buyer shopping (search/cart/checkout)
- ✅ Order management (accept/reject/complete)
- ✅ Ratings & reviews (5-star system)
- ✅ Firestore security (rules enforced)
- ✅ Admin dashboard (approve sellers)

---

## 📈 NEXT STEPS

### Ready to Deploy:
1. Read **DEPLOYMENT_CHECKLIST.md** (before App Store upload)
2. Build release APK: `flutter build apk --release`
3. Build release IPA: `flutter build ipa --release`
4. Upload to Google Play & Apple App Store

### Need Help:
- **Detailed Firebase setup:** See `FIREBASE_SETUP_GUIDE.md`
- **Admin operations:** See `ADMIN_OPERATIONS_GUIDE.md`
- **Deployment steps:** See `DEPLOYMENT_CHECKLIST.md`

---

## 🆘 TROUBLESHOOTING (3 Common Issues)

### Issue: "Permission denied" error when using app
```
Solution: Go to Firebase Console → Firestore → Rules
Make sure the rules are PUBLISHED (green check mark)
Click "Publish" again if needed
```

### Issue: Admin dashboard not showing
```
Solution: 
1. Make sure you created admin_users collection
2. Make sure your user UID is in admin_users
3. Logout and login again
```

### Issue: Can't register or login
```
Solution:
1. Go to Firebase → Authentication
2. Check that Email/Password is ENABLED
3. Refresh app and try again
```

---

**🎉 Congratulations! Your marketplace is live! 🎉**

**Time elapsed:** ~30 minutes  
**Status:** Production Ready  
**Next:** Deploy to App Store/Play Store  

Questions? Check the detailed guides:
- `FIREBASE_SETUP_GUIDE.md` (detailed Firebase setup)
- `ADMIN_OPERATIONS_GUIDE.md` (how to manage platform)
- `DEPLOYMENT_CHECKLIST.md` (before going live)
