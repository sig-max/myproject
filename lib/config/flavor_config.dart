enum AppFlavor { dev, prod }

class FlavorConfig {
  static late AppFlavor flavor;

  static void initialize({required AppFlavor flavor}) {
    FlavorConfig.flavor = flavor;
  }

  static String get appName {
    switch (flavor) {
      case AppFlavor.prod:
        return 'Medical Management';
      case AppFlavor.dev:
        return 'Medical Management (Dev)';
    }
  }
}
