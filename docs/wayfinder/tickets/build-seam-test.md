---
id: WF-9
title: Build-seam baseline test
label: wayfinder:build
status: closed
assignee:
blocked-by: []
triage: ready-for-agent
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8, Testing
Decisions). This is the first implementation slice of the build hand-off.

## What to build

The repo's first automated test. Establish a `checks` output (or an equivalent
test derivation) that asserts the NixOS system configuration evaluates and
builds successfully from the flake — `nix build .#nixos` (equivalently
`nixos-rebuild build`) succeeds. This is the single automated seam the spec
identifies, and it is the safety net every later slice runs against: it must be
green against today's waybar stack on both `main` and `quickshell` before any
caelestia code lands, so a later slice that breaks evaluation is caught
mechanically rather than at a live session.

This slice de-risks the test infrastructure itself in isolation — no caelestia
content yet.

## Acceptance criteria

- [ ] A flake `checks` output (or test derivation) exists and runs
      `nix build .#nixos` (or `nixos-rebuild build`) to completion.
- [ ] The check passes green on the current `main` (today's waybar stack).
- [ ] The check passes green on the current `quickshell` branch.
- [ ] The check asserts only external behaviour — "the configured system
      builds" — with no assertions about Nix function internals or file layout.
- [ ] Running the check requires no manual prelude beyond a standard
      `nix flake check` / `nix build` invocation.

## Blocked by

- None — can start immediately.