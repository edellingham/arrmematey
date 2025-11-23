#!/bin/bash
cd /home/ed/Dev/arrmematey

# Stage the updated file
git add install-arrmematey.sh

# Commit with descriptive message
git commit -m "Update Wireguard setup to use individual questions instead of paste

- Replace complex multi-line paste approach with step-by-step questions
- Ask for PrivateKey and Address separately from user  
- Add proper validation and error handling
- Improve user experience with clearer instructions
- Maintain compatibility with existing docker-compose.yml update logic

This makes Wireguard credential collection much more user-friendly
and reduces chance of copy-paste formatting errors."

# Push to main branch
git push origin main

echo "✅ Changes pushed successfully!"
echo ""
echo "Updated installer is now live with individual Wireguard questions."