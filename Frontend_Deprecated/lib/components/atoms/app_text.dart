// Atom: AppText
// Single Functionality: Themed text components with consistent typography

import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  const AppText.title(
    this.text, {
    super.key,
    this.textAlign,
  })  : style = null,
        maxLines = null,
        overflow = null;

  const AppText.subtitle(
    this.text, {
    super.key,
    this.textAlign,
  })  : style = null,
        maxLines = null,
        overflow = null;

  const AppText.body(
    this.text, {
    super.key,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = null;

  const AppText.caption(
    this.text, {
    super.key,
    this.textAlign,
  })  : style = null,
        maxLines = null,
        overflow = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    TextStyle? effectiveStyle = style;
    if (effectiveStyle == null) {
      if (this is _TitleText) {
        effectiveStyle = theme.textTheme.titleLarge;
      } else if (this is _SubtitleText) {
        effectiveStyle = theme.textTheme.titleMedium;
      } else if (this is _CaptionText) {
        effectiveStyle = theme.textTheme.bodySmall;
      } else {
        effectiveStyle = theme.textTheme.bodyMedium;
      }
    }

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _TitleText extends AppText {
  const _TitleText(super.text, {super.textAlign}) : super.title();
}

class _SubtitleText extends AppText {
  const _SubtitleText(super.text, {super.textAlign}) : super.subtitle();
}

class _CaptionText extends AppText {
  const _CaptionText(super.text, {super.textAlign}) : super.caption();
}

// Helper constructors
extension AppTextConstructors on AppText {
  static AppText title(String text, {TextAlign? textAlign}) => 
      _TitleText(text, textAlign: textAlign);
  
  static AppText subtitle(String text, {TextAlign? textAlign}) => 
      _SubtitleText(text, textAlign: textAlign);
  
  static AppText caption(String text, {TextAlign? textAlign}) => 
      _CaptionText(text, textAlign: textAlign);
}
