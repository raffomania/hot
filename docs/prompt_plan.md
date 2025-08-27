# Prompt Plan: Enhanced Archive Feature with Finished/Cancelled Status

This document contains the prompt plan for enhancing the existing archive functionality with split status handling and dual dropzones.

## Technical Considerations

- Maintain existing Ash Framework architecture and patterns
- Preserve Phoenix LiveView real-time functionality
- Keep comprehensive test coverage
- Follow the project's existing code conventions
- Ensure all changes integrate with the current authentication system
- Maintain the vendored SortableJS drag-and-drop implementation

## 5. Split Archive Status into Finished and Cancelled

**Status:** 📋 **PLANNED**

**Implementation Plan:**
- Modify Card resource to replace `archived` boolean with new hardcoded lists in board_lists.ex (names: "finished", "cancelled")  
- Update archive/unarchive actions to handle the new lists
- Migrate existing archived cards to use the new status system
- Update queries to handle the new status field instead of archived boolean
- Update seed data
- Update archive page to separate finished and cancelled cards
- Update tests to cover the new status-based system

**Prompt:**
```
Change the archiving data model to split archived status into two distinct statuses: finished and cancelled. The changes needed are:

1. Modify Card resource to replace `archived` boolean with new hardcoded lists in board_lists.ex (names: "finished", "cancelled")  
2. Update the existing `:archive` action to accept a status parameter and move to the appropriate list
3. Create separate actions `:mark_finished` and `:mark_cancelled` for clarity
4. Update the `:unarchive` action to set status back to "active"
5. Update all queries to use the new lists instead of the archived boolean
6. Generate and run a database migration to convert existing archived=true cards to finished status
7. Update Card resource tests to cover the new list-based functionality
8. Ensure backward compatibility during the migration process

The new status field should provide clearer semantics about why a card was removed from the active board.
Ignore any breakage on the archive page for now.
```

## 6. Split Archive Dropzone into Finished and Cancelled Zones

**Status:** 📋 **PLANNED**

**Implementation Plan:**
- Replace single archive dropzone with two separate dropzones
- Position finished dropzone (green) at bottom right of screen
- Position cancelled dropzone (red) at bottom left of screen
- Update JavaScript hooks to handle both dropzones
- Add appropriate visual styling and feedback for each zone

**Prompt:**
```
Replace the single archive dropzone with two separate dropzones for finished and cancelled statuses. The implementation should include:

1. Remove the existing single archive dropzone
2. Create a "Finished" dropzone positioned at the bottom right of the screen with green styling
3. Create a "Cancelled" dropzone positioned at the bottom left of the screen with red styling
4. Update JavaScript hooks to handle both dropzones independently:
   - Show both dropzones when dragging starts
   - Provide distinct visual feedback for each zone
   - Send different LiveView events for finished vs cancelled drops
5. Ensure both dropzones are responsive and scale properly for mobile screens
6. Use appropriate icons and text labels for each dropzone
7. Update the LiveView event handlers to process finished and cancelled actions separately
8. Maintain accessibility features for both dropzones
9. Update tests to cover both dropzone interactions

The dropzones should provide clear visual distinction between finishing and cancelling shows.
```

## 7. Update Archive Page with Finished and Cancelled Sections

**Status:** 📋 **PLANNED**

**Implementation Plan:**
- Modify archive page to show finished shows at the top in a dedicated section
- Add a separate section below for cancelled shows
- Update styling to visually distinguish between the two sections
- Maintain responsive design for mobile viewing
- Update unarchive functionality to work with the new status system

**Prompt:**
```
Update the Archive page to separate finished and cancelled shows into distinct sections. The changes needed are:

1. Modify the archive LiveView to query and display finished shows in a top section
2. Add a separate section below for cancelled shows
3. Add clear section headers and visual styling to distinguish between finished and cancelled
4. Use appropriate colors/styling: green accents for finished section, red accents for cancelled section
5. Update the unarchive functionality to work with the new status-based system
6. Maintain the existing grid layout within each section
7. Ensure responsive design works well on mobile devices
8. Update real-time PubSub handling for the new status-based events
9. Add empty state messages for each section when no cards are present
10. Update archive page tests to cover the new sectioned layout
11. Ensure proper navigation and accessibility between sections

The archive page should clearly separate and organize shows by their completion status.
```

## 8. Ensure Mobile Responsiveness for Dropzones

**Status:** 📋 **PLANNED**

**Implementation Plan:**
- Test dropzones on various mobile screen sizes
- Adjust positioning and sizing for small screens
- Ensure touch interactions work properly
- Optimize dropzone visibility without blocking content
- Test with different mobile orientations

**Prompt:**
```
Optimize the finished and cancelled dropzones for mobile screens and touch interactions. The implementation should include:

1. Test and adjust dropzone positioning for mobile screen sizes (320px and up)
2. Ensure dropzones are appropriately sized for touch interactions (minimum 44px touch targets)
3. Optimize dropzone spacing to prevent accidental drops on small screens
4. Adjust dropzone visibility and opacity to work well on mobile without blocking critical content
5. Test touch drag and drop interactions on mobile devices
6. Ensure dropzones work in both portrait and landscape orientations
7. Add CSS media queries for different mobile breakpoints
8. Test with various mobile browsers and devices
9. Ensure accessibility features work well with mobile screen readers
10. Update responsive design tests to cover mobile dropzone scenarios

The dropzones should provide an excellent user experience on mobile devices while maintaining functionality.
```