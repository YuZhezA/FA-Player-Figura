# Project status

Last updated: 2026-10-03

## Repository

- GitHub: <https://github.com/YuZhezA/FA-Player-Figura>
- Visibility: public
- Default branch: `main`
- Initial public commit: `1d5e01af46ca1cc74362ed748e7f7bed1a76a92e`
- Commit identity uses a GitHub `users.noreply.github.com` privacy address.

## Current release baseline

- Figura avatar revision: `FA-Player-Figura-v1.1-fix17`
- Target environment: Minecraft 1.21.1 / NeoForge / Figura
- `fix17` restores the forward arm tilt while actively blocking with a shield.
- Attack and interaction swings use `getSwingArm()`.
- Continuous item-use poses use `getActiveHand()`.

## Repository contents

The repository intentionally contains only the installable Figura avatar and its documentation:

- `script.lua`
- `avatar.json`
- `avatar.png`
- `accessories.bbmodel`
- project documentation and Git configuration files

The following development/reference material must not be uploaded:

- Original Fresh Animations or FA+Player resource packs
- Original `.jem` / `.jpm` files
- Entity Model Features, Entity Texture Features, or Figura source trees
- Reference screenshots
- Local test tools and compiled test classes
- Previous fix directories or release ZIP files

## Release versioning rule

- Never overwrite an existing FA Player Figura release directory or ZIP.
- Every revision must use the next available suffix, such as `-fix18`, `-fix19`, and so on.
- Verify the preceding release remains byte-for-byte unchanged before handing off a new package.
