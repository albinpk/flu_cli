# 🛠️ Contributing to `flu`

Thank you for considering contributing to `flu` — the Flutter CLI assistant that helps you bootstrap projects with ease and power. Your contributions are highly appreciated!

---

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Conventional Commits](#conventional-commits)
- [Development Setup](#development-setup)
- [Feature Ideas](#feature-ideas)
- [Code Style](#code-style)
- [License](#license)

---

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone https://github.com/albinpk/flu_cli.git
   cd packages/flu
   ```

3. Install dependencies:

   ```bash
   dart pub get
   ```

4. Run the CLI:

   ```bash
   dart bin/flu.dart
   ```

---

## 💡 How to Contribute

Here are a few ways to contribute:

- 🐞 Report bugs and issues
- 🧩 Suggest new features
- 🛠️ Fix existing bugs
- 📦 Add support for more packages or project generators
- 🧪 Improve test coverage

To start:

- Open an issue for discussion before big changes
- Make sure your code passes formatting and analysis checks

---

## 🧾 Conventional Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org/) format for commit messages:

```
<type>: <short summary>

# Example:
feat: add Riverpod state management configuration
fix: correct asset watcher debounce bug
```

**Types:**

- `feat` – New feature
- `fix` – Bug fix
- `chore` – Project maintenance (formatting, deps, etc.)
- `docs` – Documentation only
- `refactor` – Code refactor without behavior change
- `test` – Add or fix tests

---

## 🧑‍💻 Development Setup

- Ensure you're using the latest Dart stable version.
- Use `dart format .` and `dart analyze` before committing.
- If you’re adding a new feature, consider writing a test.
- Prefer composable, testable logic — not everything should live in `bin/flu.dart`.

---

## 🌟 Feature Ideas

Check out the [issues](https://github.com/albinpk/flu_cli/issues) tab or suggest your own:

- New project templates
- More package integrations (Firebase, Hive, Supabase, etc.)
- Plugin support
- Workspace tools like `flu run`, `flu analyze`, etc.

---

## 📝 License

This project is [MIT licensed](LICENSE). By contributing, you agree that your contributions will be licensed under the same.

---

Thanks again, and happy coding 💙
