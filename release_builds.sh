#!/bin/bash

# Exit on any error, unbound variable, or error in a pipeline
set -euo pipefail


# Define variables to store states of both flags
use_defaults=false
no_flavor=false

# Define available flags
valid_flags="use-defaults,h,no-flavor"

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

    echo "✅ Build completed for $2 flavor and type $1"
}

#! Function to run flutter commands, change this if you want to run any other commands before building
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
    run_flutter_commands

    # Directly run commands for each build type
    for build_type in "apk" "appbundle" "ipa"; do
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
    #! DEFAULTS - Change these values to your own
    num_flavors=2
    flavors=("dev" "lib/main_dev.dart" "prod" "lib/main_prod.dart")
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

            # Add flavor information to the array
            flavors+=("$flavor_name" "$main_dart_location")
        done
    fi
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

open builds/$current_date_time

echo "🎉 All builds completed successfully!, you can find all the builds in /builds folder"
