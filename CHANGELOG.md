# Changelog

## 1.1.3

- Update dependencies

## 1.1.2

- In `Yacto.Schema.field/3`, if opts[:default] is specified, set the value to meta[:default]

## 1.1.1

- Rename `get_or_new/4` to `get_by_or_new/4` and `get_or_insert_for_update/4` to `get_by_or_insert_for_update/4`

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
