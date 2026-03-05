# Privacy Policy – Siffersafari

**Last Updated:** March 5, 2026

## Overview

Siffersafari is a mathematics game app designed for children ages 6–12. This Privacy Policy explains how we handle data when you use our app.

**Important:** We do NOT collect, use, or disclose personal information from children or their parents. All gameplay data is stored locally on your device.

## Data We Collect

We collect **NO personal information** such as:
- ❌ Child's name, email, address, or phone number
- ❌ Parent's contact information
- ❌ Photos, videos, or audio recordings
- ❌ Location data (GPS, address)
- ❌ Persistent device identifiers (fingerprinting, cross-device tracking)

## Data We Store Locally

The following information is stored **only on your device** using encrypted local storage:

| Data Type | Purpose | Stored Where |
|-----------|---------|--------------|
| Child profile name | Identify user in app | Device storage (Hive) |
| Quiz scores & results | Track learning progress | Device storage (Hive) |
| Progress (operation unlocks) | Unlock new difficulty levels | Device storage (Hive) |
| Parent PIN (hashed) | Parent access control | Device storage (Hive), encrypted with BCrypt |
| Session history | Cumulative statistics | Device storage (Hive) |

**All data remains on your device.** We do NOT sync data to our servers.

## Data NOT Collected

- ❌ **No Server Uploads:** Your child's data never leaves your device
- ❌ **No Analytics:** We don't use Google Analytics, Firebase, Mixpanel, or similar services
- ❌ **No Advertising:** The app contains no ads, ad networks, or behavioral advertising
- ❌ **No Tracking:** We don't track your child across apps or websites
- ❌ **No Third-Party Data Sharing:** We share data with no external companies

## How You Control Your Data

### Delete a Child's Profile
1. Open Siffersafari app
2. Go to **Settings** (gear icon)
3. Select the child's profile
4. Tap **Delete Profile**
5. Confirm deletion

Profile data (quizzes, progress) is permanently deleted from the device.

### Clear All Data
1. Open Siffersafari app
2. Go to **Settings** → **Advanced**
3. Tap **Clear All Data**
4. Confirm deletion

All profiles, scores, and settings are erased. This cannot be undone.

### Access Your Data
All stored data is on YOUR device. To view or export:
- Open the app storage folder on your Android/iOS device
- Access backup files directly (technical users: Hive box files are in app cache)

## Data Security

Your data is protected by:
- **Local Encryption:** Parent PINs are hashed using BCrypt (not stored in plain text)
- **Device Storage:** Data stored in Hive encrypted box on your device
- **No Network Transmission:** No encryption needed since data never leaves your device
- **No Account/Password System:** No account means no credential breach risk

## Children's Privacy (COPPA)

Siffersafari is designed for children under 13. We comply with the **Children's Online Privacy Protection Act (COPPA)** by:
1. **Collecting zero personal information** from children or parents
2. **Storing data locally only** (no cloud servers)
3. **Providing easy data deletion** (see "How You Control Your Data" above)
4. **No tracking or profiling** across devices or apps

## Third-Party Services

We use the following open-source libraries, all operating **offline on your device:**
- **Hive** (local database) — [Apache 2.0 License](https://github.com/isar/hive)
- **Riverpod** (state management) — [MIT License](https://github.com/rrousselGit/riverpod)
- **Just Audio** (sound playback) — [MIT License](https://github.com/ryanheise/just_audio)
- **BCrypt** (password hashing) — Dart SDK, [BSD 3-Clause](https://github.com/google/bcrypt-dart)

None of these libraries phone home or collect data.

## Data Retention

We retain data only as long as necessary:
- **Child Profile Data:** Stored until you delete the profile
- **Parent PIN:** Stored until you delete the profile
- **Cache/Temporary Files:** Automatically cleared during normal app updates

We have **no centralized database**, so all data deletion is instant and permanent.

## Your Rights

As a parent/guardian, you have the right to:
- ✅ Know what data the app stores (see full list above)
- ✅ Delete your child's profile and all associated data anytime
- ✅ Request that we explain our data practices
- ✅ Contact us with privacy questions (see below)

## Changes to This Policy

If our data practices change, we will update this policy and notify users in the next app update. Continued use of the app after updates means acceptance of the new policy.

## Contact Us

For privacy questions or concerns:
- **Email:** [To be added by developer]
- **Mailing Address:** [To be added by developer if applicable]

For reports of COPPA violations, contact:
- **Federal Trade Commission:** [CoppaHotline@ftc.gov](mailto:CoppaHotline@ftc.gov)

## Compliance Summary

✅ **COPPA Compliant:** App collects zero personal information  
✅ **GDPR-Friendly:** No data processing; GDPR not applicable to offline apps  
✅ **Child-Safe:** Designed with children 6–12 in mind  
✅ **Transparent:** This policy explains everything we do (and don't do)

---

**Questions?** We're happy to explain. Contact us above.
