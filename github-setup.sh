#!/bin/bash

# GitHub Private Repo Setup Script for Arrmematey
# This script creates a private GitHub repository and pushes Arrmematey

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI (gh) is not installed. You can install it from:"
        print_info "https://cli.github.com/manual/installation"
        echo ""
        print_info "Alternatively, you can create the repo manually at:"
        print_info "https://github.com/new"
        echo ""
        read -p "Continue with manual setup? [y/N]: " manual_setup
        if [[ "$manual_setup" =~ ^[Yy]$ ]]; then
            manual_repo_setup
            exit 0
        else
            exit 1
        fi
    fi
    
    # Check if user is authenticated with GitHub
    if ! gh auth status &> /dev/null; then
        print_error "You're not authenticated with GitHub CLI."
        print_info "Please run: gh auth login"
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Get repository information
get_repo_info() {
    print_status "Getting repository information..."
    
    # Default repository name
    REPO_NAME="arrmematey"
    
    # Get repository description
    DEFAULT_DESCRIPTION="🏴‍☠️ Arrmematey - Arr... Me Matey! Your trusty pirate crew for media treasure!"
    
    echo ""
    print_info "🏴‍☠️ Arrmematey GitHub Repository Setup"
    echo "=========================================="
    echo ""
    
    read -p "Repository name [$REPO_NAME]: " input_repo_name
    REPO_NAME=${input_repo_name:-$REPO_NAME}
    
    read -p "Repository description: " repo_description
    repo_description=${repo_description:-$DEFAULT_DESCRIPTION}
    
    # Check if repository already exists
    print_status "Checking if repository '$REPO_NAME' already exists..."
    if gh repo view "$REPO_NAME" &> /dev/null; then
        print_warning "Repository '$REPO_NAME' already exists."
        read -p "Push to existing repository? [y/N]: " use_existing
        if [[ ! "$use_existing" =~ ^[Yy]$ ]]; then
            read -p "Create with different name? [y/N]: " create_different
            if [[ "$create_different" =~ ^[Yy]$ ]]; then
                get_repo_info
                return
            else
                exit 0
            fi
        fi
        USE_EXISTING=true
    else
        USE_EXISTING=false
    fi
}

# Initialize git repository
init_git() {
    print_status "Initializing Git repository..."
    
    # Initialize git if not already initialized
    if [[ ! -d ".git" ]]; then
        git init
        print_status "Git repository initialized"
    else
        print_status "Git repository already exists"
    fi
    
    # Set remote if not exists
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin "https://github.com/$(gh api user --jq .login)/$REPO_NAME.git"
        print_status "Remote origin set"
    fi
}

# Create .gitignore if not exists
create_gitignore() {
    if [[ ! -f ".gitignore" ]]; then
        cat > .gitignore << EOF
# Environment variables
.env

# Downloaded media
Media/
Downloads/

# Configuration backups
backups/
*.backup

# Docker volumes
docker-volumes/

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Temporary files
tmp/
temp/
*.tmp

# Node modules
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/
*.egg-info/
dist/
build/

# Certificates
*.pem
*.key
*.crt
*.p12

# VPN data
*.conf
wg-quick/
EOF
        print_status "Created .gitignore file"
    else
        print_status ".gitignore already exists"
    fi
}

# Stage and commit files
stage_and_commit() {
    print_status "Staging files for commit..."
    
    # Add all files
    git add .
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        print_status "No changes to commit"
    else
        print_status "Committing files..."
        
        # Create initial commit
        git commit -m "🏴‍☠️ Initial commit: Arrmematey - Arr... Me Matey!

🎯 Features:
- 🏴‍☠️ Pirate-themed media management stack
- 🔐 VPN protection with kill switch
- 🔍 Prowlarr indexer integration
- 🎬 Sonarr TV series management
- 🎥 Radarr movie management
- 🎵 Lidarr music management
- 📥 SABnzbd usenet downloader
- ⬇️ qBittorrent torrent client
- 🍿 Jellyseerr request system
- 🎛️ Beautiful pirate-themed management UI
- 📊 Health monitoring and security checks
- 🏴‍☠️ Pirate captain script with sea shanties

🚀 Quick Start:
./quick-install.sh  # One-command pirate setup
./pirate.sh daily  # Captain's daily routine

🏴‍☠️ Arr... Me Matey! Your trusty pirate crew for media treasure!"
        
        print_status "Files committed successfully"
    fi
}

# Create GitHub repository
create_github_repo() {
    if [[ "$USE_EXISTING" == "true" ]]; then
        print_status "Using existing repository '$REPO_NAME'"
        return
    fi
    
    print_status "Creating private GitHub repository '$REPO_NAME'..."
    
    # Create private repository
    gh repo create "$REPO_NAME" \
        --description "$repo_description" \
        --private \
        --clone=false \
        --confirm
    
    print_status "Repository created successfully!"
}

# Push to GitHub
push_to_github() {
    print_status "Pushing to GitHub..."
    
    # Set up tracking if not exists
    if ! git rev-parse --verify "origin/main" &> /dev/null; then
        if git rev-parse --verify "origin/master" &> /dev/null; then
            BRANCH="master"
        else
            BRANCH="main"
        fi
        git push -u origin "$BRANCH"
    else
        git push
    fi
    
    print_status "Pushed to GitHub successfully!"
}

# Manual repository setup instructions
manual_repo_setup() {
    print_info "Manual GitHub Repository Setup"
    echo "================================="
    echo ""
    print_info "1. Go to https://github.com/new"
    print_info "2. Create a new private repository named '$REPO_NAME'"
    print_info "3. Don't initialize with README (we already have files)"
    print_info "4. After creation, run these commands:"
    echo ""
    echo "git init"
    echo "git add ."
    echo 'git commit -m "🏴‍☠️ Initial commit: Arrmematey - Arr... Me Matey!"'
    echo "git remote add origin https://github.com/YOUR_USERNAME/$REPO_NAME.git"
    echo "git push -u origin main"
    echo ""
    print_info "Replace YOUR_USERNAME with your GitHub username."
}

# Show repository information
show_repo_info() {
    echo ""
    print_status "🏴‍☠️ Repository Information"
    echo "============================="
    echo ""
    print_info "Repository URL: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
    print_info "Private: Yes"
    print_info "Description: $repo_description"
    echo ""
    print_info "Next steps:"
    print_info "1. Visit the repository URL above"
    print_info "2. Review the pushed files"
    print_info "3. Set up branch protection if desired"
    print_info "4. Add collaborators if needed"
    echo ""
    print_info "🏴‍☠️ Arrmematey is now safely stored in your private GitHub repository!"
}

# Main function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🏴‍☠️ Arrmematey GitHub Setup                ║"
    echo "║                                                              ║"
    echo "║      Setup your private GitHub repository for Arrmematey      ║"
    echo "║           Your pirate crew's treasure map!              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    check_prerequisites
    get_repo_info
    init_git
    create_gitignore
    stage_and_commit
    create_github_repo
    push_to_github
    show_repo_info
}

# Run the setup
main "$@"