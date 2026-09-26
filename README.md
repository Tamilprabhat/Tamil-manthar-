# தமிழ் மாந்தர் — திறன் பார்வை V1

முதல் பதிப்பு: Android-ல் இணைய இணைப்பு இல்லாமல் தமிழ் OCR.

## தேவைகள்
- Flutter 3.x
- Android Studio / Android SDK
- Android சாதனம்

## அமைப்பு

இந்த source-ல் OCR engine-ஆக `flutter_tesseract_ocr` பயன்படுத்தப்படுகிறது.
Tamil OCR-க்கு `tam.traineddata` தேவை; அது `assets/tessdata/` உள்ளே bundled ஆக இருக்க வேண்டும்.

தற்போதைய archive-ல் அந்த binary language file சேர்க்கப்படவில்லை. காரணம்: இந்த build environment-ல் வெளியக இணையத்திலிருந்து அதை பதிவிறக்க முடியவில்லை.

Tamil traineddata கிடைத்ததும்:

    assets/tessdata/tam.traineddata

என்று வைக்கவும்.

## இயக்குவது

1. `flutter create .`
2. `flutter pub get`
3. `flutter run`

முதல் build நேரத்தில் Flutter packages download செய்ய இணையம் தேவைப்படலாம்.
Build செய்யப்பட்ட APK-ல் OCR language data bundled செய்யப்பட்டால், app-ன் OCR செயல்பாடு runtime-ல் இணையத்தை சார்ந்திருக்காது.

## அடுத்த கட்டங்கள்
- OCR result Copy / Share
- பல பக்க PDF OCR
- crop / rotate / perspective correction
- தமிழ் + English mixed OCR
- local history
- offline AI text correction
