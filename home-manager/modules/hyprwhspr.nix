{
  lib,
  pkgs,
  ...
}:

# Per-user data the hyprwhspr systemd unit (nixos/modules/desktop/hyprwhspr.nix)
# needs but its module doesn't create, so a fresh install works without the
# upstream manual first-run (`hyprwhspr config init` + `model download`).
let
  # ggml-small.en.bin (HuggingFace ggerganov/whisper.cpp, ~466 MiB) — the small
  # English-only whisper model this install uses. Fetched into the store so the
  # model bytes are declarative; the backend only READS model files, so a
  # read-only store symlink in ~/.local/share/pywhispercpp/models/ is enough
  # (pywhispercpp_backend._model_files/_model_arg just is_file() there).
  ggmlSmallEn = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin";
    hash = "sha256-xhONbVjsyDIgl+D5h8MvG+i7ChhTKj+I9zTRu/nEHl0=";
  };
in
{
  # Seed one symlink per model on first run only (never overwrites an existing
  # file, mirroring seedRsyncPassword in dotfiles-symlinks.nix) — so switching
  # models later by hand stays possible. The backend resolves config
  # `"model"` against PYWHISPERCPP_MODELS_DIR (~/.local/share/pywhispercpp/models/,
  # XDG_DATA_HOME-aware); file name is ggml-model.bin.
  home.activation.seedHyprwhsprModel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    models_dir="$HOME/.local/share/pywhispercpp/models"
    if [ ! -e "$models_dir/ggml-small.en.bin" ]; then
      $DRY_RUN_CMD mkdir -p "$models_dir"
      $DRY_RUN_CMD ln -s "${ggmlSmallEn}" "$models_dir/ggml-small.en.bin"
    fi
  '';
}