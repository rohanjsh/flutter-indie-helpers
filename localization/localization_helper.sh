#!/bin/bash

# Localization Helper Script for Flutter
# This script helps manage translations in Flutter apps

set -e

# Function to display help
show_help() {
  echo "Flutter Localization Helper"
  echo "============================="
  echo "This script helps manage translations in Flutter apps."
  echo
  echo "Usage:"
  echo "  ./localization_helper.sh [command]"
  echo
  echo "Commands:"
  echo "  extract    - Extract translatable strings from Dart files"
  echo "  generate   - Generate localization files from translations"
  echo "  add-locale - Add a new locale to the project"
  echo "  status     - Show missing translations"
  echo "  help       - Show this help message"
  echo
  echo "Examples:"
  echo "  ./localization_helper.sh extract"
  echo "  ./localization_helper.sh add-locale fr"
}

# Function to extract translatable strings
extract_strings() {
  echo "🔍 Extracting translatable strings from Dart files..."
  
  # Create directory if it doesn't exist
  mkdir -p lib/l10n
  
  # Create or update the arb template file
  echo "{" > lib/l10n/app_en.arb
  echo "  \"@@locale\": \"en\"," >> lib/l10n/app_en.arb
  
  # Find all Dart files and extract strings with tr() or similar patterns
  strings_found=false
  
  for file in $(find lib -name "*.dart"); do
    # Extract strings with tr() pattern - adjust regex as needed for your codebase
    strings=$(grep -o "tr(['\"].*['\"])" "$file" | sed -E "s/tr\(['\"](.*)['\"]\)/\1/g" | sort | uniq)
    
    if [ ! -z "$strings" ]; then
      strings_found=true
      
      while IFS= read -r string; do
        # Generate a key from the string (simplified version)
        key=$(echo "$string" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
        
        # Add to arb file if not already present
        if ! grep -q "\"$key\":" lib/l10n/app_en.arb; then
          echo "  \"$key\": \"$string\"," >> lib/l10n/app_en.arb
        fi
      done <<< "$strings"
    fi
  done
  
  # Close the JSON file
  echo "  \"@@last\": \"\"" >> lib/l10n/app_en.arb
  echo "}" >> lib/l10n/app_en.arb
  
  if [ "$strings_found" = true ]; then
    echo "✅ Extraction complete. Strings added to lib/l10n/app_en.arb"
  else
    echo "⚠️ No translatable strings found. Make sure you're using tr() or similar methods."
  fi
}

# Function to generate localization files
generate_localization() {
  echo "🔄 Generating localization files..."
  
  # Check if flutter_localizations is in pubspec.yaml
  if ! grep -q "flutter_localizations:" pubspec.yaml; then
    echo "⚠️ flutter_localizations dependency not found in pubspec.yaml"
    read -p "Would you like to add it? (y/n): " add_dep
    
    if [ "$add_dep" = "y" ]; then
      # Add dependencies to pubspec.yaml
      sed -i.bak '/dependencies:/a\
  flutter_localizations:\
    sdk: flutter\
  intl: ^0.18.0' pubspec.yaml
      rm pubspec.yaml.bak
      
      # Add l10n configuration to pubspec.yaml if not present
      if ! grep -q "flutter:" pubspec.yaml; then
        echo "flutter:" >> pubspec.yaml
      fi
      
      if ! grep -q "generate:" pubspec.yaml; then
        sed -i.bak '/flutter:/a\
  generate: true' pubspec.yaml
        rm pubspec.yaml.bak
      fi
      
      if ! grep -q "l10n:" pubspec.yaml; then
        sed -i.bak '/flutter:/a\
  l10n:\
    arb-dir: lib/l10n\
    template-arb-file: app_en.arb\
    output-localization-file: app_localizations.dart' pubspec.yaml
        rm pubspec.yaml.bak
      fi
      
      # Run flutter pub get
      flutter pub get
    fi
  fi
  
  # Generate localization files
  flutter gen-l10n
  
  echo "✅ Localization files generated successfully."
}

# Function to add a new locale
add_locale() {
  if [ -z "$1" ]; then
    echo "⚠️ Please specify a locale code (e.g., fr, es, de)"
    exit 1
  fi
  
  locale=$1
  
  echo "🌐 Adding new locale: $locale"
  
  # Check if template file exists
  if [ ! -f "lib/l10n/app_en.arb" ]; then
    echo "⚠️ Template file lib/l10n/app_en.arb not found. Run extract first."
    exit 1
  fi
  
  # Create new locale file if it doesn't exist
  if [ ! -f "lib/l10n/app_$locale.arb" ]; then
    # Copy template and change locale
    cp "lib/l10n/app_en.arb" "lib/l10n/app_$locale.arb"
    sed -i.bak "s/\"@@locale\": \"en\"/\"@@locale\": \"$locale\"/" "lib/l10n/app_$locale.arb"
    rm "lib/l10n/app_$locale.arb.bak"
    
    echo "✅ Created new locale file: lib/l10n/app_$locale.arb"
    echo "📝 Please translate the strings in this file."
  else
    echo "⚠️ Locale file already exists: lib/l10n/app_$locale.arb"
  fi
}

# Function to show translation status
show_status() {
  echo "📊 Translation Status:"
  
  # Check if template file exists
  if [ ! -f "lib/l10n/app_en.arb" ]; then
    echo "⚠️ Template file lib/l10n/app_en.arb not found. Run extract first."
    exit 1
  fi
  
  # Count keys in template
  template_keys=$(grep -o "\"[a-zA-Z0-9_]*\":" "lib/l10n/app_en.arb" | grep -v "@@" | wc -l)
  echo "📘 English (template): $template_keys strings"
  
  # Check other locale files
  for file in lib/l10n/app_*.arb; do
    if [ "$file" != "lib/l10n/app_en.arb" ]; then
      locale=$(basename "$file" | sed 's/app_\(.*\)\.arb/\1/')
      locale_keys=$(grep -o "\"[a-zA-Z0-9_]*\":" "$file" | grep -v "@@" | wc -l)
      
      if [ "$locale_keys" -lt "$template_keys" ]; then
        missing=$((template_keys - locale_keys))
        echo "🔴 $locale: $locale_keys/$template_keys strings ($missing missing)"
      else
        echo "🟢 $locale: $locale_keys/$template_keys strings (complete)"
      fi
    fi
  done
}

# Main script logic
case "$1" in
  "extract")
    extract_strings
    ;;
  "generate")
    generate_localization
    ;;
  "add-locale")
    add_locale "$2"
    ;;
  "status")
    show_status
    ;;
  "help"|"--help"|"-h")
    show_help
    ;;
  *)
    echo "⚠️ Unknown command: $1"
    echo "Run './localization_helper.sh help' for usage information."
    exit 1
    ;;
esac

exit 0
