read -p "Enter the location of the assets folder: " location

if [[ ! -d "$location" ]]; then
  echo "Error: The location '$location' does not exist."
  exit 1
fi

for FILE in $(find "$location" -type f)
do
  #  Search for references to the file in the lib folder and its subdirectories
  if ! grep -R "$FILE" lib; then
    # If no matches are found, delete the file
    rm "$FILE"
  fi
done

echo "Finished cleaning unused assets."
