PLEASE DELETE ANY NON-RELEVANT SECTIONS (self-checklist) (including this line!)

### Roblox place
(link to roblox place for this feature, if appropriate)

### Description
(what does this pr introduce? anything to note to the reviewer/team?)

### Studio changes
(does this pr rely on new instances? has this been moved into the dev place? any notes?)

### Merge Checklist
(are there missing assets? will there be some last minute commits? anything the team will need to do?)

# Self-Checklist
### Here are some reminders of what _may_ be appropriate to check before you PR
 - My PR branch has had `main` merged into it
 - I have tested my changes on Roblox Studio
 - I have added comments where behaviour/purpose is not immediately obvious to the reader
 - I have removed dead code and unused dependencies from modified scripts
 - I took the precautions not to freeze client-side threads while calling server-side functions (e.g., use an `Assume`)
 - I have added unit tests where approproiate (object serialization, verifying instance structures, give nice error messages for a difficult-to-find bug)
 - Unit tests all pass when my code is synced onto the dev place
 - UI has been tested on different resolutions
 - I have tested my feature with a high ping in Studio `(File -> Studio Settings -> "lag")`
