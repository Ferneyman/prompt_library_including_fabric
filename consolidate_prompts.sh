#!/bin/zsh

# This script generates an index file for Fabric patterns and user prompts.
# - Fabric patterns are linked directly to GitHub
# - User prompts are linked to local files in 'docs/my_prompts_consolidated/'
# Example: /Users/mcferney/Development_Projects/Prompt Library/fabric/consolidate_prompts.sh
# To run: cd /Users/mcferney/Development_Projects/Prompt Library/fabric/ && ./consolidate_prompts.sh

# Define configuration variables
# All paths are relative to the 'fabric' directory (where the script is run).
TARGET_DIR="docs/my_prompts_consolidated" # Directory for consolidated user prompts
MY_PROMPTS_DIR="docs/my_prompts" # Input: fabric/docs/my_prompts/
FABRIC_REPO_URL="https://github.com/danielmiessler/fabric"
FABRIC_PATTERNS_PATH="patterns" # Path within the GitHub repo where patterns are stored

echo "Prompt indexing script started (running from 'fabric/' directory)."
echo "Target directory for consolidated user prompts: ./${TARGET_DIR}"
echo "User prompts source directory: ./${MY_PROMPTS_DIR}"

# Ensure target directory exists
echo "Checking target directory..."
mkdir -p "./${TARGET_DIR}" # Create the target directory inside fabric/ if it doesn't exist
if [ $? -ne 0 ]; then echo "Error: Could not create/check target directory './${TARGET_DIR}'. Exiting."; exit 1; fi
echo "Target directory './${TARGET_DIR}' verified."

# Process user's prompts
echo "Processing user's prompts from './${MY_PROMPTS_DIR}'..."
# Current directory is 'fabric/'. MY_PROMPTS_DIR is 'docs/my_prompts'. TARGET_DIR is 'docs/my_prompts_consolidated'.
if [ -d "./${MY_PROMPTS_DIR}" ]; then
    for user_prompt_file in "./${MY_PROMPTS_DIR}"/*.md; do
        if [ -f "$user_prompt_file" ]; then
            base_filename=$(basename "$user_prompt_file" .md)
            sanitized_name=$(echo "$base_filename" | tr -s '[:space:]' '_' | tr -cd '[:alnum:]_-.')
            if [ -n "$sanitized_name" ]; then
                cp "$user_prompt_file" "./${TARGET_DIR}/myprompt_${sanitized_name}.md"
                if [ $? -eq 0 ]; then
                    echo "Copied user prompt: myprompt_${sanitized_name}.md to ./${TARGET_DIR}/"
                else
                    echo "Warning: Failed to copy user prompt from $user_prompt_file"
                fi
            else
                echo "Warning: Could not derive a valid name from user prompt file: $user_prompt_file"
            fi
        else
            echo "Skipping non-file item in user prompts directory: $user_prompt_file"
        fi
    done
    echo "Finished processing user's prompts."
else
    echo "Warning: User prompts directory './${MY_PROMPTS_DIR}' not found. Skipping user prompts."
fi

echo "-----------------------------------------------------
User prompts consolidation complete!
Your prompts are now in the './${TARGET_DIR}/' directory.
-----------------------------------------------------"

# ---- BEGIN INDEX GENERATION ----
echo
echo "Generating prompt index..."

# Index file path - directly in docs directory
INDEX_FILE_PATH="./docs/INDEX.md"

# Ensure this path is correct for where you placed the JSON file.
PATTERN_DESCRIPTIONS_FILE="./docs/metadata/pattern_descriptions.json"

# Initialize INDEX.md
echo "# Consolidated Prompt Index" > "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"
echo "Last updated: $(date)" >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"

echo "## Fabric Patterns" >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"
echo "These prompts link directly to the [danielmiessler/fabric](${FABRIC_REPO_URL}) GitHub repository." >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "Warning: jq command could not be found. You need jq to process Fabric pattern descriptions."
    echo "Please install jq with: brew install jq"
    exit 1
fi

# Check if pattern descriptions file exists
if [ ! -f "$PATTERN_DESCRIPTIONS_FILE" ]; then
    echo "Error: Pattern descriptions file not found at $PATTERN_DESCRIPTIONS_FILE."
    echo "Please ensure this file exists before running the script."
    exit 1
fi

# Process fabric patterns from the JSON file
echo "Processing Fabric patterns from $PATTERN_DESCRIPTIONS_FILE..."
jq -c '.patterns[]' "$PATTERN_DESCRIPTIONS_FILE" | while read -r pattern; do
    pattern_name=$(echo "$pattern" | jq -r '.patternName')
    description=$(echo "$pattern" | jq -r '.description')
    
    if [[ -n "$pattern_name" && "$pattern_name" != "null" ]]; then
        # Create GitHub link to the pattern's system.md file
        github_link="${FABRIC_REPO_URL}/blob/main/${FABRIC_PATTERNS_PATH}/${pattern_name}/system.md"
        
        # Display name with fabric_ prefix for consistency
        display_name="fabric_${pattern_name}"
        
        echo "Processing Fabric pattern: $pattern_name"
        
        # Add to INDEX.md
        echo "### [$display_name]($github_link)" >> "$INDEX_FILE_PATH"
        echo "" >> "$INDEX_FILE_PATH"
        if [[ -n "$description" && "$description" != "null" ]]; then
            echo "*Description:* $description" >> "$INDEX_FILE_PATH"
        else
            echo "*Description:* No description available." >> "$INDEX_FILE_PATH"
        fi
        echo "" >> "$INDEX_FILE_PATH"
        echo "---" >> "$INDEX_FILE_PATH"
        echo "" >> "$INDEX_FILE_PATH"
    fi
done

# Add section for user prompts
echo "## My Prompts" >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"
echo "These are custom prompts stored locally in the \`docs/my_prompts_consolidated/\` directory." >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"

# Process user prompts from my_prompts_consolidated directory
for prompt_file in "./${TARGET_DIR}"/*.md; do
    if [ -f "$prompt_file" ]; then
        filename_with_ext=$(basename "$prompt_file")
        # Skip processing INDEX.md itself if it's in the loop
        if [[ "$filename_with_ext" == "INDEX.md" ]]; then
            echo "Skipping INDEX.md itself."
            continue
        fi
        filename_no_ext="${filename_with_ext%.md}"
        
        echo "Processing user prompt: $filename_no_ext"
        
        # Extract description from file content for user prompts
        description_from_file=$(head -c 2500 "$prompt_file" | tr '\n' ' ' | sed -E \
            -e 's/<[^>]*>//g' \
            -e 's/!\[[^]]*\]\([^)]*\)//g' \
            -e 's/\[[^\]]*\]\([^)]*\)//g' \
            -e 's/#{1,6} //g' \
            -e 's/[*_`~]{1,3}//g' \
            -e 's/---[^-]*---//g' \
            -e 's/\{\{/( (/g' \
            -e 's/\}\}/) )/g' \
            -e 's/\{%/( %/g' \
            -e 's/%\}/% )/g' \
            | tr -s ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | cut -c1-500)
        
        if [ -n "$description_from_file" ]; then
            description="$description_from_file..."
        else
            description="No description available."
        fi
        
        # Add to INDEX.md - link to the local file
        echo "### [$filename_no_ext](./${TARGET_DIR}/$filename_with_ext)" >> "$INDEX_FILE_PATH"
        echo "" >> "$INDEX_FILE_PATH"
        echo "*Description:* $description" >> "$INDEX_FILE_PATH"
        echo "" >> "$INDEX_FILE_PATH"
        echo "---" >> "$INDEX_FILE_PATH"
        echo "" >> "$INDEX_FILE_PATH"
    fi
done

echo "Prompt index generation complete!"
echo "Index file: $INDEX_FILE_PATH"
echo "-----------------------------------------------------"
# ---- END INDEX GENERATION ----

