![Logo](https://storage.googleapis.com/cms-storage-bucket/847ae81f5430402216fd.svg)

# Indie Developer Helpers
#### Helping Each Other 

- [Release Builds](#flutter-builds-script)
- [Unused Assets Remover](#remove-unused-assets-script-🧹)

## Flutter Builds Script

Making it easier to generate all flutter builds.

### Description

This script automates Flutter project builds with flavor and type options. It allows you to customize the number of flavors, flavor names, entry points, and build types.

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) installed and configured.
- Bash shell environment.

### **Demo for - release_builds.sh**

https://github.com/rohanjsh/flutter-indie-helpers/assets/35066779/f79b92d1-659c-48f6-b647-a01d91bea347

### Options

- `--use-defaults`: Use default values.
- `--no-flavor`: Build without flavors.

### Usage

- **Default:**
  ```bash
  ./release_builds.sh
  ```
- **For zsh:**
     ```bash
   sh release_builds.sh
   ```

### Additional Points

- The script allows you to customize the number of flavors, flavor names, entry points, and build types.
- Use --use-defaults for quick builds with default values.
- Use --no-flavor if you don't want to use flavors. In this case, the script will prompt you to select build types directly.
- The script creates timestamped build directories in the /builds folder.
- Open the latest build directory automatically using open builds/$current_date_time.

## Remove Unused Assets Script 🧹

This script helps you clean up your Flutter project by removing assets that are no longer referenced in your code.

### Usage

1. Run the script:

   ```bash
   sh remove_unused_assets.sh
   ```

2. Enter the location of the assets folder when prompted.

3. The script will search for unused assets in the specified folder and its subdirectories.

4. Unused assets will be deleted.

### Note

- Make sure to backup your project before running this script.

- This script assumes your Flutter project is structured with a `lib` folder containing your source code.

- The script checks for references to each asset in the `lib` folder and its subdirectories.

### Example

```bash
# Enter the location of the assets folder
Enter the location of the assets folder: assets

# Output
Searching for unused assets in assets...
No references found for assets/image.png. Deleting...
No references found for assets/icon.svg. Deleting...
Finished cleaning unused assets.

```
