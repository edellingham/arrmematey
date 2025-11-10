# GitHub Repository Setup for Arrmematey 🏴‍☠️

This directory contains all the files needed to set up a private GitHub repository for your Arrmematey media stack.

## 🚀 Quick GitHub Setup

### Prerequisites
1. **Git** - Install from [git-scm.com](https://git-scm.com)
2. **GitHub CLI** - Install from [cli.github.com](https://cli.github.com/manual/installation)
3. **GitHub Authentication** - Run `gh auth login` to authenticate

### Automated Setup

```bash
# Run the automated GitHub setup script
./github-setup.sh
```

This script will:
- ✅ Check prerequisites (git, gh CLI, authentication)
- ✅ Create a private GitHub repository named `arrmematey`
- ✅ Initialize git repository in current directory
- ✅ Create appropriate `.gitignore` file
- ✅ Commit all files with pirate-themed commit message
- ✅ Push to your private GitHub repository

### Manual Setup

If you prefer manual setup:

1. **Create Private Repository**
   - Go to [https://github.com/new](https://github.com/new)
   - Repository name: `arrmematey`
   - Set to Private
   - Don't initialize with README
   - Click "Create repository"

2. **Initialize Local Git**
   ```bash
   git init
   git add .
   git commit -m "🏴‍☠️ Initial commit: Arrmematey - Arr... Me Matey!"
   ```

3. **Connect to Remote**
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/arrmematey.git
   git push -u origin main
   ```

## 📁 Repository Contents

Your private GitHub repository will contain:

### 🏴‍☠️ Core Scripts
- `quick-install.sh` - Captain's express setup
- `setup.sh` - Captain's detailed setup
- `configure.sh` - Crew service configuration
- `manage.sh` - Crew management
- `health.sh` - Ship's health monitoring
- `profiles.sh` - Crew profile management
- `pirate.sh` - Captain's personal assistance script

### 🔒 Security Scripts
- `vpn-security.sh` - Ship's security and leak testing
- `kill-switch-test.sh` - Ship's emergency kill switch testing
- `github-setup.sh` - GitHub repository setup script

### 📚 Configuration Files
- `docker-compose.yml` - Pirate fleet configuration
- `.env.example` - Environment template
- `Dockerfile.ui` - Management UI container

### 🏴‍☠️ User Interface
- `ui/` - Captain's command bridge
  - `server.js` - Node.js server
  - `package.json` - Dependencies
  - `public/` - Web interface
  - `Dockerfile` - UI container build

### 📚 Documentation
- `README.md` - Complete pirate documentation
- `LICENSE` - Software license
- `.gitignore` - Files to exclude from version control

## 🔐 Security Considerations

### Private Repository
- ✅ **Private by default** - Only you can see the repository
- ✅ **No credentials** - `.env` file excluded via `.gitignore`
- ✅ **Safe configuration** - Passwords and API keys never committed
- ✅ **Version control** - Track configuration changes safely

### Sensitive Files Excluded
The `.gitignore` excludes:
- `.env` - Environment variables and credentials
- `Media/` - Your media library
- `Downloads/` - Download staging area
- `backups/` - Configuration backups
- `*.pem`, `*.key` - SSL certificates
- `docker-volumes/` - Docker volume data

## 🔄 Repository Usage

### Clone Repository (New System)
```bash
git clone https://github.com/YOUR_USERNAME/arrmematey.git
cd arrmematey
cp .env.example .env
./quick-install.sh
```

### Pull Updates
```bash
git pull origin main
```

### Push Configuration Changes
```bash
git add .
git commit -m "🏴‍☠️ Updated configuration"
git push origin main
```

## 🌟 GitHub Features Available

### Issues and Projects
- Track feature requests and bugs
- Create project boards for improvements
- Use pirate-themed labels and milestones

### Actions and Workflows
- Set up automated testing
- Deploy with GitHub Actions
- Security scanning with CodeQL

### Branch Protection
- Require reviews for changes
- Enforce status checks
- Protect main/master branch

### Collaborators
- Add family members or friends
- Granular permission management
- Team-based access control

## 🏴‍☠️ Repository Structure

```
arrmematey/
├── 🏴‍☠️ Core Scripts/
│   ├── quick-install.sh        # Captain's express setup
│   ├── setup.sh               # Captain's detailed setup
│   ├── configure.sh           # Crew service configuration
│   ├── manage.sh              # Crew management
│   ├── health.sh              # Ship's health monitoring
│   ├── profiles.sh            # Crew profile management
│   ├── pirate.sh              # Captain's personal assistance
│   └── github-setup.sh       # GitHub repository setup
├── 🔒 Security Scripts/
│   ├── vpn-security.sh        # Ship's security testing
│   └── kill-switch-test.sh   # Emergency kill switch test
├── 📚 Configuration/
│   ├── docker-compose.yml     # Pirate fleet config
│   ├── .env.example          # Environment template
│   └── Dockerfile.ui         # Management UI container
├── 🏴‍☠️ User Interface/
│   ├── ui/
│   │   ├── server.js         # Node.js server
│   │   ├── package.json      # Dependencies
│   │   ├── Dockerfile        # UI container
│   │   └── public/
│   │       ├── index.html    # Pirate-themed UI
│   │       └── style.css    # UI styling
└── 📚 Documentation/
    ├── README.md              # Complete documentation
    ├── LICENSE                # Software license
    └── .gitignore           # Excluded files
```

## 🎯 Next Steps After Setup

1. **Review Repository** - Check all files are properly committed
2. **Set Up Branch Protection** - Protect your main branch
3. **Add Collaborators** - Share access if needed
4. **Configure Actions** - Set up automation if desired
5. **Create Issues Template** - Standardize bug reports and feature requests

## 🏴‍☠️ Pirate GitHub Tips

### Pirate-Themed Commits
- Use pirate emojis: 🏴‍☠️, 🎵, ⚓, 🍿
- Pirate-themed commit messages
- Sea shanty themed pull requests

### Repository Description
```
🏴‍☠️ Arrmematey - Arr... Me Matey! Your trusty pirate crew for media treasure! 🍿
```

### Topics
Add these topics to help others find your repo:
- `docker`, `media-server`, `automation`, `vpn`, `security`, `pirate-theme`

---

**🏴‍☠️ Arrmematey - Arr... Me Matey! Your media treasure is safely stored!**