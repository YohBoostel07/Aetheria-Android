# Aetheria

A stylized 3D open-world action RPG for Android, built with Godot 4.4.1.

## Current version: 0.4.0 — Vale do Primeiro Santuário

The first exploration-region milestone expands the combat prototype into a recognizable fantasy location: a forest trail, a ruined sanctuary, glowing crystals, torchlight, and a group of shadow creatures guarding the approach.

## Current playable foundation

- Third-person controller and camera.
- Android touch joystick, jump and attack controls.
- Stylized 3D adventurer with sword and basic procedural animations.
- Player health HUD.
- Three shadow enemies with health, pursuit, and close-range attacks.
- Sword attacks damage enemies in front of the player.
- Player defeat and respawn loop.
- First explorable region: Vale do Primeiro Santuário.
- Procedurally arranged forest, stone trail, rock fields and ground details.
- Ancient stone shrine with a central glowing crystal and smaller crystal lights.
- Torch-lit approach to the shrine.
- Enemy placements now guard the trail and sanctuary rather than surrounding the starting point.
- GitHub Actions workflow to export an Android debug APK.

## Requirements

- Godot 4.4.1
- Android export templates for APK export

## Build

Pushes to `main` trigger the Android debug APK workflow. The APK is published as a GitHub Actions artifact.

This is an original fantasy world and IP. It takes broad inspiration from open-world adventure design without using protected characters, names, maps, music, or art.
