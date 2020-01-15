# AELF
This application aims to provide you Bible and daily readings in french from AELF.org, without being connected to internet. It is directly inspired by [AELF Android](https://github.com/HackMyChurch/aelf-dailyreadings/)

Cette application a pour but de vous donner accès à la Bible et aux lectures du jour (messe et offices de la liturgie des heures) en français selon la traduction officielle pour la liturgie catholique (AELF). Ceci sans être connecté à internet en permanence. Elle est directement inspirée de l'application [AELF pour Android](https://github.com/HackMyChurch/aelf-dailyreadings/)


## Getting Started
This project is developped in flutter, from scratch and targets at the moment iOS and Android. 
Actually only the Bible is implemented. Contributions are very welcome ! Fell free to open an issue or a merge request. The code is in the **lib** directory.

## TODO

### Bible 
- Bible offline
- Bible search

### Daily Readings (mass and liturgy of hours)
- Basic implementation to start : only today and online
- Cache a few weeks
- Date peeker

### Global 
- Publish an alpha version on iOS and Android
- Code cleaning (there is a lot to do here!)
- Intent to open aelf.org links in the app
- Share button
- Match the theme and UI from AELF Android.
- Dark Theme see https://flutter.dev/docs/cookbook/design/themes and https://api.flutter.dev/flutter/material/MaterialApp/darkTheme.html
- Improve accessibility (contrast and tweaks for screen readers) see : https://flutter.dev/docs/development/accessibility-and-localization/accessibility 
- CI with Gitlab.com or Bitrise.io 
- Tests see : https://flutter.dev/docs/testing
- CD
  - Add fastlane for quick release see : https://flutter.dev/docs/deployment/cd 
  - Use bitrise.io to manage release
- Target others platforms : [Web](https://flutter.dev/web) and [Desktop](https://flutter.dev/desktop)

## Why ?
I started to contribute to the android app [look here](https://github.com/HackMyChurch/aelf-dailyreadings/pull/7) and was looking for a way to provide full offline AELF Bible to iOS users. As I am not a developper, it would have been to difficult for me to developp a native iOS app and to maintain it. When I discovered flutter I thougt it could be a good framework to achieve that. So I gave it a try and here it is : (at the time of writing) I have a minimal Bible app that runs well on iOS (and Android). 