import 'package:quanclash/l10n/l10n.dart';

/// Current app localization resolved dynamically.
///
/// The generated delegate replaces `AppLocalizations.current` whenever a locale
/// loads, so this must stay a getter: a top-level `final` would be initialized
/// once and keep pointing at the stale instance after a language change.
AppLocalizations get currentAppLocalizations => AppLocalizations.current;
