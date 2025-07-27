List<String> getSortedList(List<String> list) {
  var sortedList = List<String>.from(list);
  sortedList.sort((a, b) => a.compareTo(b));
  return sortedList;
}
