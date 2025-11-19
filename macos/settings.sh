#!/usr/bin/env bash
# ==============================================================================
# macOS System Configuration Script
# ==============================================================================
# Automates macOS system preferences for a consistent development environment
#
# Usage: ./macos/settings.sh
#
# IMPORTANT: Review settings before running!
# Some settings require a logout/restart to take effect.
# Refer to the comments in the script for details.
# Also, check out https://macos-defaults.com/ for more options.
# ==============================================================================

set -e  # Exit on error

echo "Configuring macOS system settings..."
echo "Some changes require logout/restart to take effect"
echo

# Close System Preferences to prevent conflicts
osascript -e 'tell application "System Preferences" to quit'

# ==============================================================================
# General System Settings
# ==============================================================================

echo "General System..."

# Disable startup sound
# sudo nvram SystemAudioVolume=" "

# Show battery percentage in menu bar
# defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Enable full keyboard access for all controls (Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# ==============================================================================
# Dock Settings
# ==============================================================================

echo "Dock..."

# Set Dock position to left side of the screen
defaults write com.apple.dock orientation left

# Set Dock icon size (default is 64)
defaults write com.apple.dock tilesize -int 45

# Enable Dock autohide
defaults write com.apple.dock autohide -bool false

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# Top right → Desktop
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0

# Bottom right → Mission Control
defaults write com.apple.dock wvous-br-corner -int 0
defaults write com.apple.dock wvous-br-modifier -int 0

# ==============================================================================
# Finder Settings
# ==============================================================================

echo "Finder..."

# Allow quitting Finder via ⌘ + Q
# defaults write com.apple.finder QuitMenuItem -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
# defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use list view in all Finder windows by default
# Four-letter codes for the view modes: `icnv`, `clmv`, `glyv`, `Nlsv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show the ~/Library folder
# chflags nohidden ~/Library

# Show the /Volumes folder
# sudo chflags nohidden /Volumes

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# ==============================================================================
# Menu Bar
# ==============================================================================

echo "Menu Bar..."

# Adjust menu bar icon spacing (useful for notch workaround)
defaults write -globalDomain NSStatusItemSelectionPadding -int 6
defaults write -globalDomain NSStatusItemSpacing -int 10

# ==============================================================================
# Trackpad & Mouse
# ==============================================================================

echo "Trackpad & Mouse..."

# Enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: enable three finger drag
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false

# Increase mouse tracking speed
# defaults write NSGlobalDomain com.apple.mouse.scaling -float 1

# ==============================================================================
# Screenshots
# ==============================================================================

echo "Screenshots..."

# Save screenshots to ~/Screenshots folder
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# ==============================================================================
# Safari
# ==============================================================================

# Note: Safari preferences are sandboxed in modern macOS and cannot be modified via defaults
# Configure these settings manually in Safari > Settings:
#   - Privacy: Disable "Include search engine suggestions" and "Include Safari Suggestions"
#   - Advanced: Enable "Show features for web developers"
#   - Advanced: Show full website address

# echo "Safari..."
# defaults write com.apple.Safari UniversalSearchEnabled -bool false
# defaults write com.apple.Safari SuppressSearchSuggestions -bool true
# defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
# defaults write com.apple.Safari IncludeDevelopMenu -bool true
# defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
# defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# ==============================================================================
# Activity Monitor
# ==============================================================================

echo "Activity Monitor..."

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Dock icon
defaults write com.apple.ActivityMonitor IconType -int 6

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 100

# Sort Activity Monitor results by CPU usage
# defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
# defaults write com.apple.ActivityMonitor SortDirection -int 0

# ==============================================================================
# Terminal
# ==============================================================================

echo "Terminal..."

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# ==============================================================================
# Time Machine
# ==============================================================================

echo "Time Machine..."

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# ==============================================================================
# Optional: Clipboard Manager (Maccy)
# ==============================================================================

# Uncomment if you use Maccy (brew install --cask maccy)
# echo "Maccy (Clipboard Manager)..."
# defaults write org.p0deje.Maccy pasteByDefault -bool true
# defaults write org.p0deje.Maccy historySize -int 200

# ==============================================================================
# Finish
# ==============================================================================

echo
echo "macOS configuration complete!"
echo
echo "Please restart your Mac for all changes to take effect:"
echo "    - Dock settings"
echo "    - Finder settings"
echo "    - Some system preferences"
echo
echo "To restart now: sudo shutdown -r now"
echo

# Kill affected applications
for app in "Activity Monitor" \
  "Dock" \
  "Finder" \
  "Safari" \
  "SystemUIServer"; do
  killall "${app}" &> /dev/null || true
done
