class InputValidators {
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Masukan harga jual';
    }
    final cleanValue = value.replaceAll(',', '');
    if (double.tryParse(cleanValue) == null) {
      return 'Masukan angka yang valid';
    }
    if (double.parse(cleanValue) < 0) {
      return 'Harga tidak boleh negatif';
    }
    return null;
  }
}
