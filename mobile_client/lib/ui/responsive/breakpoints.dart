class Breakpoints {
  static const double small = 600;
  static const double medium = 900;
  static const double large = 1200;
  
  static bool isSmall(double width) => width < small;
  static bool isMedium(double width) => width >= small && width < medium;
  static bool isLarge(double width) => width >= medium && width < large;
  static bool isExtraLarge(double width) => width >= large;
} 