#!/bin/zsh

# This script is intended to be placed and run from the 'fabric' directory.
# Example: /Users/mcferney/Development_Projects/Prompt Library/fabric/consolidate_prompts.sh
# To run: cd /Users/mcferney/Development_Projects/Prompt Library/fabric/ && ./consolidate_prompts.sh

# Define configuration variables
# All paths are relative to the 'fabric' directory (where the script is run).
TARGET_DIR="docs/all_prompts_consolidated" # Output: fabric/docs/all_prompts_consolidated/
FABRIC_TEMP_CLONE_NAME="temp_fabric_clone" # Name for the temp directory
FABRIC_TEMP_CLONE_PATH="../${FABRIC_TEMP_CLONE_NAME}" # Path: ../temp_fabric_clone (outside fabric/)
FABRIC_REPO_URL="https://github.com/danielmiessler/fabric.git"
MY_PROMPTS_DIR="docs/my_prompts" # Input: fabric/docs/my_prompts/

echo "Consolidation script started (running from 'fabric/' directory)."
echo "Target directory for consolidated prompts: ./${TARGET_DIR}"
echo "Temporary directory for Fabric clone: ${FABRIC_TEMP_CLONE_PATH}"
echo "User prompts source directory: ./${MY_PROMPTS_DIR}"

# Clean up previous runs
echo "Cleaning up previous run directories (if they exist)..."
rm -rf "./${TARGET_DIR}" # Clean target dir inside fabric/
rm -rf "${FABRIC_TEMP_CLONE_PATH}" # Clean temp clone dir outside fabric/
mkdir -p "./${TARGET_DIR}" # Create the target directory inside fabric/
if [ $? -ne 0 ]; then echo "Error: Could not create target directory './${TARGET_DIR}'. Exiting."; exit 1; fi
echo "Target directory './${TARGET_DIR}' created."

# Clone fabric repository into the parent directory
echo "Cloning Fabric repository from $FABRIC_REPO_URL into '${FABRIC_TEMP_CLONE_PATH}'..."
git clone --depth 1 --filter=blob:none --sparse "$FABRIC_REPO_URL" "${FABRIC_TEMP_CLONE_PATH}"
if [ $? -ne 0 ]; then echo "Error: Cloning Fabric repository failed. Exiting."; exit 1; fi
echo "Fabric repository cloned successfully into '${FABRIC_TEMP_CLONE_PATH}'."

# Navigate into the temporary clone directory
cd "${FABRIC_TEMP_CLONE_PATH}"
if [ $? -ne 0 ]; then echo "Error: Could not change directory to '${FABRIC_TEMP_CLONE_PATH}'. Exiting."; exit 1; fi
echo "Current directory: $(pwd)"

echo "Setting up sparse checkout for 'patterns' directory..."
git sparse-checkout set patterns
if [ $? -ne 0 ]; then
    echo "Error: Setting sparse checkout for patterns failed. Exiting."
    # Attempt to navigate back to the original 'fabric' directory before exiting
    # This part can be complex if paths are unusual, relying on final cleanup.
    cd ../ # Expected to be workspace root
    if [ -d "fabric" ]; then # Check if 'fabric' dir exists before trying to cd into it
        cd fabric
    fi
    exit 1
fi
echo "Sparse checkout configured."

# Process fabric patterns
echo "Processing Fabric patterns..."
# Current directory is ${FABRIC_TEMP_CLONE_PATH} (e.g., ../temp_fabric_clone relative to fabric/)
# Destination is fabric/docs/all_prompts_consolidated which is ../fabric/${TARGET_DIR}/ from here.
find patterns -type f -name system.md | while read filepath; do
    parent_dir_name=$(basename "$(dirname "$filepath")")
    # Sanitize name: replace spaces with underscores, allow alphanumeric, underscore, hyphen, dot
    sanitized_name=$(echo "$parent_dir_name" | tr -s '[:space:]' '_' | tr -cd '[:alnum:]_-.')
    if [ -n "$sanitized_name" ]; then
        cp "$filepath" "../fabric/${TARGET_DIR}/fabric_${sanitized_name}.md"
        if [ $? -eq 0 ]; then
            echo "Copied Fabric pattern: fabric_${sanitized_name}.md to ../fabric/${TARGET_DIR}/"
        else
            echo "Warning: Failed to copy Fabric pattern from $filepath"
        fi
    else
        echo "Warning: Could not derive a valid name from Fabric pattern path: $filepath"
    fi
done
echo "Finished processing Fabric patterns."

# Navigate back to the original 'fabric' directory
cd .. # Now in workspace root /Users/mcferney/Development_Projects/Prompt Library/
cd fabric # Now in /Users/mcferney/Development_Projects/Prompt Library/fabric/
if [ $? -ne 0 ]; then echo "Error: Could not change directory back to 'fabric' directory. Exiting."; exit 1; fi
echo "Current directory: $(pwd)"

# Process user's prompts
echo "Processing user's prompts from './${MY_PROMPTS_DIR}'..."
# Current directory is 'fabric/'. MY_PROMPTS_DIR is 'docs/my_prompts'. TARGET_DIR is 'docs/all_prompts_consolidated'.
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

# Clean up temporary fabric clone (which is at ../temp_fabric_clone relative to current 'fabric/' dir)
echo "Cleaning up temporary Fabric clone directory '${FABRIC_TEMP_CLONE_PATH}'..."
rm -rf "${FABRIC_TEMP_CLONE_PATH}"
echo "Temporary directory cleaned up."

echo "-----------------------------------------------------
Consolidation complete!
All prompts are now in the './${TARGET_DIR}/' directory (inside 'fabric/docs/').
Fabric patterns are prefixed with 'fabric_'.
Your prompts are prefixed with 'myprompt_'.
-----------------------------------------------------
To run this script again:
1. Make sure this script (consolidate_prompts.sh) is in your 'fabric' directory.
2. Navigate to your 'fabric' directory: cd /Users/mcferney/Development_Projects/Prompt Library/fabric/
3. Execute: ./consolidate_prompts.sh
4. Make sure it's executable: chmod +x consolidate_prompts.sh
-----------------------------------------------------"

# ---- BEGIN INDEX GENERATION ----
echo
echo "Generating prompt index..."

INDEX_FILE_PATH="./${TARGET_DIR}/INDEX.md"
# Ensure this path is correct for where you placed the JSON file.
# It should be relative to the 'fabric/' directory where the script runs.
PATTERN_DESCRIPTIONS_FILE="./docs/metadata/pattern_descriptions.json" 

# Initialize INDEX.md
echo "# Consolidated Prompt Index" > "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"
echo "Last updated: $(date)" >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "Warning: jq command could not be found. Descriptions for Fabric patterns will be extracted from file content instead of pattern_descriptions.json."
    echo "Please install jq for optimal description generation."
fi

# Check if pattern descriptions file exists
if [ ! -f "$PATTERN_DESCRIPTIONS_FILE" ]; then
    echo "Warning: Pattern descriptions file not found at $PATTERN_DESCRIPTIONS_FILE. Descriptions for Fabric patterns will be extracted from file content."
fi

for prompt_file in "./${TARGET_DIR}"/*.md; do
    if [ -f "$prompt_file" ]; then
        filename_with_ext=$(basename "$prompt_file")
        # Skip processing INDEX.md itself if it's in the loop
        if [ "$filename_with_ext" == "INDEX.md" ]; then
            echo "Skipping INDEX.md itself."
            continue
        fi
        filename_no_ext="${filename_with_ext%.md}"
        description="" # Initialize description

        echo "Processing: $filename_no_ext"

        # Try to get description from JSON for fabric_ patterns
        if [[ "$filename_no_ext" == fabric_* ]] && command -v jq &> /dev/null && [ -f "$PATTERN_DESCRIPTIONS_FILE" ]; then
            # Strip "fabric_" prefix to get the original name
            original_pattern_name_from_file="${filename_no_ext#fabric_}"
            
            # Further sanitize original_pattern_name_from_file for jq lookup:
            # Example: if filename was fabric_some_pattern_.md, this becomes some_pattern_
            # If JSON keys are like "some_pattern", remove potential trailing underscore
            jq_lookup_name="${original_pattern_name_from_file%_}" # Remove one trailing underscore if present

            if [ -n "$jq_lookup_name" ]; then
                description=$(jq -r --arg pat_name "$jq_lookup_name" '.patterns[] | select(.patternName == $pat_name) | .description' "$PATTERN_DESCRIPTIONS_FILE")
                
                # Check if jq found a description
                # Use [[ ]] for more robust string comparison and -n for non-empty check
                if [[ "$description" != "null" && -n "$description" ]]; then
                    echo "  Found description in JSON for $jq_lookup_name"
                else
                    description="" # Reset if not found or null, to trigger file extraction
                    echo "  Description for $jq_lookup_name not found in JSON or was null."
                fi
            else
                 echo "  Warning: Could not derive a valid original pattern name from $filename_no_ext for JSON lookup."
            fi
        fi

        # If description is still empty (not found in JSON or not a fabric_ pattern), extract from file content
        if [ -z "$description" ]; then
            echo "  Extracting description from file: $filename_with_ext"
            description_from_file=$(head -c 2500 "$prompt_file" | tr '\n' ' ' | sed -E \
                -e 's/<[^>]*>//g' \
                -e 's/!\[[^]]*\]\([^)]*\)//g' \
                -e 's/\[[^\]]*\]\([^)]*\)//g' \
                -e 's/#{1,6} //g' \
                -e 's/[*_`~]{1,3}//g' \
                -e 's/---[^-]*---//g' \
                | tr -s ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | cut -c1-500)

            if [ -n "$description_from_file" ]; then
                description="$description_from_file..."
            else
                description="No description available."
            fi
        fi

        echo "## [$filename_no_ext](./$filename_with_ext)" >> "$INDEX_FILE_PATH"
        echo "" >> "$INDEX_FILE_PATH"
        echo "*Description:* $description" >> "$INDEX_FILE_PATH"
        echo "" >> "$INDEX_FILE_PATH"
        echo "---" >> "$INDEX_FILE_PATH" # Simpler horizontal rule
        echo "" >> "$INDEX_FILE_PATH"
    fi
done

echo "Prompt index generation complete!"
echo "Index file: $INDEX_FILE_PATH"
echo "-----------------------------------------------------"
# ---- END INDEX GENERATION ----

