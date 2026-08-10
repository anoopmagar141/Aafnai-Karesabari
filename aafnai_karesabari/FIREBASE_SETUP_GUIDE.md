# 🔥 Firebase Setup Guide - Aafnai Karesabari

**This guide walks through complete Firebase configuration for production deployment.**

---

## ✅ STEP 1: Create Firebase Project

### 1.1 Go to Firebase Console
1. Visit: https://console.firebase.google.com/
2. Click **"Create a project"**
3. Enter project name: `Aafnai Karesabari` (or your choice)
4. Accept terms and click **"Continue"**
5. Enable Google Analytics (optional, recommended for tracking)
6. Click **"Create project"** and wait 2-3 minutes

### 1.2 Verify Project Created
- You should see your project in the Firebase Console
- Note the **Project ID** (shown in project settings)

---

## ✅ STEP 2: Configure Authentication (Email/Phone)

### 2.1 Enable Email Authentication
1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click **"Get started"** → **"Sign-in method"** tab
3. Enable **Email/Password**:
   - Click **Email/Password** provider
   - Toggle **Enable** → **Save**
4. Enable **Phone** (for OTP):
   - Click **Phone** provider
   - Toggle **Enable** → **Save**

### 2.2 Configure OAuth (Optional, for Social Login)
- Skip for now - can add Google sign-in later

---

## ✅ STEP 3: Set Up Firestore Database

### 3.1 Create Firestore Database
1. Go to **Firestore Database** (left sidebar)
2. Click **"Create database"**
3. Choose **Location**: Select closest to your region
   - For Nepal: Asia Southeast 1 (Singapore) recommended
4. Choose **Security Rules**: **Start in production mode** (we'll configure rules next)
5. Click **"Create"** and wait for initialization

### 3.2 Verify Database Created
- You should see an empty Firestore console with Collections panel

---

## ✅ STEP 4: Deploy Firestore Security Rules

### 4.1 View Current Rules
1. In Firestore, click **"Rules"** tab (top)
2. You'll see default rules

### 4.2 Replace with App Rules
1. Copy ALL text from: `firestore.rules` (in project root)
2. Paste into Firebase Console **Rules** tab
3. Click **"Publish"**
4. Wait for "Rules updated successfully" message

**Rules Include:**
- ✅ Seller listings: Only owner can create/edit/delete
- ✅ Orders: Only consumer/seller can view their own
- ✅ Reviews: Only consumer can review completed orders
- ✅ Public read: Listings visible to all
- ✅ Admin access: Full permissions

---

## ✅ STEP 5: Configure Storage (Image Upload)

### 5.1 Enable Cloud Storage
1. Go to **Storage** (left sidebar)
2. Click **"Get started"**
3. Choose **Location**: Same as Firestore (Asia Southeast 1)
4. Click **"Done"**

### 5.2 Deploy Storage Security Rules
1. Click **"Rules"** tab
2. Replace with:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Public read
    match /listings/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
      allow delete: if request.auth != null && 
        resource.metadata.uploadedBy == request.auth.uid;
    }
    
    // Authenticated uploads only
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```
3. Click **"Publish"**

---

## ✅ STEP 6: Configure App Registration

### 6.1 Get Firebase Config (Android)
1. Go to **Project Settings** (gear icon, top right)
2. Click **"Android"** under "Your apps"
3. If no Android app exists:
   - Click **"Add app"** → **Android**
   - Package name: `com.example.aafnai_karesabari`
   - App nickname: `Aafnai Karesabari Android`
   - SHA-1 certificate: Get from terminal:
     ```bash
     cd "D:/FINAL YEAR PROJECT/Aafnai Karesabari/aafnai_karesabari"
     flutter pub get
     # For debug signing:
     keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
     # Copy the SHA1 fingerprint
     ```
   - Click **"Register app"**
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

### 6.2 Get Firebase Config (iOS)
1. Go to **Project Settings** → Click **"iOS"**
2. If no iOS app exists:
   - Click **"Add app"** → **iOS**
   - Bundle ID: `com.example.aafnaiKaresabari`
   - App nickname: `Aafnai Karesabari iOS`
   - Click **"Register app"**
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`
5. In Xcode (if available): Right-click **Runner** → Add Files → Select the plist

### 6.3 Get Firebase Config (Web)
1. Go to **Project Settings** → Click **"Web"**
2. If no web app exists:
   - Click **"Add app"** → **Web**
   - App nickname: `Aafnai Karesabari Web`
   - Click **"Register app"**
3. Copy the Firebase config object shown
4. It's already in: `lib/firebase_options.dart` (from `flutterfire_cli`)

---

## ✅ STEP 7: Initialize Firebase Config in Flutter

### 7.1 Run FlutterFire CLI (One-time setup)
```bash
cd "D:/FINAL YEAR PROJECT/Aafnai Karesabari/aafnai_karesabari"
dart pub global activate flutterfire_cli
flutterfire configure
```

This will:
- Detect your Firebase project
- Auto-generate `firebase_options.dart`
- Ask which platforms (Android/iOS/Web)
- Select all three

### 7.2 Verify Configuration
- Check: `lib/firebase_options.dart` has your project credentials
- Check: `android/app/google-services.json` exists
- Check: `ios/Runner/GoogleService-Info.plist` exists

---

## ✅ STEP 8: Create Admin Account

### 8.1 Enable Email Provider
1. In **Authentication**, go to **Sign-in method** tab
2. Ensure **Email/Password** is enabled (should be from Step 2)

### 8.2 Create Admin User via Console
1. Go to **Authentication** → **Users** tab
2. Click **"Create user"** (or **"Add user"**)
3. Enter:
   - Email: `admin@aafnai.com` (use your email)
   - Password: Use strong password (min 6 chars)
   - Click **"Create"**

### 8.3 Set Admin Claims (Optional, for Admin Dashboard)
This requires Firebase CLI. Run in terminal:
```bash
npm install -g firebase-tools
firebase login
firebase auth:import --hash-algo=scrypt --rounds=8 --mem-cost=14 <project-id>
```

Or manually in Firestore, create `/admins/{uid}` document with admin data.

---

## ✅ STEP 9: Initialize Sample Data

### 9.1 Create Market Prices (Optional)
1. Go to Firestore → Create collection: `market_prices`
2. Add sample documents:
   ```
   {
     "product_name": "Tomato",
     "region": "Lalitpur",
     "price_min": 40,
     "price_max": 60,
     "unit": "kg",
     "updated_at": <current-timestamp>
   }
   ```

### 9.2 Create Notifications (Optional)
1. Create collection: `notifications`
2. Leave empty - will auto-populate as users interact

---

## ✅ STEP 10: Test Firebase Connection

### 10.1 Run the App
```bash
cd "D:/FINAL YEAR PROJECT/Aafnai Karesabari/aafnai_karesabari"
flutter clean
flutter pub get
flutter run
```

### 10.2 Test Authentication
1. **Register as Buyer:**
   - Click "Sign up"
   - Enter email & password
   - Complete profile setup
   - Should see consumer home screen

2. **Register as Seller:**
   - Click "Sign up"
   - Select "Seller" role
   - Complete seller profile (business name, location, etc.)
   - Should see seller dashboard
   - **Admin must approve** (in Firebase or admin panel)

3. **Verify in Firebase Console:**
   - Go to **Authentication** → **Users**
   - See all registered users
   - Go to **Firestore** → Check `users` collection
   - See user profiles with `role` field

---

## ✅ STEP 11: Enable Admin Account

### 11.1 Option A: Use Security Rules (Recommended)
1. Add to `firestore.rules`:
```
// Admin check
function isAdmin() {
  return exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
}
```

2. Create in Firestore: `admin_users` collection
3. Add document with your UID (from Authentication):
   - Document ID: `<your-uid>`
   - Fields: `role: "admin"`, `created_at: <timestamp>`

### 11.2 Option B: Manual Firebase Console
1. Go to **Project Settings** → **Service Accounts**
2. Click **"Generate new private key"**
3. Use this key to manually set custom claims (advanced)

### 11.3 Login as Admin
1. Run the app
2. Login with admin email/password
3. You should see admin dashboard (if role is set)

---

## ✅ STEP 12: Deploy Firestore Rules to Production

### 12.1 Verify Rules Are Correct
1. In Firestore Console → **Rules** tab
2. Check that rules file shows complete security rules
3. Rules should have checks for:
   - `auth.uid == resource.data.user_id`
   - `auth.token.email_verified == true`
   - `request.auth != null`

### 12.2 Publish Rules
1. Click **"Publish"**
2. Wait for "Rules updated successfully"
3. Rules now live on production Firebase

**⚠️ WARNING:** Once published, app MUST authenticate before accessing Firestore!

---

## ✅ STEP 13: Production Deployment Checklist

### Before Going Live:
- [ ] Firebase project created
- [ ] Authentication enabled (Email + Phone)
- [ ] Firestore database created
- [ ] Security rules deployed
- [ ] Storage configured
- [ ] `google-services.json` in Android
- [ ] `GoogleService-Info.plist` in iOS
- [ ] Admin account created
- [ ] App tested on device
- [ ] All tests passing (`flutter test`)

### Deploy to Stores:
- [ ] Update `pubspec.yaml` version to 1.0.0
- [ ] Update app icon and name
- [ ] Create release builds:
  ```bash
  flutter build apk --release
  flutter build ipa --release
  ```
- [ ] Sign builds with production keys
- [ ] Upload to Google Play Store & Apple App Store

---

## 🆘 TROUBLESHOOTING

### Issue: "Permission denied" in Firestore
**Solution:** Check security rules are published. Go to **Rules** tab and verify text is there and published.

### Issue: "App not registered" error
**Solution:** Run `flutterfire configure` again or manually add `google-services.json`.

### Issue: Images not uploading
**Solution:** Check Storage rules are published. Go to **Storage** → **Rules** tab.

### Issue: Can't login as seller
**Solution:** Check if seller needs approval. In Firestore `users/{uid}`, verify `seller_status` field exists.

### Issue: Firebase console shows no data
**Solution:** Make sure you're in correct project (check project dropdown, top-left).

---

## 📞 SUPPORT

**Firebase Documentation:** https://firebase.google.com/docs
**Flutter Firebase Plugin:** https://firebase.flutter.dev/
**Security Rules Guide:** https://firebase.google.com/docs/rules

---

## ✨ NEXT STEPS

1. ✅ Follow Steps 1-13 above
2. ✅ Test login with buyer + seller accounts
3. ✅ Create test listing as seller
4. ✅ Purchase as buyer, leave review
5. ✅ Verify data in Firestore Console
6. ✅ Deploy to App Store/Play Store

**You're ready to launch! 🚀**
