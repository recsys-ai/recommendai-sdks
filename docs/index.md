# RecSys.AI SDK

Official client libraries for the **RecSys.AI** recommendation platform, available in 11 languages.

## Available SDKs

| Language | Package | Version |
|---|---|---|
| Python | [recommendai](https://pypi.org/project/recommendai/) | [![PyPI](https://img.shields.io/pypi/v/recommendai)](https://pypi.org/project/recommendai/) |
| TypeScript / JavaScript | [@recommendai/sdk](https://www.npmjs.com/package/@recommendai/sdk) | [![npm](https://img.shields.io/npm/v/@recommendai/sdk)](https://www.npmjs.com/package/@recommendai/sdk) |
| Go | [github.com/recsys-ai/recommendai-sdkss/go](https://pkg.go.dev/github.com/recsys-ai/recommendai-sdkss/go) | [![Go Reference](https://pkg.go.dev/badge/github.com/recsys-ai/recommendai-sdkss/go.svg)](https://pkg.go.dev/github.com/recsys-ai/recommendai-sdkss/go) |
| Dart / Flutter | [recommendai](https://pub.dev/packages/recommendai) | [![pub.dev](https://img.shields.io/pub/v/recommendai)](https://pub.dev/packages/recommendai) |
| .NET / C# | [RecommendAI](https://www.nuget.org/packages/RecommendAI) | [![NuGet](https://img.shields.io/nuget/v/RecommendAI)](https://www.nuget.org/packages/RecommendAI) |
| Java | [com.recommendai:recommendai-sdk](https://search.maven.org/artifact/com.recommendai/recommendai-sdk) | [![Maven Central](https://img.shields.io/maven-central/v/com.recommendai/recommendai-sdk)](https://search.maven.org/artifact/com.recommendai/recommendai-sdk) |
| Kotlin | [com.recommendai:recommendai-sdk-kotlin](https://search.maven.org/artifact/com.recommendai/recommendai-sdk-kotlin) | [![Maven Central](https://img.shields.io/maven-central/v/com.recommendai/recommendai-sdk-kotlin)](https://search.maven.org/artifact/com.recommendai/recommendai-sdk-kotlin) |
| PHP | [recsys-ai/recommendai](https://packagist.org/packages/recsys-ai/recommendai) | [![Packagist](https://img.shields.io/packagist/v/recsys-ai/recommendai)](https://packagist.org/packages/recsys-ai/recommendai) |
| Ruby | [recommendai](https://rubygems.org/gems/recommendai) | [![Gem](https://img.shields.io/gem/v/recommendai)](https://rubygems.org/gems/recommendai) |
| Rust | [recommendai](https://crates.io/crates/recommendai) | [![crates.io](https://img.shields.io/crates/v/recommendai)](https://crates.io/crates/recommendai) |
| Swift | [RecommendAI (SwiftPM)](https://github.com/recsys-ai/recommendai-sdks) | [![GitHub tag](https://img.shields.io/github/v/tag/recsys-ai/recommendai-sdks?filter=swift%2Fv*)](https://github.com/recsys-ai/recommendai-sdks/tags) |

## Core Methods

Every SDK exposes the same four operations:

| Method | Description |
|---|---|
| `similar(itemId, limit)` | Items similar to the given item |
| `popular(limit, category?)` | Globally popular items, optionally by category |
| `upsert(items)` | Bulk create or update items in the catalogue |
| `ping()` | Health check — returns `true` if the API is reachable |
