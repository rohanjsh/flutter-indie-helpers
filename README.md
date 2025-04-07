<img src="https://storage.googleapis.com/cms-storage-bucket/847ae81f5430402216fd.svg" width="200">

### Collection of quick scripts, utilities mainly dedicated to indie developers

#### Table of contents

##### Utilities by Category
- [UI and Layout](#ui-and-layout)
- [Network and API](#network-and-api)
- [Storage and Data](#storage-and-data)
- [Authentication and Security](#authentication-and-security)
- [App Configuration and Management](#app-configuration-and-management)
- [User Input and Validation](#user-input-and-validation)
- [Analytics and Monitoring](#analytics-and-monitoring)

##### Scripts
- [Release Builds](#flutter-builds-script-)
- [Unused Assets Remover](#remove-unused-assets-script-)
- [Localization Helper](#localization-helper)

## Utilities by Category

### UI and Layout

Utilities for responsive design and theme management.

- **responsive_layout_helper.dart**: Helps create responsive layouts that adapt to different screen sizes and orientations.
- **theme_switcher.dart**: Manages theme switching between light, dark, and system modes.

### Network and API

Utilities for handling network operations and API communication.

- **api_service.dart**: A service for making API requests with error handling and response parsing.
- **network_connectivity_monitor.dart**: Monitors network connectivity status and changes.
- **deep_link_handler.dart**: Handles deep links and app links for navigation.

### Storage and Data

Utilities for data persistence and management.

- **local_database_helper.dart**: Helper for local database operations using SQLite.
- **secure_storage_helper.dart**: Securely stores sensitive data like tokens and credentials.
- **image_cache_manager.dart**: Manages caching of images for better performance.

### Authentication and Security

Utilities for user authentication and security.

- **biometric_auth_helper.dart**: Handles biometric authentication (fingerprint, face ID).

### App Configuration and Management

Utilities for app configuration, updates, and performance.

- **app_config_manager.dart**: Manages app configuration and environment variables.
- **app_update_checker.dart**: Checks for app updates and prompts users.
- **app_rating_prompt.dart**: Prompts users to rate the app at appropriate times.
- **app_performance_monitor.dart**: Monitors app performance metrics.

### User Input and Validation

Utilities for handling user input and permissions.

- **form_validator.dart**: Validates form inputs with customizable rules.
- **file_picker_helper.dart**: Simplifies file picking operations.
- **permission_handler_utility.dart**: Manages app permissions requests and status.

### Analytics and Monitoring

Utilities for analytics and error reporting.

- **firebase_analytics_helper.dart**: Helper for Firebase Analytics integration.
- **error_reporting_utility.dart**: Reports and logs errors for debugging.

## Flutter Builds Script 🧑‍💻

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

## Localization Helper

Script to help manage app localization files.

### Usage

1. Run the script:

   ```bash
   sh localization_helper.sh
   ```

2. Follow the prompts to manage your app's localization files.

## How to Use the Utilities

To use these utilities in your Flutter project:

1. Copy the desired utility files from their respective folders into your project.

2. Make any necessary adjustments to imports or package references to match your project structure.

3. Use the utilities in your code as needed.
