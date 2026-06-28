import 'package:aelf_flutter/models/app_section_item.dart';

List<AppSectionItem> appSections = [
  AppSectionItem(
      title: "Bible",
      name: "bible",
      datePickerVisible: false,
      searchVisible: true),
  AppSectionItem(title: "Messe", name: "messes"),
  AppSectionItem(title: "Informations", name: "informations"),
  AppSectionItem(title: "Lectures", name: "lectures"),
  AppSectionItem(title: "Laudes", name: "laudes"),
  AppSectionItem(title: "Tierce", name: "tierce"),
  AppSectionItem(title: "Sexte", name: "sexte"),
  AppSectionItem(title: "None", name: "none"),
  AppSectionItem(title: "Vêpres", name: "vepres"),
  AppSectionItem(title: "Complies", name: "complies"),
  AppSectionItem(title: "Lectures (⭐ nouveau !)", name: "offline_readings"),
  AppSectionItem(title: "Laudes (⭐ nouveau !)", name: "offline_morning"),
  AppSectionItem(title: "Tierce (⭐ nouveau !)", name: "offline_tierce"),
  AppSectionItem(title: "Sexte (⭐ nouveau !)", name: "offline_sexte"),
  AppSectionItem(title: "None (⭐ nouveau !)", name: "offline_none"),
  AppSectionItem(title: "Vêpres (⭐ nouveau !)", name: "offline_vespers"),
  AppSectionItem(title: "Complies (⭐ nouveau !)", name: "offline_complines"),
  AppSectionItem(
      title: "Calendrier Liturgique",
      name: "offline_calendar",
      datePickerVisible: false)
];
