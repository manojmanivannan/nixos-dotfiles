# Provides the `py-file-opener` CLI used by the `fo()` function in
# config/.config/zsh/zshrc.d/10-functions.zsh. Two provisioning strategies
# are supported; only ONE should
# be active at a time.
#
#   Option A (active)   — build py-file-opener as a pure Nix derivation and
#                         put the binary on PATH. No venv, no `uv`, fully
#                         reproducible. This is the idiomatic Nix approach.
#
#   Option B (disabled) — create a mutable ~/.scripts/.venv via a Home Manager
#                         activation script that runs `uv` (mirrors the old
#                         Arch install-apps/setup-venv-for-scripts.sh). The
#                         venv is NOT tracked by Nix and can drift, but it can
#                         be extended with arbitrary extra pip packages at any
#                         time. See the commented block below to switch.
{ pkgs, lib, config, ... }:

let
  # ── Option A (active) ─────────────────────────────────────────────────────
  # Build py-file-opener straight from its GitHub source. The console script
  # `py-file-opener` (defined in pyproject.toml [project.scripts]) is wrapped
  # onto PATH, so zshrc_addon.zsh calls it directly instead of
  # ~/.scripts/.venv/bin/py-file-opener.
  py-file-opener = pkgs.python3.pkgs.buildPythonApplication {
    pname = "py-file-opener";
    version = "0.2.0";
    format = "pyproject"; # pyproject.toml + setuptools build backend

    src = pkgs.fetchFromGitHub {
      owner = "manojmanivannan";
      repo = "py-file-opener";
      rev = "61fe8ccb4f331858e658ab6ef535e6c1ff2d2c35";
      hash = "sha256-E0BVSyTOX7VkVcgnUqaqECOwK5aVS/o41Fs0sV272A4=";
    };

    nativeBuildInputs = with pkgs.python3.pkgs; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with pkgs.python3.pkgs; [
      inquirer # only runtime dep per pyproject.toml
    ];

    pythonImportsCheck = [ "py_file_opener" ];
  };
in
{
  home.packages = [ py-file-opener ];

  # ── Option B (disabled) — mutable ~/.scripts/.venv via activation script ──
  # Reproduces the old Arch setup-venv-for-scripts.sh: a real on-disk venv at
  # ~/.scripts/.venv holding py-file-opener (plus pip/setuptools), which you
  # can later extend with `uv pip install` for any extra packages.
  #
  # To switch from Option A to Option B:
  #   1. Comment out the `let py-file-opener = ...` binding above and the
  #      `home.packages = [ py-file-opener ];` line.
  #   2. Uncomment the activationScripts block below.
  #   3. Add `uv` to home.packages in home-packages.nix.
  #   4. In config/.config/zsh/zshrc.d/10-functions.zsh, revert the `fo()` call
  #      back to `~/.scripts/.venv/bin/py-file-opener`.
  #
  # home.activationScripts.setupScriptsVenv =
  #   lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #     SCRIPT_DIR="${config.home.homeDirectory}/.scripts"
  #     mkdir -p "$SCRIPT_DIR"
  #     # Create the venv only if it doesn't already exist (matches old script).
  #     if [ ! -d "$SCRIPT_DIR/.venv" ]; then
  #       ${pkgs.uv}/bin/uv venv --python=3.11 "$SCRIPT_DIR/.venv"
  #       ${pkgs.uv}/bin/uv pip install \
  #         --python "$SCRIPT_DIR/.venv/bin/python" \
  #         pip setuptools \
  #         git+https://github.com/manojmanivannan/py-file-opener.git
  #     fi
  #   '';
}