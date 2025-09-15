#!/bin/bash
# EROFS Helper Script: Unpack and Repack EROFS/EXT4 images
# Original scripts by @ravindu644
# Combined and enhanced by GitHub Copilot

set -e

# Source the function files
source ./src/common.sh
source ./src/unpack.sh
source ./src/repack.sh

# --- Script Entry Point ---

main() {
    clear
    print_banner

    # Check for root privileges
    if [ "$EUID" -ne 0 ]; then
      echo -e "${RED}This script requires root privileges. Please run with sudo.${RESET}"
      exit 1
    fi

    check_dependencies

    # Register cleanup for interrupts and errors
    trap 'cleanup ERROR' INT TERM EXIT

    while true; do
        clear
        print_banner
        local main_options=("Unpack an image" "Repack a directory" "${RED}Clean All (Danger)${RESET}" "Exit")
        local main_choice_index=0

        while true; do
            create_menu "$main_choice_index" "EROFS Helper Menu" "${main_options[@]}"
            
            read -rsn1 key
            case "$key" in
                $'\x1b') # ANSI escape sequence
                    read -rsn2 key
                    case "$key" in
                        '[A') # Up arrow
                            main_choice_index=$(( (main_choice_index - 1 + ${#main_options[@]}) % ${#main_options[@]} ))
                            ;;
                        '[B') # Down arrow
                            main_choice_index=$(( (main_choice_index + 1) % ${#main_options[@]} ))
                            ;;
                    esac
                    ;;
                "") # Enter key
                    break
                    ;;
            esac
        done
        
        tput cnorm # Restore cursor

        case $main_choice_index in
            0) # Unpack
                image_files=($(find ./original_images -maxdepth 1 -type f))
                
                if [ ${#image_files[@]} -eq 0 ]; then
                    clear
                    print_banner
                    echo -e "\n${RED}No image files found in ./original_images/${RESET}"
                    read -p "Press Enter to return to the main menu..."
                    continue
                fi

                image_files+=("Go Back")
                local image_choice_index=0
                while true; do
                    create_menu "$image_choice_index" "Select an image to unpack" "${image_files[@]}"
                    read -rsn1 key
                    case "$key" in
                        $'\x1b')
                            read -rsn2 key
                            case "$key" in
                                '[A')
                                    image_choice_index=$(( (image_choice_index - 1 + ${#image_files[@]}) % ${#image_files[@]} ))
                                    ;;
                                '[B')
                                    image_choice_index=$(( (image_choice_index + 1) % ${#image_files[@]} ))
                                    ;;
                            esac
                            ;;
                        "")
                            if [ "${image_files[$image_choice_index]}" == "Go Back" ]; then
                                break
                            else
                                unpack_main "${image_files[$image_choice_index]}"
                                read -p "Press Enter to return to the main menu..."
                                break
                            fi
                            ;;
                    esac
                done
                ;;
            1) # Repack
                dir_files=($(find ./extracted_images -maxdepth 1 -mindepth 1 -type d))

                if [ ${#dir_files[@]} -eq 0 ]; then
                    clear
                    print_banner
                    echo -e "\n${RED}No extracted directories found in ./extracted_images/${RESET}"
                    read -p "Press Enter to return to the main menu..."
                    continue
                fi

                dir_files+=("Go Back")
                local dir_choice_index=0
                while true; do
                    create_menu "$dir_choice_index" "Select a directory to repack" "${dir_files[@]}"
                    read -rsn1 key
                    case "$key" in
                        $'\x1b')
                            read -rsn2 key
                            case "$key" in
                                '[A')
                                    dir_choice_index=$(( (dir_choice_index - 1 + ${#dir_files[@]}) % ${#dirFiles[@]} ))
                                    ;;
                                '[B')
                                    dir_choice_index=$(( (dir_choice_index + 1) % ${#dirFiles[@]} ))
                                    ;;
                            esac
                            ;;
                        "")
                            if [ "${dir_files[$dir_choice_index]}" == "Go Back" ]; then
                                break
                            else
                                repack_main "${dir_files[$dir_choice_index]}"
                                read -p "Press Enter to return to the main menu..."
                                break
                            fi
                            ;;
                    esac
                done
                ;;
            2) # Clean All
                clean_all
                read -p "Press Enter to return to the main menu..."
                ;;
            3) # Exit
                clear
                print_banner
                echo -e "${YELLOW}Exiting.${RESET}"
                exit 0
                ;;
        esac
    done
}

main "$@"
