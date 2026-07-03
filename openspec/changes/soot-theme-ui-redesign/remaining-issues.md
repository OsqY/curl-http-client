Bugs and features to implement for the Soot UI:

1. **Response body white background**: HighlightView from flutter_highlight doesn't set a background, defaults to white. Fix: Wrap in Container with bg color, or set HighlightView backgroundColor.
2. **ClickCursor missing** on several interactive elements: DropdownButtonFormField, DropdownMenu, PopupMenuButton trigger areas, some IconButtons.
3. **Context menu positioning**: showMenu uses `RelativeRect.fill` which centers the menu. Fix: capture tap position and use a proper `RelativeRect` from the tap details.
4. **Dropdown centering**: DropdownButtonFormField opens centered over the field. Fix: wrap in a custom overlay or use offset/alignment.
5. **Body/Auth editors cramped**: Add proper vertical spacing between sections.
6. **Subfolder save**: HttpRequest model needs `folderId` field; sidebar folder context menu needs "New Request" to save to that folder; main_screen _saveRequest needs to handle folderId.
7. **Theme system**: Add `sootLightTheme`, `sootOrangeDarkTheme` and a way to switch between them.
