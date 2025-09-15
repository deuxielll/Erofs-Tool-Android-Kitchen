# Unpack functions for erofs-helper

unpack_main() {
    # Check if image file is provided
    if [ $# -ne 1 ]; then
        echo -e "${YELLOW}Usage: $0 unpack <image_file>${RESET}"
        echo -e "Example: $0 unpack vendor.img"
        exit 1
    fi

    IMAGE_FILE="$1"
    PARTITION_NAME=$(basename "$IMAGE_FILE" .img)
    EXTRACT_DIR="./extracted_images/extracted_${PARTITION_NAME}"

    # Handle different file types
    case "$IMAGE_FILE" in
        *.tar|*.tar.md5)
            echo "Unpacking .tar file..."
            mkdir -p "$EXTRACT_DIR"
            tar -xf "$IMAGE_FILE" -C "$EXTRACT_DIR"
            echo "Extraction complete."
            
            # Clean up temporary files
            echo -e "\nCleaning up temporary files..."
            rm -rf "$MOUNT_DIR"
            
            # Go back to the main menu or previous state
            # (Assuming there's a function or mechanism to handle this)
            return 0
            ;;
        *.zip)
            echo "Unpacking .zip file..."
            mkdir -p "$EXTRACT_DIR"
            unzip "$IMAGE_FILE" -d "$EXTRACT_DIR"
            echo "Extraction complete."
            exit 0
            ;;
        *.7z)
            echo "Unpacking .7z file..."
            mkdir -p "$EXTRACT_DIR"
            7z x "$IMAGE_FILE" -o"$EXTRACT_DIR"
            echo "Extraction complete."
            exit 0
            ;;
        *.lz4)
            echo "Unpacking .lz4 file..."
            mkdir -p "$EXTRACT_DIR"
            lz4 -d "$IMAGE_FILE" "$EXTRACT_DIR/$(basename "$IMAGE_FILE" .lz4)"
            echo "Extraction complete."
            exit 0
            ;;
    esac

    MOUNT_DIR="/tmp/${PARTITION_NAME}_mount"
    REPACK_INFO="${EXTRACT_DIR}/.repack_info"
    RAW_IMAGE="${IMAGE_FILE%.img}_raw.img"
    FS_CONFIG_FILE="${REPACK_INFO}/fs-config.txt"
    FILE_CONTEXTS_FILE="${REPACK_INFO}/file_contexts.txt"

    # Check if image file exists
    if [ ! -f "$IMAGE_FILE" ]; then
      echo -e "${RED}Error: Image file '$IMAGE_FILE' not found.${RESET}"
      exit 1
    fi

    # Create or recreate mount directory
    if [ -d "$MOUNT_DIR" ]; then
      echo -e "${YELLOW}Removing existing mount directory...${RESET}"
      rm -rf "$MOUNT_DIR"
    fi
    mkdir -p "$MOUNT_DIR"

    # Create extraction and repack info directories
    if [ -d "$EXTRACT_DIR" ]; then
      echo -e "${YELLOW}Removing existing extraction directory: ${EXTRACT_DIR}${RESET}"
      rm -rf "$EXTRACT_DIR"
    fi
    mkdir -p "$EXTRACT_DIR"
    mkdir -p "$REPACK_INFO"

    # Try to mount the image
    echo -e "Attempting to mount ${BOLD}$IMAGE_FILE${RESET}..."
    if ! mount -o loop,ro "$IMAGE_FILE" "$MOUNT_DIR" 2>/dev/null; then
      echo -e "${YELLOW}Direct mounting failed. Trying to convert image...${RESET}"
      
      # Try to determine image format
      IMAGE_TYPE=$(file "$IMAGE_FILE" | grep -o -E 'Android.*|Linux.*|EROFS.*|data')
      
      if [ -n "$IMAGE_TYPE" ]; then
        echo -e "${BLUE}Detected image type: ${BOLD}$IMAGE_TYPE${RESET}"
        
        # Create a raw copy to try mounting
        echo -e "${BLUE}Creating raw image as ${BOLD}$RAW_IMAGE${RESET}${BLUE}...${RESET}"
        
        # Try using simg2img for sparse images
        if command -v simg2img &> /dev/null; then
          echo -e "${BLUE}Converting with simg2img...${RESET}"
          simg2img "$IMAGE_FILE" "$RAW_IMAGE"
        else
          # Simple copy as fallback
          echo -e "${YELLOW}simg2img not found, creating direct copy...${RESET}"
          cp "$IMAGE_FILE" "$RAW_IMAGE"
        fi
        
        echo -e "${BLUE}Attempting to mount raw image...${RESET}"
        if ! mount -o loop,ro "$RAW_IMAGE" "$MOUNT_DIR" 2>/dev/null; then
          echo -e "${RED}Failed to mount even after conversion. No luck with this image.${RESET}"
          exit 1
        fi
        
        echo -e "${GREEN}Successfully mounted raw image.${RESET}"
      else
        echo -e "${RED}Failed to identify image type for conversion. No luck with this image.${RESET}"
        exit 1
      fi
    else
      echo -e "${GREEN}Successfully mounted original image.${RESET}"
    fi

    # First get root directory context specifically
    echo -e "\n${BLUE}Capturing root directory attributes...${RESET}"
    ROOT_CONTEXT=$(ls -dZ "$MOUNT_DIR" | awk '{print $1}')
    ROOT_STATS=$(stat -c "%u %g %a" "$MOUNT_DIR")

    # Create config files with root attributes first
    echo "# FS config extracted from $IMAGE_FILE on $(date)" > "$FS_CONFIG_FILE"
    echo "/ $ROOT_STATS" >> "$FS_CONFIG_FILE"

    echo "# File contexts extracted from $IMAGE_FILE on $(date)" > "$FILE_CONTEXTS_FILE"
    echo "/ $ROOT_CONTEXT" >> "$FILE_CONTEXTS_FILE"

    # Extract metadata with progress
    echo -e "\n${BLUE}Extracting file attributes...${RESET}"
    total_items=$(find "$MOUNT_DIR" -mindepth 1 | wc -l)
    processed=0

    # Create a special file for symlink info
    SYMLINK_INFO="${REPACK_INFO}/symlink_info.txt"
    echo "# Symlink info extracted from $IMAGE_FILE on $(date)" > "$SYMLINK_INFO"

    find "$MOUNT_DIR" -mindepth 1 | while read -r item; do
        processed=$((processed + 1))
        show_progress $processed $total_items "Extracting attributes"
        
        rel_path=${item#$MOUNT_DIR}
        
        # Special handling for symlinks
        if [ -L "$item" ]; then
            target=$(readlink "$item")
            stats=$(stat -c "%u %g %a" "$item" 2>/dev/null)
            context=$(ls -dZ "$item" 2>/dev/null | awk '{print $1}')
            echo "$rel_path $target $stats $context" >> "$SYMLINK_INFO"
        else
            # Get basic attributes and context
            stats=$(stat -c "%u %g %a" "$item" 2>/dev/null)
            context=$(ls -dZ "$item" 2>/dev/null | awk '{print $1}')
            
            [ -n "$stats" ] && echo "$rel_path $stats" >> "$FS_CONFIG_FILE"
            [ -n "$context" ] && [ "$context" != "?" ] && echo "$rel_path $context" >> "$FILE_CONTEXTS_FILE"
        fi
    done
    echo -e "\n${GREEN}[✓] Attributes extracted successfully${RESET}\n"

    # Calculate checksums with spinner
    echo -e "${BLUE}Calculating original file checksums...${RESET}"
    (cd "$MOUNT_DIR" && find . -type f -exec sha256sum {} \;) > "${REPACK_INFO}/original_checksums.txt" &
    spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    spin=0
    while kill -0 $! 2>/dev/null; do
        # Clear entire line first
        echo -ne "\r\033[K${BLUE}[${spinner[$((spin++ % 10))]}] Generating checksums${RESET}"
        sleep 0.1
    done

    # Clear line and show completion
    echo -e "\r\033[K${GREEN}[✓] Checksums generated${RESET}\n"

    # Copy files with SELinux contexts preserved
    echo -e "${BLUE}Copying files with preserved attributes...${RESET}"
    echo -e "${BLUE}┌─ Source: ${MOUNT_DIR}${RESET}"
    echo -e "${BLUE}└─ Target: ${EXTRACT_DIR}${RESET}\n"

    # Use tar with selinux flag for proper context preservation
    (cd "$MOUNT_DIR" && tar --selinux -cf - .) | (cd "$EXTRACT_DIR" && tar --selinux -xf -) & 
    show_copy_progress $! "$MOUNT_DIR" "$EXTRACT_DIR" "Copying files"
    wait $!

    # Verify copy succeeded
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Files copied successfully with SELinux contexts${RESET}"
    else
        echo -e "\n${RED}[!] Error occurred during copy${RESET}"
        exit 1
    fi

    # Store timestamp and metadata location for repacking
    echo "UNPACK_TIME=$(date +%s)" > "${REPACK_INFO}/metadata.txt"
    echo "SOURCE_IMAGE=$IMAGE_FILE" >> "${REPACK_INFO}/metadata.txt"

    # Verify extraction
    if [ $? -eq 0 ]; then
      echo -e "\n${GREEN}Extraction completed successfully.${RESET}"
      echo -e "${BOLD}Files extracted to: ${EXTRACT_DIR}${RESET}"
      echo -e "${BOLD}Repack info stored in: ${REPACK_INFO}${RESET}"
      echo -e "${BOLD}File contexts saved to: ${FILE_CONTEXTS_FILE}${RESET}"
      echo -e "${BOLD}FS config saved to: ${FS_CONFIG_FILE}${RESET}\n"

      # Transfer ownership to actual user
      if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$EXTRACT_DIR"
      fi
    else
      echo -e "${RED}Error occurred during extraction.${RESET}"
      exit 1
    fi

    # Unmount the image
    if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
      umount "$MOUNT_DIR"
      echo -e "\n${GREEN}Image unmounted successfully.${RESET}"
    fi
}
