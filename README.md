# Aetheria

A stylized 3D fantasy action RPG for Android, built with Godot 4.4.1.

## Current version: 0.6.0 — Inventário e Progressão

This milestone introduces the first playable character progression loop. Completing the shrine quest grants 100 EXP; reaching the threshold raises the hero to level 2 and improves maximum health, sword damage, and defense. Further levels require progressively more experience.

Exploration now includes collectible medicinal herbs, blue crystals, ancient ore, and the Guardian Amulet. Pickups float and glow in the world, are collected by approaching them, and appear in the inventory panel. The Guardian Amulet is automatically equipped when collected and increases defense.

## Current playable foundation

- Third-person controller and camera.
- Android touch joystick, jump and attack controls.
- Stylized 3D adventurer with sword and basic procedural animations.
- Dynamic health HUD that reflects maximum health upgrades.
- Three shadow enemies with health, pursuit, and close-range attacks.
- Sword attacks damage enemies in front of the player.
- Player defeat and respawn loop.
- First explorable region: Vale do Primeiro Santuário.
- Procedurally arranged forest, stone trail, rock fields and ground details.
- Improved procedural trees with branches and layered leaves.
- Ancient stone shrine with a central glowing crystal and smaller crystal lights.
- Torch-lit approach to the shrine.
- Quest: defeat three Sombrio, then reach the central crystal.
- Quest progress HUD and +100 EXP completion reward.
- Character levels, EXP progression, and level-up stat increases.
- Character attributes: maximum health, attack, and defense.
- Collectible items: Erva medicinal, Cristal azul, and Minério antigo.
- Guardian Amulet equipment that increases defense.
- Inventory and character status HUD.
- Android debug APK exported through GitHub Actions.

## Requirements

- Godot 4.4.1
- Android export templates for APK export

## Build

Pushes to the default branch trigger the Android debug APK workflow. The APK is published as a GitHub Actions artifact.

This is an original fantasy world and IP. It takes broad inspiration from open-world adventure design without using protected characters, names, maps, music, or art.


Visual overhaul branch: Android build validation is enabled for this branch.
