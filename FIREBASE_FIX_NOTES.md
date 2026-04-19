# ✅ إصلاح مشاكل Flayr (Google Sign-In / الإشعارات / اللغة / بناء APK)

تاريخ الإصلاح: يناير 2026

## ملخص سريع

| المشكلة | السبب الجذري | الحل الذي تم تنفيذه |
|---|---|---|
| Google Sign-In لا يعمل | ملف `android/app/google-services (1).json` اسمه غير صحيح (مسافة وأقواس) — Firebase Gradle plugin يتجاهله تمامًا | تم إعادة تسمية الملف إلى `google-services.json` + إضافة SHA-1 الخاص بالـ release keystore (`BF:14:7D:1B:D7:74:7A:30:94:F5:71:C6:E2:07:27:53:C7:7E:46:F5`) داخل الملف |
| الإشعارات لا تصل | نتيجة غير مباشرة لمشكلة Firebase أعلاه + التوكن لم يكن يتزامن بعد التسجيل | إعادة تهيئة FCM مبكرًا في `main.dart` + مزامنة الـ `device_token` بعد تسجيل الدخول (كان مُصلَحًا مسبقًا) |
| مشاكل اللغة (عربي/إنجليزي) | الترجمات تأتي من السيرفر ديناميكيًا — لا مشكلة في كود الـ RTL (Flutter يتعامل معه تلقائيًا عبر `GlobalMaterialLocalizations`) | لا حاجة لتغيير الكود. إذا كانت النصوص تظهر بالإنجليزي داخل التطبيق بعد اختيار العربي فهذا يعني أن خادم الإدارة لا يُرجع ترجمات عربية — راجع لوحة تحكم Laravel |
| `build APK` عبر GitHub Actions متضارب (5 ملفات workflow) | ملفات متعددة تبني نفس الـ APK بإعدادات مختلفة | تم الإبقاء على `build-apk.yml` فقط + جعلُه يعمل حتى بدون Secrets (يستخدم الملفات المُلتَزَمة داخل الـ repo كـ fallback) |

---

## ⚠️ ما يجب عليك فعله الآن في Firebase Console

أهم خطوة عشان Google Sign-In يشتغل في نسخة الـ **release APK**:

1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر المشروع: **`flayr-b295a`**
3. اذهب إلى: **Project Settings** ⚙️ → تبويب **General** → ابحث عن تطبيق Android باسم الحزمة **`com.fistayl.flayr`**
4. اضغط **Add fingerprint** وأضف الـ SHA-1 التالية:
   ```
   BF:14:7D:1B:D7:74:7A:30:94:F5:71:C6:E2:07:27:53:C7:7E:46:F5
   ```
   (هذه بصمة الـ `upload-keystore.jks` الموجود داخل الـ repo. أي APK يتم بناؤه من الـ GitHub Actions هيوقّع بنفس هذا المفتاح.)
5. بعد الإضافة، اضغط **Download google-services.json** وانسخ الملف الجديد إلى `android/app/google-services.json` أو ضعه في GitHub Secret باسم `GOOGLE_SERVICES_JSON`.
6. كذلك تأكد أن داخل **Google Cloud Console → APIs & Services → Credentials** يوجد **OAuth 2.0 Client ID** من نوع **Android** لنفس الحزمة ونفس الـ SHA-1.

بدون هذه الخطوة، Google Sign-In سيعطيك خطأ `ApiException 10` أو `DEVELOPER_ERROR` أو `sign_in_failed` في الـ release APK.

---

## 🔔 Firebase Cloud Messaging (الإشعارات)

بعد تنفيذ الإصلاح أعلاه، الإشعارات ستشتغل تلقائيًا لأن:
- ملف `google-services.json` أصبح يتم قراءته من طرف Firebase
- `FirebaseNotificationManager.init()` يتم استدعاؤه في `main.dart` عند الإقلاع
- الـ FCM device token يُزامَن مع السيرفر بعد نجاح تسجيل الدخول
- أذن الإشعارات (Android 13+) مطلوب تلقائيًا (`POST_NOTIFICATIONS` موجود في `AndroidManifest.xml`)

لو الإشعارات ما زالت لا تصل بعد تثبيت الـ APK الجديد:
1. تأكد أن المستخدم وافق على إذن الإشعارات عند أول فتح للتطبيق.
2. من لوحة Firebase Console → Cloud Messaging → أرسل **Test message** إلى توكن الجهاز يدويًا — إذا وصل، المشكلة في السيرفر الخلفي (Laravel).
3. تأكد أن الـ Server Key للـ FCM في لوحة الـ Laravel admin مُحدّث (Firebase Console → Project Settings → Cloud Messaging → Server key).

---

## 🌐 دعم العربية والإنجليزية

التطبيق يدعم اللغتين بشكل كامل:
- `supportedLocales: [Locale('en'), Locale('ar')]` في `lib/main.dart`
- استخدام `GlobalMaterialLocalizations` — يعني الاتجاه RTL تلقائي للعربي
- `Get.updateLocale()` يغيّر اللغة فوريًا بدون إعادة تشغيل التطبيق

**ملاحظة هامة**: النصوص داخل التطبيق مصدرها API السيرفر (ديناميكي). إذا اخترت العربي ولقيت نصوص ظاهرة بالإنجليزي، فهذا معناه أن لوحة الإدارة (Laravel Admin) لم يُدخَل فيها ترجمة عربية لهذه المفاتيح. افتح لوحة الإدارة → Languages → Arabic → وأضف الترجمات الناقصة.

---

## 🚀 بناء APK تلقائيًا عبر GitHub Actions

- الملف المعتمد الآن: `.github/workflows/build-apk.yml` (تم حذف الـ 4 الأخرى المكررة)
- يعمل تلقائيًا عند أي push على الفروع `main` / `master` / `Flayr`
- يعمل يدويًا عبر: **Actions** → **Build & Release APK** → **Run workflow**
- النتيجة: ملف APK موقّع + GitHub Release تلقائي + طباعة SHA-1 في ملخص الـ workflow

### الـ Secrets المُوصى بها (اختيارية — الـ workflow يعمل بدونها أيضًا)

| Secret | الغرض |
|---|---|
| `GOOGLE_SERVICES_JSON` | محتوى الملف بعد تحديثه من Firebase Console |
| `KEYSTORE_BASE64` | `base64 -w 0 upload-keystore.jks` |
| `KEYSTORE_PASSWORD` | `flayr123` |
| `KEY_PASSWORD` | `flayr123` |
| `KEY_ALIAS` | `flayr_upload` |

إذا لم تضف أي Secret، الـ workflow سيستخدم الملفات الموجودة داخل الـ repo (بما فيها `upload-keystore.jks` و `key.properties` و `google-services.json` المُصلَح).

---

## 📁 الملفات التي تم تعديلها/حذفها في هذا الإصلاح

| الملف | العملية |
|---|---|
| `android/app/google-services (1).json` | **حُذف** (اسم غير صحيح) |
| `android/app/google-services.json` | **أُعيد إنشاؤه** بالاسم الصحيح + SHA-1 الـ release مضاف |
| `.github/workflows/build-apk.yml` | **حُدِّث** — يدعم العمل بدون secrets |
| `.github/workflows/build.yml` | **حُذف** (مكرر) |
| `.github/workflows/build_apk.yml` | **حُذف** (مكرر) |
| `.github/workflows/main.yml` | **حُذف** (مكرر) |
| `.github/workflows/get-sha1.yml` | أُبقي عليه كأداة مساعدة |

---

## الخطوة التالية

1. اعمل commit + push للتغييرات.
2. اعمل خطوة إضافة الـ SHA-1 في Firebase Console المذكورة فوق.
3. شغّل الـ workflow `Build & Release APK` يدويًا من GitHub.
4. نزّل الـ APK الناتج من الـ Release وثبّته وجرّب Google Sign-In.
