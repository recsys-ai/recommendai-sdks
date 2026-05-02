# Contributing to RecSys.AI SDK

Thank you for your interest in contributing! This monorepo contains client SDKs for 11 languages.

## Repository Layout

```
recommendai-sdk/
├── python/          # PyPI package
├── typescript/      # npm package
├── go/              # Go module
├── dart/            # pub.dev package
├── dotnet/          # NuGet package
├── java/            # Maven Central artifact
├── kotlin/          # Maven Central artifact
├── php/             # Packagist package
├── ruby/            # RubyGems gem
├── rust/            # crates.io crate
├── swift/           # SwiftPM package
├── docs/            # MkDocs documentation source
└── .github/
    └── workflows/   # CI and publish workflows
```

## Getting Started

1. Fork the repository and clone your fork.
2. Create a feature branch: `git checkout -b feat/my-change`
3. Make your changes in the relevant SDK folder.
4. Run the tests for that language (see below).
5. Open a pull request against `main`.

## Running Tests

### Python
```bash
cd python && pip install -e ".[dev]" && pytest
```

### TypeScript
```bash
cd typescript && npm ci && npm test
```

### Go
```bash
cd go && go test ./...
```

### Dart
```bash
cd dart && dart pub get && dart test
```

### .NET
```bash
cd dotnet && dotnet test
```

### Java
```bash
cd java && mvn test
```

### Kotlin
```bash
cd kotlin && ./gradlew test
```

### PHP
```bash
cd php && composer install && vendor/bin/phpunit
```

### Ruby
```bash
cd ruby && bundle install && bundle exec rspec
```

### Rust
```bash
cd rust && cargo test
```

### Swift
```bash
cd swift && swift test
```

## Code Style

- Match the style of the existing code in each SDK.
- Every public method that makes an HTTP call must be covered by a test.
- All SDKs must expose the same four core methods: `similar`, `popular`, `upsert`, `ping`.

## Releasing

Releases are automated via GitHub Actions. To publish a new version of an SDK, push a tag
following the pattern `<language>/v<semver>`:

```bash
git tag python/v1.2.3
git push origin python/v1.2.3
```

This triggers the corresponding `publish-<language>.yml` workflow.

## Code of Conduct

Please be respectful and constructive in all interactions. We follow the
[Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
