#!/bin/bash

# Exit on any error, unbound variable, or error in a pipeline
set -euo pipefail

# Define a variable to store whether the flag is present
use_defaults=false

# Get the current date and time
current_date_time=$(date "+%Y-%m-%d:%H:%M:%S")

#+----------------------------------------------+
#|      Function to build and copy files        |
#+----------------------------------------------+
# Function to build and copy files
build_and_copy_files() {
    if [ "$1" == "apk" ]; then
        flutter build $1 --flavor $2 -t $3 --split-per-abi
    else
        flutter build $1 --flavor $2 -t $3
    fi

    # Create a directory for the build
    mkdir -p builds/$current_date_time/[$2-$1]

    cp -r $4* builds/$current_date_time/[$2-$1]

    echo "✅ Build completed for $2 flavor and $1 type."
}

run_flutter_commands() {
    echo "🚀 Cleaning, fetching dependencies, and running build processes..."
    flutter clean
    flutter pub get
    dart pub get
    dart run build_runner build --delete-conflicting-outputs
}

#+-------------------------+
#|      Process flags      |
#+-------------------------+
# Process options using getopts
while getopts ":h-:" opt; do
    case $opt in
    -)
        case $OPTARG in
        use-defaults)
            use_defaults=true
            ;;
        *)
            echo "Invalid option: --$OPTARG" >&2
            exit 1
            ;;
        esac
        ;;
    h)
        echo "Usage: $0 [--use-defaults]"
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    esac
done

#+-------------------------+
#|      Get arguments      |
#+-------------------------+
# Check if the flag is set and take appropriate action
if [[ $use_defaults == true ]]; then
    #? Default values for flavors and main.dart locations
    num_flavors=2
    flavors=("dev" "lib/main_dev.dart" "prod" "lib/main_prod.dart")
else
    read -p "🤔 Number of flavors?  " num_flavors

    # Array to store flavor information
    declare -a flavors

    # Prompt the user for flavor information
    for ((i = 1; i <= num_flavors; i++)); do
        read -p "🍦 Flavor $i name:  " flavor_name
        read -p "📄 main location of flavor $i: " main_dart_location

        # Add flavor information to the array
        flavors+=("$flavor_name" "$main_dart_location")
    done
fi

run_flutter_commands

# Build and copy files for each flavor
for ((i = 0; i < ${#flavors[@]}; i += 2)); do
    flavor_name=${flavors[i]}
    main_dart_location=${flavors[i + 1]}

    # Build and copy files for each build type
    for build_type in "apk" "appbundle" "ipa"; do
        case "$build_type" in
        "apk")
            output_directory="build/app/outputs/flutter-apk/"
            ;;
        "appbundle")
            output_directory="build/app/outputs/bundle/"
            ;;
        "ipa")
            output_directory="build/ios/ipa/"
            ;;
        esac

        # Build and copy files for the flavor and build type
        build_and_copy_files $build_type $flavor_name $main_dart_location $output_directory
    done
done

echo "🎉 All builds completed successfully!, you can find all the builds in /builds folder"
