# Contributing to HepaSense Mobile

## Pull Request Rules

### Quick Summary
All PRs must follow these guidelines:

1. **Widget tests**: Write widget tests for UI changes
2. **Code format**: Run `flutter analyze` and `flutter format` before submitting
3. **Firebase**: Validate Firebase configuration
4. **Mobile-specific**: Test on target devices

### Branch Naming
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or improvements
- `chore/` - Maintenance tasks

### Commit Message Guidelines
- Use imperative present tense: "Add widget", "Fix bug", not "Added widget", "Fixed bug"
- Keep subject line <50 characters
- Reference issues with `#123`
- Add Co-authored-by: openhands <openhands@all-hands.dev>

### Review Process
1. All tests must pass
2. Linting must pass (`flutter analyze` and `flutter format`)
3. Widget tests must pass for UI changes
4. Changes reviewed by at least one maintainer
5. Merge into `main` or `develop` only

### Local Development Setup
```bash
# Install dependencies
dart pub get

# Run tests
flutter test

# Run linter
flutter analyze

# Format code
flutter format --set-exit-if-changed lib/

# Run all checks
flutter analyze && flutter format --set-exit-if-changed lib/
```

## Code Style

We use `flutter analyze` for linting and `flutter format` for formatting. Run these before submitting:

```bash
flutter analyze     # Linting
flutter format --set-exit-if-changed lib/  # Formatting
```

## Testing

All changes must include tests:

```bash
# Run tests
flutter test

# Run widget tests specifically
flutter test --platforms=ios,android
```

## Dependencies

- Keep dependencies up-to-date
- Check for Firebase configuration issues
- Update `pubspec.yaml` only through official channels

## Security

- Never commit secrets, API keys, or credentials
- Use Firebase configuration management
- Test authentication flows

## Firebase

- Validate Firebase configuration before deployment
- Ensure environment-specific configs are properly separated
- Test push notifications and authentication

## Branches and Merging

- Work on feature branches
- Merge into `main` (production) or `develop` (pre-release)
- Ensure all CI checks pass before merging
- Run tests on target platforms (iOS/Android)
- Document the reasoning for any non-standard approaches
