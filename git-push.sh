#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Pushing updated install-arrmematey.sh (v2.20.0) ==="

# Stage changes
echo "Staging changes..."
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Update Wireguard setup to use individual questions (v2.20.0)

- Replace complex multi-line paste approach with step-by-step questions
- Ask for PrivateKey and Address separately from user
- Add proper validation and error handling  
- Improve user experience with clearer instructions
- Maintain compatibility with existing docker-compose.yml update logic
- Fix version inconsistency (now both show 2.20.0)

This makes Wireguard credential collection much more user-friendly
and reduces chance of copy-paste formatting errors."

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Changes pushed to GitHub!"
echo "🏴‍☠️  Updated installer is now live with:"
echo "   • Version 2.20.0"  
echo "   • Individual Wireguard questions (PrivateKey + Address)"
echo "   • Better UX and validation"
echo ""
echo "Users can now run:"
echo "bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh)"