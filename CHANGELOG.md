# Changelog

## 1.1.0

- Add `Yacto.Schema.Single` and `Yacto.Schema.Shard` modules.
    - These define `repo/{0-1}` after `use Yacto.Schema`.
- Add `Yacto.Repo.Helper` to provide convenient functions.

## 1.0.7

- Apply elixir formatter
- Fix warnings
- Update dependencies

## 1.0.6

- [Bug] Fix a migration type name includes with spaces.

## 1.0.5

- Shorten index name for too long name error.
- Use specified migration type if :type defined in meta
- Remove illegal character in filename for Windows
