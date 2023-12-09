#!/bin/bash

#!  DEFAULTS
#!  Change these to your own
#!  PASS --use-defaults FLAG, TO USE THESE DEFAULTS
default_num_flavors=2
default_flavors=("dev" "lib/main_dev.dart" "prod" "lib/main_prod.dart")
default_build_types=("apk" "appbundle" "ipa")

#  DESCRIPTION
# Automates Flutter project builds with flavor and type options.

# Prerequisites:
# - Flutter installed and configured.
# - Bash shell environment.

# Options:
# --use-defaults: Use default values.
# --no-flavor: Build without flavors.

# Usage:
# - Default: ./build_script.sh
# - Custom: ./build_script.sh --use-defaults
# - No Flavor: ./build_script.sh --no-flavor

# How To Guide:
# - Run the script and follow prompts for custom builds.
#   - Number of flavors
#   - Flavor name and entry point for each flavor
#   - Build types to generate
# - Script creates timestamped build directories.

# Exit on any error, unbound variable, or error in a pipeline
set -euo pipefail

#! +--------------------------+
#! |      GLOBAL VARIABLES    |
#! +--------------------------+
# Define variables to store states of both flags
use_defaults=false
no_flavor=false
# Define available flags
valid_flags="use-defaults,h,no-flavor"

# Get the current date and time
current_date_time=$(date "+%Y-%m-%d:%H:%M:%S")

#+---------------------------------+
#|     Function Declarations       |
#+---------------------------------+
#! Function to run flutter commands, ALTER COMMANDS AS NEEDED (project specific)
run_flutter_commands() {
    echo "🚀 Cleaning, fetching dependencies, and running build processes..."
    flutter clean
    flutter pub get
    dart pub get
    #! Uncomment the following line if you are using build_runner
    # dart run build_runner build --delete-conflicting-outputs
}

# Function to display an interactive menu for build types
select_build_types() {
    if [[ $use_defaults == true ]]; then
        build_types=("${default_build_types[@]}")
        return
    fi

    echo "️  Select the build type(s) you want to generate:"
    echo "  1. APK"
    echo "  2. AAB (App Bundle)"
    echo "  3. IPA"
    echo "  0. All"

    read -p "Enter your choice (comma-separated numbers): " build_type_choice

    # Split the user input into an array of individual choices
    IFS=',' read -r -a build_type_choices <<<"$build_type_choice"

    build_types=()
    # Loop through each choice and validate it
    for choice in "${build_type_choices[@]}"; do
        case "$choice" in
        0) build_types=("apk" "appbundle" "ipa") ;;
        1) build_types+=("apk") ;;
        2) build_types+=("appbundle") ;;
        3) build_types+=("ipa") ;;
        *) echo "Invalid choice: '$choice'. Ignoring." ;;
        esac
    done

    # Check if any valid choices were selected
    if [[ ${#build_types[@]} -eq 0 ]]; then
        echo "No valid build types selected. Exiting." && exit 1
    fi
}

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

    echo "✅ Build completed for $2 flavor and type $1"
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
        h)
            echo "Usage: $0 [--$valid_flags]"
            exit 0
            ;;
        no-flavor)
            no_flavor=true
            ;;
        *)
            echo "Invalid option: --$OPTARG" >&2
            echo "Available options: $valid_flags" >&2
            exit 1
            ;;
        esac
        ;;
    h)
        echo "Usage: $0 [--$valid_flags]"
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        echo "Available options: $valid_flags" >&2
        exit 1
        ;;
    esac
done

# Check if the no-flavor flag is set
if [[ $no_flavor == true ]]; then
    select_build_types
    run_flutter_commands

    # Directly run commands for each build type
    for build_type in "${build_types[@]}"; do
        case "$build_type" in
        "apk")
            flutter build apk --split-per-abi

            # Create a directory for the build
            mkdir -p builds/$current_date_time/[no-flavor-$build_type]

            # Copy files for each build type
            cp -r build/app/outputs/flutter-apk/* builds/$current_date_time/[no-flavor-$build_type]
            ;;
        "appbundle")
            flutter build appbundle

            # Create a directory for the build
            mkdir -p builds/$current_date_time/[no-flavor-$build_type]

            # Copy files over
            cp -r build/app/outputs/bundle/* builds/$current_date_time/[no-flavor-$build_type]
            ;;
        "ipa")
            flutter build ipa

            # Create a directory for the build
            mkdir -p builds/$current_date_time/[no-flavor-$build_type]

            # Copy files over
            cp -r build/ios/ipa/* builds/$current_date_time/[no-flavor-$build_type]
            ;;
        esac

        # Create a directory for the build
        mkdir -p builds/$current_date_time/[no-flavor-$build_type]

        # Copy files for each build type
        case "$build_type" in
        "apk")
            cp -r build/app/outputs/flutter-apk/* builds/$current_date_time/[no-flavor-$build_type]
            ;;
        "appbundle")
            cp -r build/app/outputs/bundle/* builds/$current_date_time/[no-flavor-$build_type]
            ;;
        "ipa")
            cp -r build/ios/ipa/* builds/$current_date_time/[no-flavor-$build_type]
            ;;
        esac

    done

    echo "🎉 All builds completed successfully!, you can find all the builds in /builds folder"

    open builds/$current_date_time
    exit 0
fi

#+-------------------------+
#|      Get arguments      |
#+-------------------------+
# Check if the flag is set and take appropriate action
if [[ $use_defaults == true ]]; then
    num_flavors=$default_num_flavors
    flavors=("${default_flavors[@]}")
    select_build_types
else
    # if no-flavor, then skip this step
    if [[ $no_flavor == false ]]; then
        read -p "🤔 Number of flavors?  " num_flavors

        # Array to store flavor information
        declare -a flavors

        # Prompt the user for flavor information
        for ((i = 1; i <= num_flavors; i++)); do
            read -p "🍦 Flavor $i name:  " flavor_name
            read -p "📄 Entry point location of flavor $i (eg. lib/main_dev.dart): " main_dart_location

            #check if the file exists
            #if it does not exist, then ask again
            while [[ ! -f $main_dart_location ]]; do
                echo "🚫 File $main_dart_location does not exist, try again"
                read -p "📄 Entry point location of flavor $i (eg. lib/main_dev.dart): " main_dart_location
            done

            # Add flavor information to the array
            flavors+=("$flavor_name" "$main_dart_location")
        done

        select_build_types
    fi
fi

run_flutter_commands

# Build and copy files for each flavor
for ((i = 0; i < ${#flavors[@]}; i += 2)); do
    flavor_name=${flavors[i]}
    main_dart_location=${flavors[i + 1]}

    # Build and copy files for each build type
    for build_type in "${build_types[@]}"; do
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

open builds/$current_date_time

echo "🎉 All builds completed successfully!, you can find all the builds in /builds folder"
