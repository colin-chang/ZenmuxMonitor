# Contributing to ZenMux Monitor

Thank you for your interest in contributing! This guide covers how to submit changes.

## Reporting Issues

- **Bug reports**: Use the [Bug Report](../../issues/new?template=bug_report.md) template
- **Feature requests**: Use the [Feature Request](../../issues/new?template=feature_request.md) template
- **Security vulnerabilities**: Do **not** open a public issue. See [SECURITY.md](./SECURITY.md)

Before opening a new issue, please search existing issues to avoid duplicates.

## Development Setup

1. Fork and clone the repository
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Generate the Xcode project: `xcodegen generate`
4. Open `ZenmuxMonitor.xcodeproj` in Xcode 16+

## Making Changes

1. Create a branch from `main`: `git checkout -b my-feature`
2. Make your changes with clear, descriptive commits
3. Test your changes — ensure the app builds and runs correctly
4. Push to your fork and open a Pull Request against `main`

## Pull Request Guidelines

- One logical change per PR — keep it focused
- Include a clear description of what the PR does and why
- Reference any related issues (e.g., `Fixes #12`)
- Ensure the project builds without warnings

## Code Style

- Follow Swift API Design Guidelines
- Keep it simple — no unnecessary abstractions or over-engineering
- Zero third-party dependencies — use only Apple frameworks

## License

By submitting a contribution, you agree that your work will be licensed under the [MIT License](LICENSE).
