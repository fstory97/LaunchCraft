# Changelog

All notable changes to LaunchCraft will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Flatpak browser detection support
  - Auto-detect Chrome (com.google.Chrome)
  - Auto-detect Firefox (org.mozilla.firefox)
  - Auto-detect Chromium (org.chromium.Chromium)
  - Auto-detect Microsoft Edge (com.microsoft.Edge)
  - Auto-detect Brave (com.brave.Browser)
  - Auto-detect Vivaldi (com.vivaldi.Vivaldi)
- KDE Plasma desktop environment support
  - Desktop environment detection (GNOME vs KDE)
  - User guidance for pinning to taskbar in KDE Plasma
  - Proper handling of gsettings errors in non-GNOME environments
- Additional system browser detection
  - google-chrome-stable
  - chromium
  - brave-browser
  - vivaldi

### Changed
- Browser detection logic now checks system browsers first, then Flatpak browsers
- Improved error handling for environments without web browsers

### Fixed
- "A web browser is required" error on systems with Flatpak browsers only
- "org.gnome.shell schema not found" error on KDE Plasma environments
- Taskbar pinning now works correctly on both GNOME and KDE Plasma

## [0.2.0] - 2025-02-21

### Added
- Flatpak sandbox detection and user guidance
- Comprehensive package dependency checking and installation
- Support for multiple package managers (apt, dnf, pacman, zypper)
- Improved AppImage handling with GPU error mitigation
- Icon extraction from AppImage files
- Favicon download for website shortcuts
- Desktop file generation with proper categories
- WM_CLASS detection for better window grouping

### Changed
- Enhanced error messages and user feedback
- Improved timeout handling for AppImage operations
- Better handling of crashed AppImage processes

## [0.1.0] - 2025-01-15

### Added
- Initial project setup
- Basic AppImage registration
- Website shortcut creation
- Multi-language support (English/Korean)
- GNOME desktop environment support
- Interactive installation location selection (Dock/Desktop/Both)
- Automatic icon extraction and management
- Desktop entry (.desktop file) generation
- System locale-based language detection
- Command-line language override option (-l)

### Features
- AppImage application icon management
- Website shortcut with custom icons
- Simple shell script-based solution
- WM_CLASS detection via xprop
- Automatic dependency installation
- GTK icon cache update
- Desktop database update

### Documentation
- README.md with usage examples
- README.ko.md for Korean users
- MIT License
- Example screenshots

---

## Release History

- **[Unreleased]** - Flatpak and KDE Plasma support
- **[0.2.0]** - 2025-02-21 - Enhanced AppImage and Flatpak detection
- **[0.1.0]** - 2025-01-15 - Initial release
