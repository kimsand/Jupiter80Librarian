# Jupiter-80 Librarian
The Roland Jupiter-80 is a powerful synth. With great power comes great... complexity. Sounds can have up to 4 levels (Registrations, Live Sets, Tones and Partials) but these dependencies must be manually organized with little help from the built-in system. This makes it difficult to know if a dependency will break when deleting a sound, or if a sound already exists on an import. Also, it is easy to forget which sounds are stored in which backup / export files.

This tool is an attempt to make it easier to get an overview of sounds and their dependencies. The tool can open SVD files from the Jupiter-80 and the Jupiter-50.

![Screenshot](https://raw.githubusercontent.com/kimsand/Jupiter80Librarian/master/images/JP80.png)

Features:
* List all Registrations, Live Sets and Tones inside the file.
* List the order, name and parts of each Registration.
* List the order, name and layers of each Live Set.
* List the order, name and partials of each Tone.
* Show the names of the built-in acoustic tones and PCMs used by sounds.
* List only Live Sets that are in use by any Registration.
* List only Live Sets that are NOT used by any Registration.
* List only Tones that are in use by any Live Set.
* List only Tones that are NOT used by any Live Set.
* List all Registrations that use the selected Live Set(s).
* List all Live Sets (and optionally Registrations) that use the selected Tone(s).
* Filter on any column (e.g. name, part, layer, partial) to quickly find sounds.
* Sort on any column (e.g. name, part, layer, partial) to browse alphabetically.

Wish list:
* Export dependency data to CSV files (import into any spreadsheet app).
* Rename Registrations, Live Sets and Tones.
* Delete Registrations.
* Safely delete Live Sets and Tones, warning about dependencies.
* Optionally delete dependencies when deleting Registrations, Live Sets and Tones.
* Move Registrations and banks of Registrations.
* Safely move Live Sets without breaking Registrations (update dependencies).
* Safely move Tones without breaking Live Sets and Registrations (update dependencies).