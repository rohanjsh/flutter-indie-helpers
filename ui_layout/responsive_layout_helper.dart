import 'package:flutter/material.dart';

/// A utility class to help with responsive layouts in Flutter apps.
/// 
/// This helper provides methods to determine the current device type,
/// screen size category, and orientation, as well as widgets to build
/// responsive layouts.
class ResponsiveLayoutHelper {
  /// Screen width breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  /// Get the device type based on the screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }
  
  /// Get the screen size category based on the screen width
  static ScreenSizeCategory getScreenSizeCategory(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return ScreenSizeCategory.xs;
    } else if (width < 480) {
      return ScreenSizeCategory.sm;
    } else if (width < 768) {
      return ScreenSizeCategory.md;
    } else if (width < 1024) {
      return ScreenSizeCategory.lg;
    } else if (width < 1200) {
      return ScreenSizeCategory.xl;
    } else {
      return ScreenSizeCategory.xxl;
    }
  }
  
  /// Check if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Check if the device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// Check if the device is a mobile device
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  /// Check if the device is a tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  /// Check if the device is a desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop ||
        getDeviceType(context) == DeviceType.largeDesktop;
  }
  
  /// Get the appropriate padding based on the screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(24.0);
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return const EdgeInsets.all(32.0);
    }
  }
  
  /// Get the appropriate font size based on the screen size
  static double getFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.2;
      case DeviceType.desktop:
        return desktop ?? mobile * 1.4;
      case DeviceType.largeDesktop:
        return largeDesktop ?? mobile * 1.6;
    }
  }
  
  /// Get the appropriate icon size based on the screen size
  static double getIconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.25;
      case DeviceType.desktop:
        return desktop ?? mobile * 1.5;
      case DeviceType.largeDesktop:
        return largeDesktop ?? mobile * 1.75;
    }
  }
  
  /// Get the appropriate spacing based on the screen size
  static double getSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.5;
      case DeviceType.desktop:
        return desktop ?? mobile * 2.0;
      case DeviceType.largeDesktop:
        return largeDesktop ?? mobile * 2.5;
    }
  }
  
  /// Get the appropriate number of grid columns based on the screen size
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return isLandscape(context) ? 2 : 1;
      case DeviceType.tablet:
        return isLandscape(context) ? 3 : 2;
      case DeviceType.desktop:
        return 4;
      case DeviceType.largeDesktop:
        return 6;
    }
  }
  
  /// Get the appropriate grid item width based on the screen size
  static double getGridItemWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = getGridColumns(context);
    final padding = getScreenPadding(context);
    
    return (width - padding.left - padding.right - (columns - 1) * 16) / columns;
  }
  
  /// Get the appropriate container width based on the screen size
  static double getContainerWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return width;
      case DeviceType.tablet:
        return width * 0.8;
      case DeviceType.desktop:
        return width * 0.7;
      case DeviceType.largeDesktop:
        return width * 0.6;
    }
  }
  
  /// Get the appropriate container height based on the screen size
  static double getContainerHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return height * 0.6;
      case DeviceType.tablet:
        return height * 0.7;
      case DeviceType.desktop:
        return height * 0.8;
      case DeviceType.largeDesktop:
        return height * 0.8;
    }
  }
  
  /// Get the appropriate button size based on the screen size
  static Size getButtonSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const Size(120, 40);
      case DeviceType.tablet:
        return const Size(150, 48);
      case DeviceType.desktop:
        return const Size(180, 56);
      case DeviceType.largeDesktop:
        return const Size(200, 64);
    }
  }
}

/// Device types based on screen width
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Screen size categories
enum ScreenSizeCategory {
  xs, // Extra small (< 360)
  sm, // Small (< 480)
  md, // Medium (< 768)
  lg, // Large (< 1024)
  xl, // Extra large (< 1200)
  xxl, // Extra extra large (>= 1200)
}

/// A widget that builds different widgets based on the device type
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext) mobileBuilder;
  final Widget Function(BuildContext)? tabletBuilder;
  final Widget Function(BuildContext)? desktopBuilder;
  final Widget Function(BuildContext)? largeDesktopBuilder;
  
  const ResponsiveBuilder({
    Key? key,
    required this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
    this.largeDesktopBuilder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveLayoutHelper.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileBuilder(context);
      case DeviceType.tablet:
        return tabletBuilder?.call(context) ?? mobileBuilder(context);
      case DeviceType.desktop:
        return desktopBuilder?.call(context) ??
            tabletBuilder?.call(context) ??
            mobileBuilder(context);
      case DeviceType.largeDesktop:
        return largeDesktopBuilder?.call(context) ??
            desktopBuilder?.call(context) ??
            tabletBuilder?.call(context) ??
            mobileBuilder(context);
    }
  }
}

/// A widget that builds different widgets based on the orientation
class OrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext) portraitBuilder;
  final Widget Function(BuildContext) landscapeBuilder;
  
  const OrientationBuilder({
    Key? key,
    required this.portraitBuilder,
    required this.landscapeBuilder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveLayoutHelper.isLandscape(context);
    
    return isLandscape ? landscapeBuilder(context) : portraitBuilder(context);
  }
}

/// A widget that builds different widgets based on the screen size category
class ScreenSizeBuilder extends StatelessWidget {
  final Widget Function(BuildContext)? xsBuilder;
  final Widget Function(BuildContext)? smBuilder;
  final Widget Function(BuildContext)? mdBuilder;
  final Widget Function(BuildContext)? lgBuilder;
  final Widget Function(BuildContext)? xlBuilder;
  final Widget Function(BuildContext)? xxlBuilder;
  final Widget Function(BuildContext) defaultBuilder;
  
  const ScreenSizeBuilder({
    Key? key,
    this.xsBuilder,
    this.smBuilder,
    this.mdBuilder,
    this.lgBuilder,
    this.xlBuilder,
    this.xxlBuilder,
    required this.defaultBuilder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final sizeCategory = ResponsiveLayoutHelper.getScreenSizeCategory(context);
    
    switch (sizeCategory) {
      case ScreenSizeCategory.xs:
        return xsBuilder?.call(context) ?? defaultBuilder(context);
      case ScreenSizeCategory.sm:
        return smBuilder?.call(context) ??
            xsBuilder?.call(context) ??
            defaultBuilder(context);
      case ScreenSizeCategory.md:
        return mdBuilder?.call(context) ??
            smBuilder?.call(context) ??
            xsBuilder?.call(context) ??
            defaultBuilder(context);
      case ScreenSizeCategory.lg:
        return lgBuilder?.call(context) ??
            mdBuilder?.call(context) ??
            smBuilder?.call(context) ??
            xsBuilder?.call(context) ??
            defaultBuilder(context);
      case ScreenSizeCategory.xl:
        return xlBuilder?.call(context) ??
            lgBuilder?.call(context) ??
            mdBuilder?.call(context) ??
            smBuilder?.call(context) ??
            xsBuilder?.call(context) ??
            defaultBuilder(context);
      case ScreenSizeCategory.xxl:
        return xxlBuilder?.call(context) ??
            xlBuilder?.call(context) ??
            lgBuilder?.call(context) ??
            mdBuilder?.call(context) ??
            smBuilder?.call(context) ??
            xsBuilder?.call(context) ??
            defaultBuilder(context);
    }
  }
}

/// A widget that adapts its layout based on the screen size
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? largeDesktopWidth;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final double? largeDesktopHeight;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? largeDesktopPadding;
  final Alignment alignment;
  final Color? backgroundColor;
  final BoxDecoration? decoration;
  
  const AdaptiveContainer({
    Key? key,
    required this.child,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.largeDesktopWidth,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.largeDesktopHeight,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.largeDesktopPadding,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.decoration,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveLayoutHelper.getDeviceType(context);
    
    double? width;
    double? height;
    EdgeInsets? padding;
    
    switch (deviceType) {
      case DeviceType.mobile:
        width = mobileWidth;
        height = mobileHeight;
        padding = mobilePadding ?? const EdgeInsets.all(16.0);
        break;
      case DeviceType.tablet:
        width = tabletWidth ?? mobileWidth;
        height = tabletHeight ?? mobileHeight;
        padding = tabletPadding ?? mobilePadding ?? const EdgeInsets.all(24.0);
        break;
      case DeviceType.desktop:
        width = desktopWidth ?? tabletWidth ?? mobileWidth;
        height = desktopHeight ?? tabletHeight ?? mobileHeight;
        padding = desktopPadding ?? tabletPadding ?? mobilePadding ?? const EdgeInsets.all(32.0);
        break;
      case DeviceType.largeDesktop:
        width = largeDesktopWidth ?? desktopWidth ?? tabletWidth ?? mobileWidth;
        height = largeDesktopHeight ?? desktopHeight ?? tabletHeight ?? mobileHeight;
        padding = largeDesktopPadding ??
            desktopPadding ??
            tabletPadding ??
            mobilePadding ??
            const EdgeInsets.all(32.0);
        break;
    }
    
    return Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      color: backgroundColor,
      decoration: decoration,
      child: child,
    );
  }
}

/// A widget that adapts its text style based on the screen size
class AdaptiveText extends StatelessWidget {
  final String text;
  final double mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final double? largeDesktopFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const AdaptiveText(
    this.text, {
    Key? key,
    required this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.largeDesktopFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveLayoutHelper.getFontSize(
      context,
      mobile: mobileFontSize,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
      largeDesktop: largeDesktopFontSize,
    );
    
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A widget that adapts its grid layout based on the screen size
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsets padding;
  
  const AdaptiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayoutHelper.getGridColumns(context);
    
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: children.map((child) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - padding.left - padding.right - (columns - 1) * spacing) / columns,
            child: child,
          );
        }).toList(),
      ),
    );
  }
}

/// Example usage:
///
/// ```dart
/// // Using ResponsiveBuilder
/// ResponsiveBuilder(
///   mobileBuilder: (context) => MobileLayout(),
///   tabletBuilder: (context) => TabletLayout(),
///   desktopBuilder: (context) => DesktopLayout(),
/// );
///
/// // Using OrientationBuilder
/// OrientationBuilder(
///   portraitBuilder: (context) => PortraitLayout(),
///   landscapeBuilder: (context) => LandscapeLayout(),
/// );
///
/// // Using ScreenSizeBuilder
/// ScreenSizeBuilder(
///   smBuilder: (context) => SmallLayout(),
///   mdBuilder: (context) => MediumLayout(),
///   lgBuilder: (context) => LargeLayout(),
///   defaultBuilder: (context) => DefaultLayout(),
/// );
///
/// // Using AdaptiveContainer
/// AdaptiveContainer(
///   mobileWidth: double.infinity,
///   tabletWidth: 600,
///   desktopWidth: 800,
///   mobilePadding: EdgeInsets.all(16),
///   tabletPadding: EdgeInsets.all(24),
///   child: YourWidget(),
/// );
///
/// // Using AdaptiveText
/// AdaptiveText(
///   'Hello, World!',
///   mobileFontSize: 16,
///   tabletFontSize: 20,
///   desktopFontSize: 24,
///   fontWeight: FontWeight.bold,
/// );
///
/// // Using AdaptiveGrid
/// AdaptiveGrid(
///   spacing: 16,
///   runSpacing: 16,
///   padding: EdgeInsets.all(16),
///   children: [
///     ItemWidget(),
///     ItemWidget(),
///     ItemWidget(),
///     // ...
///   ],
/// );
///
/// // Using ResponsiveLayoutHelper methods
/// Widget build(BuildContext context) {
///   final isDesktop = ResponsiveLayoutHelper.isDesktop(context);
///   final padding = ResponsiveLayoutHelper.getScreenPadding(context);
///   final fontSize = ResponsiveLayoutHelper.getFontSize(
///     context,
///     mobile: 16,
///     tablet: 20,
///     desktop: 24,
///   );
///   
///   return Padding(
///     padding: padding,
///     child: isDesktop
///         ? DesktopLayout()
///         : MobileLayout(),
///   );
/// }
/// ```
