# 👨‍💼 Admin Operations Guide - Aafnai Karesabari

**Complete guide for admin to manage the platform after Firebase setup.**

---

## 🔐 STEP 1: Admin Login

### 1.1 First-Time Admin Setup
1. **Create admin account in Firebase:**
   - Go to Firebase Console → **Authentication** → **Users**
   - Click **"Create user"**
   - Email: `admin@aafnai.com` (change to your email)
   - Password: Strong password (min 6 chars)
   - Click **"Create"**

2. **Grant admin role in Firestore:**
   - Go to **Firestore** → Create new collection: `admin_users`
   - Click **"Add document"**
   - Document ID: Copy the UID from the admin user you just created
     - (Find in Authentication → Users table, click the user, copy the UID)
   - Add fields:
     ```
     role: "admin"
     email: "admin@aafnai.com"
     created_at: (current timestamp)
     permissions: ["manage_sellers", "manage_listings", "view_analytics"]
     ```
   - Click **"Save"**

3. **Verify in security rules:**
   - Check `firestore.rules` includes admin check
   - Should have: `path(['admin_users', request.auth.uid])`

### 1.2 Login to App
1. Open the app (run `flutter run`)
2. Click **"Sign up"** or **"Log in"**
3. Enter admin email + password
4. After profile setup, admin dashboard should appear
5. You should see: **"Admin Dashboard"** in navigation

---

## 📊 STEP 2: Admin Dashboard Overview

### 2.1 What Admin Can Do
Located in: `lib/features/admin/dashboard/admin_dashboard_screen.dart`

**Current Admin Features:**
- ✅ View seller applications (pending approval)
- ✅ Approve/reject sellers
- ✅ View platform statistics
- ✅ View all orders (monitoring)
- ✅ Access analytics (future)

### 2.2 Access Admin Panel
1. Login as admin
2. Bottom navigation shows **"Admin"** tab
3. Click it to open admin dashboard

---

## 👥 STEP 3: Manage Sellers (Most Important)

### 3.1 Seller Approval Workflow

**Sellers register with status = "pending"**

To approve sellers:
1. Open **Admin Dashboard** → **"Seller Applications"** tab
2. See list of pending sellers with:
   - Business name
   - Email
   - Phone
   - Location
   - Status badge (PENDING)

3. Click **"Approve"** button:
   - Updates `seller_status` to "approved" in Firestore
   - Seller can now create listings
   - Seller notification sent (if notifications enabled)

4. Click **"Reject"** button:
   - Updates `seller_status` to "rejected"
   - Seller locked out of seller features
   - Rejection reason shown to seller (optional)

### 3.2 View All Sellers
**Current Status:** Feature in admin_dashboard_screen.dart

```
- Go to Admin Dashboard
- Click "All Sellers" section
- See each seller's:
  - Name, email, phone
  - Status (pending/approved/rejected)
  - Date registered
  - Total listings count
  - Total orders count
```

### 3.3 Manually Change Seller Status (If Needed)
**Via Firebase Console** (if app UI not ready):
1. Go to Firestore → **users** collection
2. Find user with `role: "seller"`
3. Edit field: `seller_status: "approved"` or `"rejected"`
4. Changes take effect immediately

---

## 📦 STEP 4: Monitor Orders & Transactions

### 4.1 View All Orders
**In Admin Dashboard:**
1. Click **"Orders"** section
2. See all orders in system with:
   - Order ID
   - Buyer name
   - Seller name
   - Status (pending/accepted/completed/rejected)
   - Amount
   - Date

3. Click order to see details:
   - Product info
   - Quantity ordered
   - Price breakdown
   - Status timeline

### 4.2 Commission Tracking
**Current Status:** Automatic via OrderStatus logic

- Order created → Commission calculated
- Order completed → Commission credited
- View in: Seller → Earnings screen

**Manual Audit:**
1. Firestore → **orders** collection
2. Each order has:
   - `commission_amount` (auto-calculated)
   - `farmer_payout` (amount after commission)
   - `status` (for tracking)

---

## 🏪 STEP 5: Manage Listings

### 5.1 View All Listings
**Via Firebase Console** (no UI for this yet):
1. Go to Firestore → **listings** collection
2. See all active listings
3. Filter by:
   - `farmer_id` (seller)
   - `status` (active/inactive)
   - `category` (vegetable/fruit/grain)

### 5.2 Remove Problematic Listings
**If listing violates policy:**
1. Go to Firestore → **listings** → find document
2. Options:
   - **Option A:** Update `status: "inactive"` (soft delete)
   - **Option B:** Delete document entirely (hard delete)
   - **Option C:** Add `flagged_reason: "spam"` field

3. Notify seller via email (manual for now)

### 5.3 Check Listing Inventory
**Current:** Seller manages via app

To monitor stock levels:
1. Firestore → **listings** collection
2. Check `quantity` field for each listing
3. Filter by `quantity == 0` to find out-of-stock items

---

## ⭐ STEP 6: Monitor Reviews & Quality

### 6.1 View All Reviews
**Via Firebase Console:**
1. Go to Firestore → **reviews** collection
2. See all reviews with:
   - Rating (1-5 stars)
   - Comment
   - Farmer ID (which seller)
   - Consumer ID (which buyer)
   - Date

### 6.2 Remove Inappropriate Reviews
**If review violates policy:**
1. Find review in Firestore → **reviews**
2. Delete the document
3. Notify buyer/seller (optional)

### 6.3 Analytics
**To check seller ratings:**
1. Go to Firestore → **reviews** collection
2. Filter by `farmer_id: "seller-uid"`
3. Calculate average rating:
   - Sum all ratings
   - Divide by review count
   - This is seller's average rating

---

## 💰 STEP 7: Financial Management

### 7.1 View Platform Revenue
**Commission Tracking:**
1. Firestore → **orders** collection
2. For each completed order:
   - `commission_amount` = platform revenue
   - Sum all completed order commissions

**Example Report:**
```
Total Orders: 150
Completed: 120
Commission Rate: 10%
Total Platform Revenue: 50,000 NPR

Seller A: 20 completed orders × 1000 NPR × 90% = 18,000 NPR
Seller B: 15 completed orders × 2000 NPR × 90% = 27,000 NPR
```

### 7.2 Payout Management
**Current Status:** Manual process

To payout sellers:
1. Go to admin console (future feature)
2. See `farmer_payout` amounts for each seller
3. Mark as "paid" in Firestore
4. Process payment via bank transfer

---

## 📱 STEP 8: Troubleshooting Admin Access

### Issue: Admin role not working
**Solution:**
1. Verify `admin_users` collection exists in Firestore
2. Verify your UID is in admin_users collection
3. Check security rules include admin check:
   ```
   // firestore.rules should have:
   function isAdmin() {
     return exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
   }
   ```
4. If rules changed, click **"Publish"** in Firestore Rules tab

### Issue: Can't see seller applications
**Solution:**
1. Go to Firestore → **users** collection
2. Filter: `role == "seller"` AND `seller_status == "pending"`
3. If none show, no sellers registered yet
4. Test by registering as seller first

### Issue: Approve button not working
**Solution:**
1. Check Firestore rules allow admin to update users
2. Try manually updating in Firestore console:
   - Find user document
   - Change `seller_status: "pending"` → `"approved"`
   - Click "Save"
3. If manual works but button doesn't, check app logs for errors

---

## 📋 STEP 9: Daily Admin Checklist

### Morning
- [ ] Check new seller applications
- [ ] Approve/reject as needed
- [ ] Check for flagged orders or reviews

### Throughout Day
- [ ] Monitor order flow (new orders, completions)
- [ ] Answer seller support requests
- [ ] Check for platform issues

### Weekly
- [ ] Review seller performance
- [ ] Check commission payouts
- [ ] Monitor buyer feedback
- [ ] Generate revenue report

### Monthly
- [ ] Review platform statistics
- [ ] Process seller payouts
- [ ] Plan promotions/discounts
- [ ] Update market prices if needed

---

## 🔧 STEP 10: Advanced Admin Tasks

### 10.1 Create Test Users
For QA/testing, create accounts:
1. Firebase Console → **Authentication** → **Users**
2. Click **"Create user"** for each:
   - **Test Seller:** `seller@test.com` / password
   - **Test Buyer:** `buyer@test.com` / password
   - **Test Admin:** `admin@test.com` / password

3. In Firestore, set their roles:
   - For sellers: Add `seller_status: "approved"`
   - For admins: Add to `admin_users` collection

### 10.2 Bulk Data Operations
**Export orders for reporting:**
1. Firestore → **orders** collection
2. Click ⋮ (three dots) → **"Export collection"**
3. Download as JSON/CSV
4. Use Excel/Google Sheets for analysis

### 10.3 Security Audit
**Monthly, check:**
1. Authentication → **Users**: Look for suspicious accounts
2. Firestore → **Rules** tab: Verify rules are still active
3. Storage → **Rules** tab: Verify storage rules are active
4. Activity log in Firebase Console for unusual activity

---

## 📞 STEP 11: Key Firestore Collections Reference

```
admins/
├── {uid}
│   ├── email: string
│   ├── role: "admin"
│   └── permissions: array

users/
├── {uid}
│   ├── email: string
│   ├── phone: string
│   ├── name: string
│   ├── role: "seller" | "buyer"
│   ├── seller_status: "pending" | "approved" | "rejected"
│   └── created_at: timestamp

listings/
├── {id}
│   ├── farmer_id: string
│   ├── product_name: string
│   ├── price_per_unit: number
│   ├── quantity: number
│   ├── status: "active" | "inactive"
│   └── category: string

orders/
├── {id}
│   ├── consumer_id: string
│   ├── farmer_id: string
│   ├── listing_id: string
│   ├── quantity: number
│   ├── total_price: number
│   ├── commission_amount: number (auto)
│   ├── farmer_payout: number (auto)
│   ├── status: "pending" | "accepted" | "completed"
│   └── created_at: timestamp

reviews/
├── {id}
│   ├── order_id: string
│   ├── consumer_id: string
│   ├── farmer_id: string
│   ├── rating: number (1-5)
│   ├── comment: string
│   └── created_at: timestamp

notifications/
├── {id}
│   ├── user_id: string
│   ├── title: string
│   ├── message: string
│   ├── type: string
│   ├── read: boolean
│   └── created_at: timestamp
```

---

## ✨ QUICK START FOR ADMIN

```
1. Follow Firebase Setup Guide steps 1-13
2. Create admin account (email + password)
3. Add admin UID to admin_users collection
4. Login to app with admin email
5. Go to Admin Dashboard
6. Approve first seller application
7. Test by registering as seller + buyer
8. Place test order and leave review
9. Check all data in Firestore Console
10. Ready to launch!
```

---

**Questions? Check FIREBASE_SETUP_GUIDE.md for detailed setup instructions.**

**Ready to manage the platform! 🚀**
