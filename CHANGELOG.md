# Changelog

All notable changes to ZenMux Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-05-20

### Added

- Full i18n support with `LanguageManager` for English and Simplified Chinese
- Language picker in Settings — switch language without changing system preferences
- Open source project documentation (CONTRIBUTING.md, CHANGELOG.md, SECURITY.md, issue templates)
- Badges and restructured README (English & Chinese)

### Changed

- Replaced all hardcoded Chinese strings with localized `L()` function calls
- Improved quota countdown formatting with localized templates

## [1.0.0] - 2026-05-19

### Added

- Menu bar resident app showing 5-hour quota usage percentage
- Usage panel with 5-hour / 7-day progress bars, PAYG balance, and Flow rate
- Right-click context menu (Refresh, Settings, Quit)
- Color-coded usage warnings (green / orange / red)
- API Key stored securely in macOS Keychain
- Configurable auto-refresh interval (1 / 5 / 15 / 30 minutes)
- English and Simplified Chinese UI with system language auto-detection
