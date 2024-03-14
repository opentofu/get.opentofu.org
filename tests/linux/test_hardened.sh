#!/bin/bash

# Set a restrictive umask
simulate_hardened_umask() {
    umask 0027
}

# Function to perform installation steps
perform_installation() {
    pushd ../../src
    ./install-opentofu.sh --install-method deb
    popd
}

# Function to check permissions after installation
check_permissions() {
    # Define an array of file paths to check
    local file_paths=(
        "/etc/apt/keyrings/opentofu.gpg"
        "/etc/apt/keyrings/opentofu-repo.gpg"
        "/etc/apt/sources.list.d/opentofu.list"
    )

    # Loop through file paths and check permissions
    for file_path in "${file_paths[@]}"; do
        local permissions=$(stat -c %a "$file_path")
        echo "Permissions for $file_path: $permissions"
        if [ "${permissions}" != "644" ]; then
            echo "Test failed: Incorrect permissions for $file_path"
            exit 1
        fi
    done
}

# Main test execution
simulate_hardened_umask
perform_installation
check_permissions

echo "Test passed: Installation and permissions check completed successfully."