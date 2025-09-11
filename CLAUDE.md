# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a new Flutter project called "slowdown" with a minimal setup. The app currently displays "Hello World!" as a starting point.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app on connected device/emulator
- `flutter run -d chrome` - Run in Chrome browser
- `flutter run -d macos` - Run on macOS
- `flutter run -d ios` - Run on iOS simulator
- `flutter run -d android` - Run on Android emulator

### Build Commands
- `flutter build apk` - Build Android APK
- `flutter build ipa` - Build iOS app
- `flutter build web` - Build for web
- `flutter build macos` - Build macOS app
- `flutter build linux` - Build Linux app
- `flutter build windows` - Build Windows app

### Testing and Analysis
- `flutter test` - Run unit tests
- `flutter analyze` - Run static analysis and linting
- `flutter analyze --watch` - Run analysis continuously
- `flutter test --coverage` - Run tests with coverage report

### Project Management
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter clean` - Clean build artifacts
- `flutter doctor` - Check Flutter installation and dependencies

## Project Structure

- `lib/main.dart` - Entry point with basic MaterialApp and "Hello World!" display
- `pubspec.yaml` - Project configuration with minimal dependencies (flutter, flutter_test, flutter_lints)
- `analysis_options.yaml` - Uses flutter_lints for code analysis
- Platform-specific folders: `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`

## Code Architecture

The app uses Flutter's standard structure with:
- Material Design components
- StatelessWidget pattern for the main app
- Center-aligned text widget as placeholder content

## Linting and Code Quality

The project uses `flutter_lints` package for code analysis. Run `flutter analyze` to check for issues before committing changes.