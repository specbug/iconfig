# Terminal Wizard UI Design

## Design Principles
- **User-Friendly**: Clear instructions and visual cues
- **Resilient**: Graceful error handling and recovery
- **Informative**: Provide context and progress feedback
- **Efficient**: Minimize user input requirements
- **Attractive**: Use colors and formatting for better readability

## UI Components

### 1. Header Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  🔄 Mac Sync Wizard v1.0                                                 ┃
┃  Easily sync and setup your Mac utilities across multiple machines       ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 2. Menu Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  Please select an option:                                                ┃
┃                                                                          ┃
┃  [1] Setup new repository                                                ┃
┃  [2] Backup current settings                                             ┃
┃  [3] Restore settings from repository                                    ┃
┃  [4] Configure sync settings                                             ┃
┃  [5] View sync status                                                    ┃
┃  [q] Quit                                                                ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 3. Progress Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  Progress: Backing up Cursor settings                                    ┃
┃                                                                          ┃
┃  [████████████████████████████████████████░░░░░░░░░░░░░░░░] 70%         ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 4. Selection Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  Select utilities to sync:                                               ┃
┃                                                                          ┃
┃  [✓] Cursor                   [✓] Warp Terminal                         ┃
┃  [✓] PyCharm                  [✓] System Fonts                          ┃
┃  [✓] Sublime Text             [✓] Anki                                  ┃
┃  [✓] Trackpad Settings        [✓] Logi Options+                         ┃
┃  [✓] Git Settings             [✓] 1Password                             ┃
┃  [✓] Arc Browser              [✓] Stretchly                             ┃
┃  [ ] Dev Tools (setup only)   [✓] Maccy                                 ┃
┃                                                                          ┃
┃  Use arrow keys to navigate, space to toggle, enter to confirm           ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 5. Configuration Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  Sync Configuration:                                                     ┃
┃                                                                          ┃
┃  Repository URL: [https://github.com/username/mac-sync.git            ] ┃
┃  Sync Frequency: [Every 6 hours                                        ] ┃
┃  Auto Commit:    [✓] Enabled                                            ┃
┃  Notifications:  [✓] Errors only                                        ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 6. Status Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  Status: ✅ All systems operational                                      ┃
┃                                                                          ┃
┃  Last sync: 2025-05-27 07:15:22                                         ┃
┃  Next scheduled sync: 2025-05-27 13:15:22                               ┃
┃                                                                          ┃
┃  Synced utilities: 14/15                                                 ┃
┃  Repository: https://github.com/username/mac-sync.git                   ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 7. Error Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  ⚠️  Warning: Could not access PyCharm settings                          ┃
┃                                                                          ┃
┃  Reason: Application not installed or path not found                     ┃
┃  Action: Skipping this utility. You can retry later from the main menu.  ┃
┃                                                                          ┃
┃  [c] Continue with other utilities   [r] Retry   [h] Help               ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 8. Success Component
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                          ┃
┃  ✅ Success! All selected utilities have been synced                     ┃
┃                                                                          ┃
┃  Repository: https://github.com/username/mac-sync.git                   ┃
┃  Commit ID: a1b2c3d4e5f6g7h8i9j0                                        ┃
┃                                                                          ┃
┃  Background sync service is now running.                                 ┃
┃  Press any key to return to main menu...                                 ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Wizard Flow

### Initial Setup Flow
1. Display welcome screen with project description
2. Check for Git installation and configure if needed
3. Prompt for Git repository URL (new or existing)
4. Detect installed utilities
5. Allow selection of utilities to sync
6. Configure sync settings (frequency, notifications)
7. Perform initial backup
8. Setup background sync service
9. Show success screen with next steps

### Backup Flow
1. Display backup options screen
2. Select utilities to backup
3. Show progress during backup
4. Commit and push changes to repository
5. Show success screen with summary

### Restore Flow
1. Display restore options screen
2. Pull latest changes from repository
3. Select utilities to restore
4. Show progress during restore
5. Handle conflicts if they arise
6. Show success screen with summary

### Configuration Flow
1. Display current configuration
2. Allow editing of repository URL
3. Configure sync frequency
4. Configure notification preferences
5. Configure commit message template
6. Save configuration

## Error Handling Strategy

### Graceful Degradation
- If a utility fails to sync, continue with others
- Provide clear error messages with suggested actions
- Allow retry options for failed operations

### Recovery Mechanisms
- Save state between operations to allow resuming
- Implement rollback for failed operations
- Provide manual override options

### User Feedback
- Clear indication of what went wrong
- Suggestions for how to fix issues
- Links to documentation for complex problems

## Color Scheme
- Headers: Blue
- Success messages: Green
- Warnings: Yellow
- Errors: Red
- Progress bars: Cyan
- Normal text: White
- Background: Terminal default

## Implementation Notes
- Use Python's `rich` library for terminal UI components
- Implement a state machine for wizard flow
- Store wizard state in a temporary file to allow resuming
- Use ANSI escape codes for colors and formatting
- Ensure compatibility with common terminal emulators
