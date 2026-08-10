# 🚀 Pre-Launch Deployment Checklist

**Complete checklist before launching to production.**

---

## ✅ FIREBASE CONFIGURATION (Complete First)

### Backend Setup
- [ ] Firebase project created on console.firebase.google.com
- [ ] Authentication enabled (Email + Phone)
- [ ] Firestore database created (Production mode)
- [ ] Cloud Storage configured
- [ ] Security rules deployed and published
- [ ] Admin account created and verified
- [ ] `google-services.json` placed in `android/app/`
- [ ] `GoogleService-Info.plist` placed in `ios/Runner/`
- [ ] `flutterfire configure` run successfully
- [ ] Firebase emulator tested (optional)

**Estimated Time:** 1-2 hours

---

## ✅ APP CONFIGURATION

### Version & Build
- [ ] Update `pubspec.yaml` version to `1.0.0`
- [ ] Update `pubspec.yaml` build number
- [ ] Check app name in `pubspec.yaml`: "Aafnai Karesabari"

### Android Build
- [ ] `android/app/build.gradle` updated:
  - [ ] `applicationId` set to unique package name
  - [ ] `minSdkVersion` ≥ 21
  - [ ] `compileSdkVersion` ≥ 33
- [ ] Generate release signing key:
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10950
  ```
- [ ] Store keystore file safely (backup!)
- [ ] `android/key.properties` created with keystore info
- [ ] Run test build: `flutter build apk --release`

### iOS Build
- [ ] Update `ios/Runner.xcodeproj` bundle identifier
- [ ] Set deployment target to iOS 11.0+
- [ ] Register app on Apple Developer account
- [ ] Create App Store Connect entry
- [ ] Generate provisioning profiles
- [ ] Run test build: `flutter build ipa --release`

### App Icons & Branding
- [ ] App icon (192x192) placed in correct locations
- [ ] Splash screen configured with logo
- [ ] App name displayed correctly on home screen
- [ ] Color scheme matches brand guidelines
- [ ] Typography is consistent

---

## ✅ FUNCTIONALITY TESTING

### User Flows
- [ ] **Buyer Flow:**
  - [ ] Register account (email + password)
  - [ ] Complete buyer profile
  - [ ] Browse home screen categories
  - [ ] Search for products
  - [ ] View product details
  - [ ] Add to wishlist
  - [ ] Add to cart
  - [ ] Checkout successfully
  - [ ] View order confirmation
  - [ ] Track order status
  - [ ] Leave review with rating

- [ ] **Seller Flow:**
  - [ ] Register account
  - [ ] Complete seller profile
  - [ ] Wait for admin approval (or test manual approval)
  - [ ] Create first listing
  - [ ] Edit listing
  - [ ] Update inventory stock
  - [ ] View orders received
  - [ ] Accept/reject orders
  - [ ] Mark orders as completed
  - [ ] View earnings dashboard
  - [ ] See ratings from reviews

- [ ] **Admin Flow:**
  - [ ] Login to admin account
  - [ ] Access admin dashboard
  - [ ] Approve pending sellers
  - [ ] View all orders
  - [ ] Monitor platform metrics
  - [ ] Check seller applications

### Edge Cases
- [ ] Empty cart checkout (should prevent)
- [ ] Out of stock product (should disable button)
- [ ] Review with 0 quantity order (should fail)
- [ ] Duplicate review same order (should prevent)
- [ ] Seller can't edit other seller's listings
- [ ] Buyer can't change order status
- [ ] Admin can't be locked out

### Performance
- [ ] [ ] App loads home screen in < 3 seconds
- [ ] [ ] Product search responds in < 2 seconds
- [ ] [ ] No crashes or freezes during normal usage
- [ ] [ ] Images load without delay
- [ ] [ ] Cart operations are instant
- [ ] [ ] Run: `flutter test` - all 29 tests pass ✅

---

## ✅ SECURITY VERIFICATION

### Authentication
- [ ] Firebase Auth active and working
- [ ] OTP verification implemented
- [ ] Email verification enforced (if desired)
- [ ] Session tokens secure (no localStorage)
- [ ] Password requirements enforced (min 6 chars)

### Data Security
- [ ] Firestore rules deployed and published
- [ ] Rules prevent unauthorized reads/writes
- [ ] Seller can't modify other sellers' data
- [ ] Buyer can't modify orders
- [ ] Admin access controlled via admin_users collection
- [ ] No sensitive data logged in console

### Storage Security
- [ ] Cloud Storage rules deployed
- [ ] Only authenticated users can upload
- [ ] File deletion authorized
- [ ] No malicious uploads possible

### API Security
- [ ] No API keys exposed in code
- [ ] No hardcoded secrets in git
- [ ] Environment variables used for config
- [ ] CORS headers correctly set

---

## ✅ DATA & CONTENT

### Initial Data
- [ ] Sample listings created (for demo)
- [ ] Market prices initialized
- [ ] Test seller accounts created
- [ ] Test buyer accounts created
- [ ] Sample reviews added (optional)

### Content Review
- [ ] Privacy Policy written and linked
- [ ] Terms of Service written and linked
- [ ] Contact/Support info added
- [ ] About page has accurate info
- [ ] All text is spellchecked

---

## ✅ MONITORING & LOGGING

### Firebase Setup
- [ ] Cloud Logging enabled (logs tab in Firebase Console)
- [ ] Error tracking configured
- [ ] Crash analytics enabled
- [ ] Performance monitoring enabled (optional)

### Debugging
- [ ] Release builds tested on real device
- [ ] Logcat output checked for errors (Android)
- [ ] Console checked for exceptions (iOS)
- [ ] Network tab in Chrome DevTools checked (Web)

---

## ✅ DOCUMENTATION

### For Users
- [ ] **Help/FAQ page** created
- [ ] **Tutorial** shown on first login
- [ ] **Onboarding flow** clear and simple
- [ ] **Error messages** are user-friendly

### For Admins
- [ ] **ADMIN_OPERATIONS_GUIDE.md** complete ✅
- [ ] **FIREBASE_SETUP_GUIDE.md** complete ✅
- [ ] **README.md** has setup instructions
- [ ] **DEPLOYMENT_CHECKLIST.md** this file ✅

### For Developers
- [ ] **Code comments** on complex logic
- [ ] **Architecture documented** in README
- [ ] **API endpoints documented** (if applicable)
- [ ] **Database schema documented**

---

## ✅ LEGAL & COMPLIANCE

### Platform Requirements
- [ ] Terms of Service approved by legal
- [ ] Privacy Policy covers GDPR (if applicable)
- [ ] Data retention policy defined
- [ ] Right to be forgotten implemented
- [ ] Age restriction set (if applicable)

### Nepal-Specific
- [ ] Business registration complete
- [ ] Tax ID (PAN) for marketplace
- [ ] GST registration (if applicable)
- [ ] Payment gateway compliant with NRB guidelines

---

## ✅ DEPLOYMENT STEPS

### Android Play Store
1. [ ] Create Google Play Developer account ($25 one-time)
2. [ ] Create app listing with:
   - [ ] App name
   - [ ] Description (500 chars)
   - [ ] Screenshots (5 minimum)
   - [ ] Feature graphics
   - [ ] Icon (512x512)
3. [ ] Upload APK/AAB file
4. [ ] Set pricing (Free)
5. [ ] Select target countries
6. [ ] Submit for review (takes 2-24 hours)
7. [ ] Launch to production

### Apple App Store
1. [ ] Create Apple Developer account ($99/year)
2. [ ] Create app record in App Store Connect
3. [ ] Create app listing with:
   - [ ] App name
   - [ ] Description
   - [ ] Screenshots (6.5" iPhone required)
   - [ ] Preview video (optional)
   - [ ] Support URL
4. [ ] Upload .ipa file via Xcode
5. [ ] Set build version and number
6. [ ] Add export compliance info
7. [ ] Submit for review (takes 1-3 days)
8. [ ] Launch to production

### Web (Firebase Hosting)
```bash
firebase deploy --only hosting
```
- [ ] Domain configured (if custom)
- [ ] SSL certificate active
- [ ] CDN caching configured

---

## ✅ POST-LAUNCH

### Day 1-2: Monitoring
- [ ] Monitor Firebase console for errors
- [ ] Check crash analytics
- [ ] Monitor user registration rate
- [ ] Verify payment processing
- [ ] Monitor server load

### Week 1: Stability
- [ ] Fix any critical bugs immediately
- [ ] Monitor app reviews and ratings
- [ ] Collect user feedback
- [ ] Fix common issues
- [ ] Optimize performance if needed

### Week 2-4: Growth
- [ ] Plan marketing campaign
- [ ] Encourage early user reviews
- [ ] Onboard first sellers
- [ ] Process early transactions
- [ ] Monitor metrics

---

## 📊 LAUNCH APPROVAL SIGN-OFF

**Project Name:** Aafnai Karesabari  
**Version:** 1.0.0  
**Date:** ___________

**Checklist Status:**
- Coding: ✅ COMPLETE
- Testing: ✅ 29/29 PASSING
- Firebase Setup: ⬜ IN PROGRESS (Follow FIREBASE_SETUP_GUIDE.md)
- Documentation: ✅ COMPLETE
- Security: ⬜ IN PROGRESS (Follow checklist)
- Deployment: ⬜ IN PROGRESS (Follow steps)

**Ready to Launch?**
- [ ] YES - All checks complete
- [ ] NO - Needs more work (list issues below)

**Issues to Fix Before Launch:**
```
(List any blockers here)
```

---

## 🎯 SUCCESS CRITERIA

✅ App launches without crashes  
✅ Users can register and login  
✅ Sellers can create listings  
✅ Buyers can purchase  
✅ Reviews can be posted  
✅ Admin can approve sellers  
✅ All tests passing  
✅ No Firebase security errors  

**You're ready to launch! 🚀**
