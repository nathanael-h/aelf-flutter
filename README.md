# AELF
This application aims to provide you Bible and daily readings in french from AELF.org, without being connected to internet. It is directly inspired by [AELF Android](https://github.com/HackMyChurch/aelf-dailyreadings/)

:fr: Cette application a pour but de vous donner accès à la Bible et aux lectures du jour (messe et offices de la liturgie des heures) en français selon la traduction officielle pour la liturgie catholique (AELF). Ceci sans être connecté à internet en permanence. Elle est directement inspirée de l'application [AELF pour Android](https://github.com/HackMyChurch/aelf-dailyreadings/)

## Try it ?
If the build worked on bitrise.io (click the image bellow) you can download an apk file and try it on Android 😄 Edit : the link is hard to find in the build logs, ask-me and I'll send it to you. To try it on iOS, ask-me and I'll send you a code to download the app from TestFlight !

:fr: Si la compilation a marché sur bitrise (cliquez sur l'image ci-dessous) vous pouvez télécharger un apk et l'essayer sur Android 😄 Edit: le lien est perdu dans les logs de compilation, demandez-moi et je vous l'enverrai. Pour tester sur iOS, demandez-moi et je vous enverrai un code pour télécharger l'app depuis TestFlight ! 
 

[![Build Status](https://app.bitrise.io/app/2eebdaafcd535b2a/status.svg?token=-dSaCJW2Bi_SgfHPStbl1Q&branch=master)](https://app.bitrise.io/app/2eebdaafcd535b2a) 

## Getting Started
This project is developped in flutter, from scratch and targets at the moment iOS and Android. 
Actually only the Bible is implemented. Contributions are very welcome ! Fell free to open an issue or a merge request. The code is in the **lib** directory. Install flutter, and launch *flutter run* from this directory (using terminal, cmd or powershell...). flutter works very well in Visual Studio Code (VS Code) and IntelliJ.

🇫🇷 Le pojet est actuellement développé de zéro avec flutter, et cible pour le moment iOS et Android. 
Pour le moment seule la Bible est fonctionnelle. Les contributions sont les bienvenues ! Vous pouvez ouvrir un ticket ou une demande de fusion. Le code est dans le dossier **lib**. Installez flutter, et lancer *flutter run* (avec terminal, cmd, ou powershell) depuis le présent dossier. flutter fonctionne aussi dans les IDE Visual Studio Code (VS Code) et IntelliJ.

## TODO

### Bible 
- Bible offline
- Bible search

### Daily Readings (mass and liturgy of hours)
- Basic implementation to start : only today and online
- Cache a few weeks
- Date peeker

### Global 
- Translate all this Readme to 🇫🇷
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
  - Add auto-screenshots : write needed tests and give them to fastlane with https://pub.dev/packages/screenshots 
  - Use bitrise.io to manage release
- Target others platforms : [Web](https://flutter.dev/web) and [Desktop](https://flutter.dev/desktop)

## Why ?
I started to contribute to the android app [look here](https://github.com/HackMyChurch/aelf-dailyreadings/pull/7) and was looking for a way to provide full offline AELF Bible to iOS users. As I am not a developper, it would have been to difficult for me to developp a native iOS app and to maintain it. When I discovered flutter I thougt it could be a good framework to achieve that. So I gave it a try and here it is : (at the time of writing) I have a minimal Bible app that runs well on iOS (and Android). 

🇫🇷 J'ai commencé par contribuer à l'application Android AELF [voir ici](https://github.com/HackMyChurch/aelf-dailyreadings/pull/7) et cherchait également un moyen de proposer la Bible AELF (avec accès sans internet) aux utilisateurs d'iOS. N'étant pas développeur, il aurait été trop complexe pour moi de dévelloper une application iOS native et de la maintenir dans le temps. Quand j'ai découvert flutter, je me suis dit que ça pourrait être un bon framework pour ça. Ainsi je me suis lancé, et voilà ou j'en suis : (au moment où j'écris ceci) J'ai une application simple proposant le Bible qui fonctionne sur iOS (et Android). 

## Screenshots :

### Bible: 
![List of Bible books](screenshots/01_home_bible.PNG)

### Bible book: 
![Bible book](screenshots/02_bible_book.PNG)

### Drawer menu: 
![Drawer menu](screenshots/03_drawer_menu.PNG)

### To Do alert: 
![To do alert](screenshots/04_not_dev_screen.PNG)