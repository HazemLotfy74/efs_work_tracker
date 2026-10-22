String? emailValidator(String? email){
  if (email!.isEmpty) {
    return 'Please enter your email';
  }
  if (!email.contains('@')) {
    return 'Please enter a valid email';
  }
  if (!email.contains('.')) {
    return 'Please enter a valid email';
  }
  return null;
}

String? passwordValidator(String? password){
  if (password!.isEmpty) {
    return 'Please enter your password';
  }
  if (password.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}