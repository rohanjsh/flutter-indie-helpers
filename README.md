# Flutter Builds Script

Making it easier to generate all flutter builds.

## Description

This script automates Flutter project builds with flavor and type options. It allows you to customize the number of flavors, flavor names, entry points, and build types.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) installed and configured.
- Bash shell environment.

## **Demo for - release_builds.sh**

https://github.com/rohanjsh/flutter-indie-helpers/assets/35066779/f79b92d1-659c-48f6-b647-a01d91bea347

## Options

- `--use-defaults`: Use default values.
- `--no-flavor`: Build without flavors.

## Usage

- **Default:**
  ```bash
  ./release_builds.sh

## Additional Points
- The script allows you to customize the number of flavors, flavor names, entry points, and build types.
- Use --use-defaults for quick builds with default values.
- Use --no-flavor if you don't want to use flavors. In this case, the script will prompt you to select build types directly.
- The script creates timestamped build directories in the /builds folder.
- Open the latest build directory automatically using open builds/$current_date_time.
