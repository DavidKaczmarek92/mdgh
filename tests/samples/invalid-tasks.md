# Invalid Tasks Sample

This file contains various violations of the mdgh task convention.

## [LEVEL2] This is a level 2 heading with a tag
Expected error: Wrong heading level for task.

### This heading is missing a tag
Expected error: Missing or malformed tag in level 3 heading.

### [] This heading has an empty tag
Expected error: Empty tag.

### [INVALID!TAG] This heading has invalid characters in the tag
Expected error: Invalid characters in tag.

#### [LEVEL4] This is a level 4 heading with a tag
Expected error: Wrong heading level for task.

### [VALID] This is actually valid
But the next line is a heading that might be confused.

## [TAG] Another level 2 violation
This should also be caught.
