/// Joins the last two words with a no-break space so a headline never wraps with a single word on its last line
/// ("You cancelled this / order"). Only for text that is displayed; strings that are compared stay as they are.
String keepLastWordsTogether(String text) {
  final i = text.lastIndexOf(' ');
  return i <= 0 ? text : '${text.substring(0, i)} ${text.substring(i + 1)}';
}
