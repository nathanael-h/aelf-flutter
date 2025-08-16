class AppSectionItem {
  final String title;
  final String name;
  final bool datePickerVisible;
  final bool searchVisible;

  const AppSectionItem(
      {required this.title,
      required this.name,
      this.datePickerVisible = true,
      this.searchVisible = false});
}
