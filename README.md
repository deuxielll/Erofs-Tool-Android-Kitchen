# EROFS Helper Script

A versatile script for unpacking and repacking Android system images on Linux. It supports various filesystems like EXT4, EROFS, and F2FS, and meticulously preserves file attributes such as xattrs, contexts, ownership, and permissions.

This script provides an interactive, menu-driven interface to simplify the process of modding Android images.

## Features

-   **Interactive Menu:** Easy-to-use menu for unpacking, repacking, and cleaning.
-   **Multiple Filesystem Support:** Works with EROFS, EXT4, and F2FS images.
-   **Archive Support:** Can unpack various archive formats including `.tar`, `.zip`, `.7z`, and `.lz4`.
-   **Attribute Preservation:** Correctly handles and restores SELinux contexts, file permissions, and ownership.
-   **Dependency Checker:** Automatically checks for required tools and offers to install them on Debian-based systems.
-   **Workspace Management:** Keeps source images, extracted files, and repacked images organized in separate directories.

## Preview

![Main Menu](https://user-images.githubusercontent.com/893307# EROFS Helper Script

A versatile script for unpacking and repacking Android system images on Linux. It supports various filesystems like EXT4, EROFS, and F2FS, and meticulously preserves file attributes such as xattrs, contexts, ownership, and permissions.

This script provides an interactive, menu-driven interface to simplify the process of modding Android images.

## Features

-   **Interactive Menu:** Easy-to-use menu for unpacking, repacking, and cleaning.
-   **Multiple Filesystem Support:** Works with EROFS, EXT4, and F2FS images.
-   **Archive Support:** Can unpack various archive formats including `.tar`, `.zip`, `.7z`, and `.lz4`.
-   **Attribute Preservation:** Correctly handles and restores SELinux contexts, file permissions, and ownership.
-   **Dependency Checker:** Automatically checks for required tools and offers to install them on Debian-based systems.
-   **Workspace Management:** Keeps source images, extracted files, and repacked images organized in separate directories.

## Preview

[![Erofs-Tools](https://fsgezdakoianpjhingyz.supabase.co/storage/v1/object/public/images/046a2967-8d7b-4349-9db9-70db0ac4bd56.png)](https://fsgezdakoianpjhingyz.supabase.co/storage/v1/object/public/images/046a2967-8d7b-4349-9db9-70db0ac4bd56.png)

1.  **Place your images:** Copy the image files you want to unpack into the `original_images` directory.
2.  **Run the script:** Execute the main helper script with root privileges:
    ```bash
    sudo ./erofs-helper.sh
    ```
3.  **Choose an option from the menu:**
    *   **Unpack an image:** Select an image file from the `original_images` directory to extract. The contents will be placed in a new folder inside the `extracted_images` directory.
    *   **Repack a directory:** Choose a directory from `extracted_images` to repack into a new image. You will be prompted to select the output filesystem (EROFS or EXT4) and compression options. The new image will be saved in the `repacked_images` directory.
    *   **Clean All (Danger):** Deletes the contents of the `original_images`, `extracted_images`, and `repacked_images` directories to provide a clean workspace.
    *   **Exit:** Closes the script.

### F2FS Filesystem Support

For F2FS filesystem support, you may need to load the kernel module first:
```bash
sudo modprobe f2fs
```

## Credits

-   Original scripts by **@ravindu644**
-   Enhancements and interactive menu by **@deuxielll**
-   `erofs-utils` by the **EROFS team**

