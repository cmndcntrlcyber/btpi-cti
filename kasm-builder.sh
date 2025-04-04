#!/bin/bash
#
# Kasm Workspaces Custom Image Builder
# This script builds and registers custom Kasm workspace images for CTI operations
#

set -e

# Configuration
KASM_SERVER="https://localhost:443"
KASM_USER="admin@kasm.local"
KASM_PASSWORD="password"
IMAGE_REGISTRY="default"
DOCKERFILE_DIR="./kasm-images"
OUTPUT_DIR="./kasm-builds"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Display help
show_help() {
    echo "Kasm Custom Image Builder"
    echo ""
    echo "Usage: $0 [options] [image_name]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Display this help message"
    echo "  -s, --server URL           Kasm server URL (default: $KASM_SERVER)"
    echo "  -u, --user USERNAME        Kasm admin username (default: $KASM_USER)"
    echo "  -p, --password PASSWORD    Kasm admin password"
    echo "  -l, --list                 List available custom image templates"
    echo "  -b, --build IMAGE          Build a specific image"
    echo "  -a, --build-all            Build all available images"
    echo "  -r, --register IMAGE       Register a built image with Kasm"
    echo "  --force                    Force rebuild even if image exists"
    echo ""
    echo "Examples:"
    echo "  $0 --list"
    echo "  $0 --build threat-hunting"
    echo "  $0 --build-all"
    echo "  $0 --register threat-hunting"
    echo ""
}

# List available custom image templates
list_templates() {
    echo "Available custom image templates:"
    echo ""
    
    if [ ! -d "$DOCKERFILE_DIR" ]; then
        echo "Error: Dockerfile directory not found: $DOCKERFILE_DIR"
        exit 1
    fi
    
    for dockerfile in "$DOCKERFILE_DIR"/*; do
        if [ -f "$dockerfile" ]; then
            base_name=$(basename "$dockerfile" .Dockerfile)
            echo "  - $base_name"
            
            # Get the description from the Dockerfile if available
            description=$(grep "# Description:" "$dockerfile" | sed 's/# Description: //')
            if [ ! -z "$description" ]; then
                echo "    $description"
            fi
            echo ""
        fi
    done
}

# Build a specific image
build_image() {
    local image_name=$1
    local force=$2
    
    echo "Building image: $image_name"
    
    # Check if the Dockerfile exists
    dockerfile="$DOCKERFILE_DIR/$image_name.Dockerfile"
    if [ ! -f "$dockerfile" ]; then
        echo "Error: Dockerfile not found: $dockerfile"
        exit 1
    fi
    
    # Check if the image already exists
    if [ "$force" != "true" ] && docker image inspect "kasm-$image_name:latest" &> /dev/null; then
        echo "Image kasm-$image_name:latest already exists. Use --force to rebuild."
        return
    fi
    
    # Build the image
    echo "Building from $dockerfile..."
    docker build -t "kasm-$image_name:latest" -f "$dockerfile" .
    
    # Save the image
    echo "Saving image to $OUTPUT_DIR/kasm-$image_name.tar..."
    docker save "kasm-$image_name:latest" > "$OUTPUT_DIR/kasm-$image_name.tar"
    
    echo "Image built and saved successfully!"
}

# Build all available images
build_all_images() {
    local force=$1
    
    echo "Building all available images..."
    
    if [ ! -d "$DOCKERFILE_DIR" ]; then
        echo "Error: Dockerfile directory not found: $DOCKERFILE_DIR"
        exit 1
    fi
    
    for dockerfile in "$DOCKERFILE_DIR"/*.Dockerfile; do
        if [ -f "$dockerfile" ]; then
            base_name=$(basename "$dockerfile" .Dockerfile)
            build_image "$base_name" "$force"
        fi
    done
    
    echo "All images built successfully!"
}

# Register an image with Kasm
register_image() {
    local image_name=$1
    
    echo "Registering image: $image_name with Kasm server..."
    
    # Check if the image exists
    image_file="$OUTPUT_DIR/kasm-$image_name.tar"
    if [ ! -f "$image_file" ]; then
        echo "Error: Image file not found: $image_file"
        echo "You need to build the image first with --build $image_name"
        exit 1
    fi
    
    # Get image metadata from Dockerfile
    dockerfile="$DOCKERFILE_DIR/$image_name.Dockerfile"
    if [ ! -f "$dockerfile" ]; then
        echo "Error: Dockerfile not found: $dockerfile"
        exit 1
    fi
    
    # Extract metadata
    friendly_name=$(grep "# Name:" "$dockerfile" | sed 's/# Name: //')
    description=$(grep "# Description:" "$dockerfile" | sed 's/# Description: //')
    category=$(grep "# Category:" "$dockerfile" | sed 's/# Category: //')
    
    if [ -z "$friendly_name" ]; then
        friendly_name="CTI - $image_name"
    fi
    
    if [ -z "$category" ]; then
        category="Security"
    fi
    
    # Login to Kasm
    echo "Logging in to Kasm..."
    
    # This is a placeholder - in a real implementation you would use the Kasm API
    # to authenticate and register the image
    echo "Note: This is a placeholder for the actual Kasm API integration."
    echo "In a production environment, you would need to implement the API calls to:"
    echo "1. Authenticate with the Kasm server"
    echo "2. Upload the Docker image or register it from a registry"
    echo "3. Create a workspace using the API"
    
    echo ""
    echo "Image information that would be registered:"
    echo "  Name: $friendly_name"
    echo "  Description: $description"
    echo "  Category: $category"
    echo "  Image: kasm-$image_name:latest"
    
    echo ""
    echo "For manual registration:"
    echo "1. Log in to your Kasm admin panel"
    echo "2. Go to Workspaces"
    echo "3. Click 'Add Workspace'"
    echo "4. Select 'Custom (Docker Registry)'"
    echo "5. Enter the above information"
    
    # Actual implementation would call the Kasm API here
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--server)
            KASM_SERVER="$2"
            shift
            shift
            ;;
        -u|--user)
            KASM_USER="$2"
            shift
            shift
            ;;
        -p|--password)
            KASM_PASSWORD="$2"
            shift
            shift
            ;;
        -l|--list)
            list_templates
            exit 0
            ;;
        -b|--build)
            build_image "$2" "false"
            shift
            shift
            ;;
        -a|--build-all)
            build_all_images "false"
            shift
            ;;
        -r|--register)
            register_image "$2"
            shift
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $key"
            show_help
            exit 1
            ;;
    esac
done

echo "Done!"
exit 0