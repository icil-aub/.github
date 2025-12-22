# Widget Download/Update Script

This repo includes a single PowerShell script that downloads or updates the widget repositories you have access to.

## Where to store it
Place `download-or-update-widgets.ps1` in the widgets root folder (the same folder that contains your widget folders, such as `Slider` and `advancedButton`). Example:
- `C:\Users\Maurice\Documents\EB_1.19\client\your-extensions\widgets\download-or-update-widgets.ps1`

Keeping it in the widgets root lets the script default to that folder when cloning/updating.

## How to run
From the widgets root:
```powershell
.\download-or-update-widgets.ps1
```
Optional argument:
- `-BaseDir C:\path\to\widgets` to choose a different destination.

## Expected output
During the run you will see lines like:
- `Cloning <url> -> <path>` for new widgets.
- `Updating <path>` for existing widgets.

At the end, the script prints:
- A list of downloaded widgets.
- A list of updated widgets.

It finishes with a summary line and waits for `Press Enter to close`, so the terminal stays open.

If you do not have access to a repository, the script logs a warning and continues with the next one.
