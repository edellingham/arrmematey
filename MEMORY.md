# Arrmematey Project Memory

## Current State (December 11, 2025)

**Task**: Integrate movie backdrops from Fanart.tv API into Arrmematey UI, implement pirate theme, and fix backdrop loading issues.

**Completed**: 
- Added arrmematey-logo.svg (300x103px, 2.9:1 ratio) to replace emoji
- Removed purple gradient background, switched to clean #f8fafc
- Implemented complete pirate theme throughout UI (removed all "butler" references)
- Added arrmematey-icon.svg as site favicon
- Integrated Fanart.tv API with user's API key (809f4d10e36810f6f0a15445d11ec78d)
- Added correct TMDB movie IDs for 41 user-requested movies
- Fixed z-index layering issues between backdrop, overlay, and content
- Added cache-busting timestamps to prevent browser caching
- Added comprehensive emoji-based console debugging

**Current Issue**: User reports no backdrop images visible despite API returning correct URLs and src being set. The `<img class="backdrop-image" id="backdropImage" src="" alt="">` remains empty in DOM.

**Next Steps**: Determine why backdrop image src attribute isn't being set despite JavaScript apparently executing correctly.

## Files & Changes

**Modified Files**:
- `/home/ed/Dev/arrmematey/ui/public/index.html` - Main UI with pirate theme conversion, backdrop loading with debug logs, CSS z-index fixes
- `/home/ed/Dev/arrmematey/ui/server.js` - Fanart.tv API integration with 41 correct TMDB movie IDs
- `/home/ed/Dev/arrmematey/.env.example` - Added Fanart.tv API key configuration

**Read Files**:
- `/home/ed/Dev/arrematey/images/arrmematey-logo.svg` - Custom logo for UI
- `/home/ed/Dev/arrmematey/ui/package.json` - Node.js dependencies (express, dockerode, dotenv, socket.io)

**Key Files Untouched**:
- Docker Compose configuration
- Shell scripts for management/setup
- CRUSH.md documentation

## Technical Context

**Architecture**: Node.js Express server serving static HTML with Socket.io for real-time Docker container updates. Frontend vanilla JavaScript handles backdrop loading via fetch API.

**Libraries/Frameworks**: Express, Dockerode, Socket.io, dotenv (server-side). No frontend framework - vanilla JS.

**Commands Working**:
- `cd /home/ed/Dev/arrmematey/ui && node server.js` - Starts UI server on port 3000
- API endpoint `http://localhost:3000/api/fanart/backdrop` returns valid backdrop URLs
- Cache-busting with `?t=timestamp` parameter added

**Commands Failed**: Initial attempts with TMDB API failed due to invalid API key, fixed by switching to Fanart.tv with user's key.

**Environment**: Node.js server running on localhost:3000, requires Docker socket (causing errors but not blocking main functionality).

## Strategy & Approach

**Chosen Approach**: 
1. API Integration - Direct Fanart.tv API calls using user's key instead of TMDB
2. Pirate Theme Conversion - Complete UI overhaul removing "butler" terminology
3. Visual Enhancement - Custom logo at proper 2.9:1 ratio, removed gradient
4. Debugging Method - Comprehensive console logging to trace JavaScript execution

**Why This Approach**: User specifically wanted Fanart.tv integration and pirate theme. Direct API calls avoid authentication complexity of TMDB while providing high-quality movie backdrops.

**Key Insights**:
- Fanart.tv returns different image types (moviethumb, moviebackground, movieposter)
- Z-index layering was blocking backdrop visibility behind white overlay
- Browser caching can prevent image updates, requiring cache-busting
- 41 specific TMDB IDs needed for user's movie list

**Gotchas Discovered**:
- Initial TMDB IDs were incorrect (random internet sources)
- CSS layering prevented backdrop visibility despite correct URLs
- Browser caching masks updates without cache-busting parameters
- Server logs show successful API calls but user sees no images

**Assumptions Made**:
- User has arrmematey-icon.svg in images directory
- Fanart.tv API key is valid and active
- Browser allows cross-origin image loading from Fanart.tv domains

**Blockers/Risks**:
- CORS issues preventing image loading from Fanart.tv
- CSS still hiding images despite z-index fixes
- JavaScript execution errors preventing src assignment
- Network blocking of Fanart.tv image domains

## Exact Next Steps

1. **Verify Console Logs**: Check browser dev tools (F12) for emoji debugging messages to confirm JavaScript execution
2. **DOM Inspection**: Verify if `document.getElementById('backdropImage')` returns valid element
3. **Image Loading Test**: Manually test Fanart.tv URLs in browser to confirm accessibility
4. **CORS Check**: Inspect network tab for cross-origin errors when loading images
5. **CSS Audit**: Use dev tools to verify backdrop image element visibility and computed styles
6. **Manual Test**: Add temporary alert() in JavaScript to confirm function execution
7. **Fallback Strategy**: If Fanart.tv blocked, implement local fallback images

## Build/Test/Lint Commands

```bash
# Start the UI server
cd /home/ed/Dev/arrmematey/ui && node server.js

# Test API endpoint
curl http://localhost:3000/api/fanart/backdrop

# Check logs
tail -f /home/ed/Dev/arrmematey/logs/arrmematey.log
```

## Code Style Preferences

- Pirate theme terminology (no "butler" references)
- Clean light backgrounds (#f8fafc) instead of gradients
- Custom SVG logos over emoji
- Comprehensive console debugging with emoji indicators
- Cache-busting parameters for dynamic content
- Z-index layering: backdrop (-1), overlay (1), content (2)

## Important Code Locations

- `ui/server.js:125-189` - Fanart.tv API endpoint with movie list and error handling
- `ui/public/index.html:660-700` - loadBackdrop() function with comprehensive debugging
- `ui/public/index.html:42-50` - CSS z-index layering for backdrop system