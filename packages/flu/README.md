# 🚀 flu - Flutter Utility for Developers

[![deploy](https://github.com/albinpk/flu_cli/actions/workflows/deploy.yml/badge.svg)](https://github.com/albinpk/flu_cli/actions/workflows/deploy.yml)
[![Pub Version](https://img.shields.io/pub/v/flu)](https://pub.dev/packages/flu)
[![Pub Points](https://img.shields.io/pub/points/flu)](https://pub.dev/packages/flu/score)
[![GitHub Repo](https://img.shields.io/badge/GitHub-albinpk/flu_cli-blue?logo=github)](https://github.com/albinpk/flu_cli)
[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)

A developer-friendly CLI utility tool for Dart & Flutter projects that helps you scaffold projects, manage assets, and generate models faster.

---

## Table of Contents

- [Installation](#installation)
- [Commands](#commands)
  - [`flu create`](#flu-create)
    - [Usage](#usage)
    - [Options](#options)
    - [Example](#example)
  - [`flu asset`](#flu-asset)
    - [Usage](#usage-1)
    - [Options](#options-1)
    - [Example](#example-1)
  - [`flu gen` _(WIP)_](#flu-gen-wip)
    - [Usage](#usage-2)
    - [Options](#options-2)
    - [Features](#features)
    - [Example](#example-2)
    - [Syntax](#syntax)
    - [Field Options](#field-options)
      - [Custom JSON Key](#custom-json-key)
      - [Enum Support](#enum-support)

---

## Installation

### From pub.dev

```bash
dart pub global activate flu
```

---

## Commands

```
create   Create and configure new Flutter project
asset    Generates const references for your Flutter assets.
gen      [WIP] A faster model generator
```

---

### `flu create`

Create and configure a new Flutter project.

#### Usage

```bash
flu create
```

This will prompt you for configurations.

You can also pass these options as arguments to skip prompts and create the project directly.

#### Options

```
-h, --help                Print this usage information.
-n, --name                The name of the project
-d, --description         The description of the project
    --org                 The organization name
    --flutter-version     The Flutter version used in FVM
    --platforms           The platforms supported by this project
                          [android, ios, web, linux, macos, windows]
    --[no-]melos          Whether to use Melos for the project
    --workspace-name      Name used for pub workspace (root pubspec.yaml)
    --initial-version     Initial version of the project
    --dependencies        Dependencies of the project
    --dev-dependencies    Dev dependencies of the project
```

#### Example

```bash
flu create -n my_app --org com.example --platforms android,ios,web --flutter-version 3.22.1 --melos
```

---

### `flu asset`

Generates const references for your Flutter assets.

#### Usage

```bash
flu asset [arguments]
```

#### Options

```
-w, --watch         Watch for changes and re-generate the assets class.
-n, --class-name    The name of the generated asset class.
                    (defaults to "Assets")
```

#### Example

```bash
flu asset -n MyAssets
```

To automatically regenerate assets on file changes:

```bash
flu asset --watch
```

---

### `flu gen` _(WIP)_

A blazing fast model generator built using Rust ⚡

#### Usage

```bash
flu gen [arguments]
```

#### Options

```
-p, --path    Path to dart files (default: lib/**/*.dart)
```

#### Features

- Generate model classes with simple `// @flu` syntax and blazing-fast performance.
- This supports field types like `int`, `double`, `bool`, `String`, `DateTime`, `enum`, `List`, `dynamic`, and custom models with `fromJson`/`toJson` methods.
- It will generate the model in a `.flu.dart` file with `<constructor>`, `fromJson`, `toJson`, `copyWith`, `toString`, `hashCode` and `==` methods.

#### Example

```dart
// @flu
abstract class _User {
  String get name;
  int? get age;
}
```

```dart
void main() {
  final user = User(name: 'John', age: 25);

  print(user.toJson()); // { "name": "John", "age": 25 }

  final copy = user.copyWith(age: 30);
  print(copy.age); // 30

  final parsed = User.fromJson({"name": "John", "age": 25});
  print(parsed); // User(name: John, age: 25)

  print(user == parsed); // true
}
```

#### Syntax

- Class must be annotated with `// @flu`
- Must be an **abstract class**
- Name must start with **underscore (`_`)**
- Fields must be **getters with return types**, no implementation
- You can add per-field options with `// @flu` above the getter

> You can generate the `flu` class from JSON using the [J2M](https://j2m.albinpk.dev/) model converter.

#### Field Options

##### Custom JSON Key

```dart
// @flu
abstract class _User {
  // @flu key="first_name"
  String get name;
}
```

Will generate JSON like:

```json
{ "first_name": "John" }
```

##### Enum Support

```dart
// @flu
abstract class _User {
  // @flu enum
  Role get role;
}

enum Role { admin, user }
```

Serialization and deserialization will be handled for the enum `Role`.

<!-- > 🔧 In the future, a detailed benchmark chart will be added here to showcase how much faster `flu gen` is compared to `build_runner`. -->

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

If you like this project, give it a ⭐ on [GitHub](https://github.com/albinpk/flu_cli)!
