#!/bin/zsh

# This script generates an index file for Fabric patterns and user prompts.
# - Fabric patterns are linked directly to GitHub
# - User prompts are linked to local files in 'docs/my_prompts_consolidated/'
# Example: /Users/mcferney/Development_Projects/Prompt Library/fabric/consolidate_prompts.sh
# To run: cd /Users/mcferney/Development_Projects/Prompt Library/fabric/ && ./consolidate_prompts.sh

# Define configuration variables
# All paths are relative to the 'fabric' directory (where the script is run).
TARGET_DIR="docs/my_prompts_consolidated" # Directory for consolidated user prompts
MY_PROMPTS_DIR="docs/my_prompts" # Default input: fabric/docs/my_prompts/
PARENT_DIR="../" # Access parent directory for possible prompt sources
PARENT_MY_PROMPTS_DIR="../my_prompts" # Try to look for my_prompts in parent directory
FABRIC_REPO_URL="https://github.com/danielmiessler/fabric"
FABRIC_PATTERNS_PATH="patterns" # Path within the GitHub repo where patterns are stored
FABRIC_PATTERN_EXTRACTS_URL="https://raw.githubusercontent.com/danielmiessler/fabric/main/Pattern_Descriptions/pattern_extracts.json" # URL to fetch pattern descriptions
PATTERN_EXTRACTS_TEMP_FILE="/tmp/fabric_pattern_extracts.json" # Temporary file to store downloaded pattern extracts

echo "Prompt indexing script started (running from 'fabric/' directory)."
echo "Target directory for consolidated user prompts: ./${TARGET_DIR}"
echo "User prompts source directory: ./${MY_PROMPTS_DIR}"

# Ensure target directory exists
echo "Checking target directory..."
mkdir -p "./${TARGET_DIR}" # Create the target directory inside fabric/ if it doesn't exist
if [ $? -ne 0 ]; then echo "Error: Could not create/check target directory './${TARGET_DIR}'. Exiting."; exit 1; fi
echo "Target directory './${TARGET_DIR}' verified."

# Process user's prompts - try multiple possible locations
echo "Searching for user's prompts..."

# Array of possible prompt directories to check
potential_prompt_dirs=(
    "./${MY_PROMPTS_DIR}"                 # Default: fabric/docs/my_prompts
    "${PARENT_MY_PROMPTS_DIR}"            # Parent-level: ../my_prompts
    "../fabric/docs/my_prompts"           # Another possible location
    "./../my_prompts"                     # Alternative parent format
)

found_prompts=false

for prompt_dir in "${potential_prompt_dirs[@]}"; do
    echo "Checking for prompts in: $prompt_dir"
    
    if [ -d "$prompt_dir" ]; then
        echo "Found prompts directory: $prompt_dir"
        
        # Check if directory contains .md files
        md_file_count=$(find "$prompt_dir" -maxdepth 1 -type f -name "*.md" | wc -l)
        if [ "$md_file_count" -eq 0 ]; then
            echo "  No markdown files found in $prompt_dir"
            continue
        fi
        
        for user_prompt_file in "$prompt_dir"/*.md; do
            if [ -f "$user_prompt_file" ]; then
                base_filename=$(basename "$user_prompt_file" .md)
                sanitized_name=$(echo "$base_filename" | tr -s '[:space:]' '_' | tr -cd '[:alnum:]_-.')
                
                if [ -n "$sanitized_name" ]; then
                    cp "$user_prompt_file" "./${TARGET_DIR}/myprompt_${sanitized_name}.md"
                    
                    if [ $? -eq 0 ]; then
                        echo "  Copied user prompt: myprompt_${sanitized_name}.md to ./${TARGET_DIR}/"
                        found_prompts=true
                    else
                        echo "  Warning: Failed to copy user prompt from $user_prompt_file"
                    fi
                else
                    echo "  Warning: Could not derive a valid name from user prompt file: $user_prompt_file"
                fi
            else
                echo "  Skipping non-file item in user prompts directory: $user_prompt_file"
            fi
        done
        
        echo "Finished processing user's prompts from $prompt_dir"
    else
        echo "  Directory not found: $prompt_dir"
    fi
done

# Check if any parent directory might have .md files directly
echo "Checking parent directory for .md files..."
parent_md_files=$(find "$PARENT_DIR" -maxdepth 1 -type f -name "*.md" | wc -l)
if [ "$parent_md_files" -gt 0 ]; then
    echo "Found markdown files in parent directory, copying them..."
    for user_prompt_file in "$PARENT_DIR"/*.md; do
        if [ -f "$user_prompt_file" ]; then
            base_filename=$(basename "$user_prompt_file" .md)
            sanitized_name=$(echo "$base_filename" | tr -s '[:space:]' '_' | tr -cd '[:alnum:]_-.')
            
            if [ -n "$sanitized_name" ]; then
                cp "$user_prompt_file" "./${TARGET_DIR}/myprompt_${sanitized_name}.md"
                
                if [ $? -eq 0 ]; then
                    echo "  Copied user prompt from parent dir: myprompt_${sanitized_name}.md to ./${TARGET_DIR}/"
                    found_prompts=true
                else
                    echo "  Warning: Failed to copy user prompt from $user_prompt_file"
                fi
            fi
        fi
    done
fi

if [ "$found_prompts" = false ]; then
    echo "No user prompts found in any expected locations."
    echo "Will use existing prompts in ./${TARGET_DIR}/ if available."
fi

echo "-----------------------------------------------------
User prompts consolidation complete!
Your prompts are now in the './${TARGET_DIR}/' directory.
-----------------------------------------------------"

# ---- BEGIN INDEX GENERATION ----
echo
echo "Generating prompt index..."

# Index file path - directly in docs directory
INDEX_FILE_PATH="./docs/index.md"

# Initialize INDEX.md
echo "# Consolidated Prompt Index" > "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"
# Use a date format without time or timezone to avoid issues
current_date=$(LC_ALL=C date "+%B %d, %Y")
echo "Last updated: $current_date" >> "$INDEX_FILE_PATH" 
echo "" >> "$INDEX_FILE_PATH"

echo "## Fabric Patterns" >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"
echo "These prompts link directly to the [danielmiessler/fabric](${FABRIC_REPO_URL}) GitHub repository." >> "$INDEX_FILE_PATH"
echo "" >> "$INDEX_FILE_PATH"

# Check if required tools are installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq command could not be found. You need jq to process Fabric pattern descriptions."
    echo "Please install jq with: brew install jq"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "Error: curl command could not be found. You need curl to download pattern descriptions."
    echo "Please install curl to continue."
    exit 1
fi

# Download pattern extracts directly from GitHub
echo "Downloading pattern extracts from GitHub..."
curl -s -H "Accept: application/vnd.github.v3.raw" "$FABRIC_PATTERN_EXTRACTS_URL" -o "$PATTERN_EXTRACTS_TEMP_FILE"

if [ $? -ne 0 ] || [ ! -s "$PATTERN_EXTRACTS_TEMP_FILE" ]; then
    echo "Warning: Failed to download pattern extracts from GitHub or file is empty."
    
    # Add placeholder message for Fabric patterns
    echo "Unable to fetch pattern descriptions from GitHub. Fabric patterns are available at:" >> "$INDEX_FILE_PATH"
    echo "${FABRIC_REPO_URL}/tree/main/${FABRIC_PATTERNS_PATH}" >> "$INDEX_FILE_PATH"
    echo "" >> "$INDEX_FILE_PATH"
else
    # Apply a much more robust preprocessing to clean the JSON file
    echo "Preprocessing JSON to fix formatting issues..."
    ESCAPED_JSON_TEMP_FILE="/tmp/fabric_pattern_extracts_escaped.json"
    FIXED_JSON_TEMP_FILE="/tmp/fabric_pattern_extracts_fixed.json"
    
    echo "Step 1: Clean up control characters and escape sequences..."
    # First pass: Remove all control characters that interfere with JSON parsing
    perl -pe 's/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]//g' "$PATTERN_EXTRACTS_TEMP_FILE" > "$ESCAPED_JSON_TEMP_FILE"
    
    # Check if the file starts with a valid JSON character
    first_char=$(head -c 1 "$ESCAPED_JSON_TEMP_FILE")
    if [[ "$first_char" != "{" && "$first_char" != "[" ]]; then
        echo "Warning: JSON file does not start with a valid JSON character. Fixing header..."
        # Find the first occurrence of { or [ and trim everything before it
        perl -ne 'if(/^[{\[]/) {print; $found=1} elsif($found) {print}' "$ESCAPED_JSON_TEMP_FILE" > "${ESCAPED_JSON_TEMP_FILE}.tmp"
        mv "${ESCAPED_JSON_TEMP_FILE}.tmp" "$ESCAPED_JSON_TEMP_FILE"
    fi
    
    echo "Step 2: Fixing invalid escape sequences and normalize line endings..."
    # Replace problematic sequences that often break JSON parsing
    perl -pe '
        # Fix common escape sequence issues
        s/\\(?!["\\/bfnrt])/\\\\/g;
        # Normalize line endings
        s/\r\n/\\n/g;
        s/\n/\\n/g;
        # Fix broken quote escaping
        s/(?<!\\)\\"/\\\\"/g;
        # Handle percent symbols that break JSON parsing
        s/%$/%\\n/g;
    ' "$ESCAPED_JSON_TEMP_FILE" > "$FIXED_JSON_TEMP_FILE"
    
    # Validate JSON structure
    echo "Step 3: Validating processed JSON structure..."
    if jq -e '.' "$FIXED_JSON_TEMP_FILE" >/dev/null 2>&1; then
        echo "JSON validation successful!"
        mv "$FIXED_JSON_TEMP_FILE" "$ESCAPED_JSON_TEMP_FILE"
    else
        echo "Error: Initial JSON validation failed. Attempting deeper repair..."
        
        # Try a completely different approach - rebuild the JSON structure
        echo "Step 4: Rebuilding JSON structure..."
        echo '{' > "$FIXED_JSON_TEMP_FILE"
        echo '  "patterns": [' >> "$FIXED_JSON_TEMP_FILE"
        
        # Extract each pattern entry individually with perl
        perl -n -e '
            if (/^\s*{\s*"patternName":\s*"([^"]+)"/) {
                $pattern_name = $1;
                $started = 1;
                $json = "    {\n      \"patternName\": \"$pattern_name\",\n";
            }
            elsif ($started && /^\s*"pattern_extract":\s*"/) {
                $json .= "      \"pattern_extract\": \"";
                $in_extract = 1;
            }
            elsif ($in_extract && /^\s*}/) {
                $json .= "\"\n    },\n";
                print $json;
                $started = 0;
                $in_extract = 0;
            }
            elsif ($in_extract) {
                # Clean the line for pattern_extract
                $_ =~ s/"/\\"/g;  # Escape quotes
                $_ =~ s/\\/\\\\/g; # Escape backslashes
                $_ =~ s/\n/\\n/g;  # Escape newlines
                $_ =~ s/\r//g;     # Remove carriage returns
                $_ =~ s/[\x00-\x1F]//g; # Remove control chars
                chomp;
                $json .= $_;
            }
        ' "$PATTERN_EXTRACTS_TEMP_FILE" >> "$FIXED_JSON_TEMP_FILE"
        
        # Remove trailing comma if it exists
        perl -i -pe 's/,\s*$/\n/' "$FIXED_JSON_TEMP_FILE"
        
        # Close the JSON structure
        echo '  ]' >> "$FIXED_JSON_TEMP_FILE"
        echo '}' >> "$FIXED_JSON_TEMP_FILE"
        
        # Validate the rebuilt JSON
        if jq -e '.' "$FIXED_JSON_TEMP_FILE" >/dev/null 2>&1; then
            echo "JSON rebuild successful!"
            mv "$FIXED_JSON_TEMP_FILE" "$ESCAPED_JSON_TEMP_FILE"
        else
            echo "Error: JSON rebuild failed. Will use GitHub API fallback."
            cp "$PATTERN_EXTRACTS_TEMP_FILE" "$ESCAPED_JSON_TEMP_FILE"
        fi
    }
    
    # Check for patterns array
    if ! jq -e '.patterns' "$ESCAPED_JSON_TEMP_FILE" >/dev/null 2>&1; then
        echo "Warning: Downloaded JSON file validation failed. The patterns array might be missing."            echo "Attempting to fetch pattern directories directly from GitHub..."
            # Try to get pattern directories directly from GitHub API
            GITHUB_API_REPO_CONTENTS="https://api.github.com/repos/danielmiessler/fabric/contents/patterns"
            PATTERN_DIR_TEMP_FILE="/tmp/fabric_pattern_dirs.json"
            
            # Get the list of directories in the patterns folder
            echo "Fetching pattern directories from GitHub API..."
            curl -s -H "Accept: application/vnd.github+json" "$GITHUB_API_REPO_CONTENTS" -o "$PATTERN_DIR_TEMP_FILE"
            
            if [ $? -eq 0 ] && [ -s "$PATTERN_DIR_TEMP_FILE" ] && jq -e '.' "$PATTERN_DIR_TEMP_FILE" >/dev/null 2>&1; then
                echo "Successfully fetched pattern directories from GitHub API"
                
                # Filter only directories
                DIR_COUNT=$(jq 'map(select(.type == "dir")) | length' "$PATTERN_DIR_TEMP_FILE" 2>/dev/null)
                
                if [ -z "$DIR_COUNT" ]; then
                    DIR_COUNT=0
                fi
                
                echo "Found $DIR_COUNT pattern directories"
                
                if [ "$DIR_COUNT" -gt 0 ]; then
                    # Process each directory
                    jq -c 'map(select(.type == "dir"))[]' "$PATTERN_DIR_TEMP_FILE" | while read -r dir_entry; do
                        pattern_name=$(echo "$dir_entry" | jq -r '.name')
                        if [ -n "$pattern_name" ] && [ "$pattern_name" != "null" ]; then
                            # Format pattern name for better display
                            # Replace underscores with spaces and capitalize first letter of each word
                            formatted_pattern_name=$(echo "$pattern_name" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
                            
                            # Create link to the pattern's system.md file (error handling for path)
                            if [ -n "$pattern_name" ]; then
                                github_link="${FABRIC_REPO_URL}/blob/main/${FABRIC_PATTERNS_PATH}/${pattern_name}/system.md"
                            else
                                github_link="${FABRIC_REPO_URL}/blob/main/${FABRIC_PATTERNS_PATH}"
                            fi
                            
                            # Display name with fabric: prefix
                            display_name="fabric: $formatted_pattern_name"
                            
                            # Add to INDEX.md (only if pattern_name is not empty)
                            if [ -n "$pattern_name" ]; then
                                echo "### [$display_name]($github_link)" >> "$INDEX_FILE_PATH"
                                echo "" >> "$INDEX_FILE_PATH"
                                echo "*Description:* Pattern description not available." >> "$INDEX_FILE_PATH"
                                echo "" >> "$INDEX_FILE_PATH"
                                echo "---" >> "$INDEX_FILE_PATH"
                                echo "" >> "$INDEX_FILE_PATH"
                                echo "Indexed pattern: $pattern_name"
                            fi
                        fi
                    done
                    
                    # Clean up temp file
                    rm -f "$PATTERN_DIR_TEMP_FILE"
                else
                    # Add placeholder message for Fabric patterns
                    echo "No patterns found via GitHub API. Fabric patterns are available at:" >> "$INDEX_FILE_PATH"
                    echo "${FABRIC_REPO_URL}/tree/main/${FABRIC_PATTERNS_PATH}" >> "$INDEX_FILE_PATH"
                    echo "" >> "$INDEX_FILE_PATH"
                fi
            else
                # Add placeholder message for Fabric patterns
                echo "Pattern extracts JSON file from GitHub is malformed. Fabric patterns are available at:" >> "$INDEX_FILE_PATH"
                echo "${FABRIC_REPO_URL}/tree/main/${FABRIC_PATTERNS_PATH}" >> "$INDEX_FILE_PATH"
                echo "" >> "$INDEX_FILE_PATH"
                
                # Clean up temp file
                rm -f "$PATTERN_DIR_TEMP_FILE"
            fi
    else
        # Count patterns in JSON file
        pattern_count=$(jq '.patterns | length' "$ESCAPED_JSON_TEMP_FILE")
        echo "Found $pattern_count patterns in the downloaded JSON file"
        
        if [ "$pattern_count" -eq 0 ]; then
            echo "Warning: No patterns found in downloaded JSON file."
            
            # Add placeholder message for Fabric patterns
            echo "No patterns found in the downloaded JSON file. Fabric patterns are available at:" >> "$INDEX_FILE_PATH"
            echo "${FABRIC_REPO_URL}/tree/main/${FABRIC_PATTERNS_PATH}" >> "$INDEX_FILE_PATH"
            echo "" >> "$INDEX_FILE_PATH"
        else
            # Process each pattern
            jq -c '.patterns[]' "$ESCAPED_JSON_TEMP_FILE" | while read -r pattern; do
                pattern_name=$(echo "$pattern" | jq -r '.patternName')
                # Use pattern_extract field instead of description
                pattern_extract=$(echo "$pattern" | jq -r '.pattern_extract')
                
                echo "Processing pattern: $pattern_name"
                
                # Skip if pattern name is empty or null
                if [ -z "$pattern_name" ] || [ "$pattern_name" = "null" ]; then
                    echo "Warning: Empty pattern name found, skipping..."
                    continue
                fi
                
                # Create GitHub link to the pattern's system.md file
                github_link="${FABRIC_REPO_URL}/blob/main/${FABRIC_PATTERNS_PATH}/${pattern_name}/system.md"
                
                # Format pattern name for better display
                # Replace underscores with spaces, capitalize first letter of each word
                formatted_pattern_name=$(echo "$pattern_name" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
                
                # Display name with fabric: prefix for readability
                display_name="fabric: $formatted_pattern_name"
                
                # Extract a brief description from the pattern_extract (first 300 characters)
                if [[ -n "$pattern_extract" && "$pattern_extract" != "null" ]]; then
                    # Clean up the extract to make it more readable as a description
                    description=$(echo "$pattern_extract" | tr '\n' ' ' | sed -E \
                        -e 's/<[^>]*>//g' \
                        -e 's/!\[[^]]*\]\([^)]*\)//g' \
                        -e 's/\[[^\]]*\]\([^)]*\)//g' \
                        -e 's/#{1,6} //g' \
                        -e 's/[*_`~]{1,3}//g' \
                        -e 's/\{\{/( (/g' \
                        -e 's/\}\}/) )/g' \
                        -e 's/\{%/( %/g' \
                        -e 's/%\}/% )/g' \
                        | tr -s ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | cut -c1-300)
                    description="${description}..."
                else
                    description="No description available."
                fi
                
                # Add to INDEX.md
                echo "### [$display_name]($github_link)" >> "$INDEX_FILE_PATH"
                echo "" >> "$INDEX_FILE_PATH"
                echo "*Description:* $description" >> "$INDEX_FILE_PATH"
                echo "" >> "$INDEX_FILE_PATH"
                echo "---" >> "$INDEX_FILE_PATH"
                echo "" >> "$INDEX_FILE_PATH"
            done
        fi
    fi
    
    # Clean up the temporary files
    rm -f "$PATTERN_EXTRACTS_TEMP_FILE"
    rm -f "$ESCAPED_JSON_TEMP_FILE"
fi

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
        
        # Extract and format a clean title from the filename
        # 1. Remove "myprompt_" prefix
        # 2. Replace underscores and hyphens with spaces
        # 3. Remove trailing underscores/spaces
        clean_title="${filename_no_ext#myprompt_}"
        clean_title="${clean_title//_/ }"
        clean_title="${clean_title//-/ }"
        # Remove trailing underscores or spaces
        clean_title="${clean_title%_*}"
        clean_title="${clean_title% }"
        
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
        
        # Add to INDEX.md - link to the local file using clean title for display
        echo "### [$clean_title](./my_prompts_consolidated/$filename_with_ext)" >> "$INDEX_FILE_PATH"
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

