#
# The media catalogue: GRAPHICAL media consumption only. A terminal-shaped tool, no matter how
# media-adjacent it looks, is nixsh's problem now.
#
# THE PLACEMENT RULE, stated as a test so the next addition is decided rather than argued: does
# the tool have a display mode at all, and is that mode its DEFAULT?
#
#   yes -> a display-substrate repo (this one, nixdesktop, or nixrecord)
#   no  -> nixsh
#
# "Can it be coaxed into a terminal" is NOT the test. mpv ships `--vo=sixel` and OBS cannot run
# headless at all; a test built on CAPABILITY rather than DEFAULT would misfile both anyway. Worked
# examples, so the rule is provable rather than merely asserted:
#
#   - cmus            no display mode at all                    -> nixsh
#   - zathura          gtk4, a GUI document viewer -- not a TUI to begin with, so there was never
#                      a nixsh case for it either -> DROPPED. It was in this table by mistake;
#                      nothing here or in nixsh replaces it.
#   - OBS              display-only, cannot run headless          -> nixrecord (production, not
#                      consumption -- a different repo again, see "What this repo does not own")
#   - asciinema / vhs  RECORD a terminal, need no display server  -> nixsh -- which is also what
#                      keeps nixrecord single-purpose (screen/window/region capture only)
#   - mpv              defaults to a graphical window, which by the rule above would put it here
#                      -- but the operator uses it as the TERMINAL video/audio player and vlc as
#                      the graphical one. Filed in nixsh BY STATED USE, not by its default. Said
#                      plainly, here, so a reader does not conclude the rule was applied loosely:
#                      it was overridden on purpose, once, for a named reason.
#
# What the rule leaves in THIS table: vlc, the graphical media interface. Everything else this
# catalogue used to carry -- ffmpeg, mpv, cmus, yazi, chafa, timg, yt-dlp -- has no display mode
# by default (mpv's stated exception above) and moved to nixsh. zathura and zathura-pdf-poppler
# did not move anywhere; see above.
#
# One entry is not a placeholder for one package, and this repo is not being retired to it: the
# operator has confirmed a graphical image viewer (imv or swayimg) and a comics reader are both
# coming, both belonging here by the same display-and-default test. Add them as their own entries
# when actually decided -- verified against a real system the same way vlc is below -- not
# pre-declared empty ahead of that. If a second kind of graphical entry stops fitting comfortably
# under `players`, that is the point to open a second group, not before.
#
# `arch` is the pacman package, `nixpkgs` the attribute. An `aur` field (default false) exists in
# this table's shape for a pacman name that lives in the AUR rather than an official repo -- see
# nixfont's own lib/fonts.nix header for why that distinction is load-bearing: `pacman -S` fails
# the WHOLE transaction on an AUR name with "target not found", taking every other package in the
# same converge down with it. No entry needs it today; the field stays in the shape because the
# next graphical addition is not guaranteed to be an official-repo package on Arch.
#
# Every (arch, nixpkgs) pair below was verified against a REAL system, not guessed: `pacman -Si
# <name>` against a live CachyOS box for the Arch side, and `nix eval` -- forcing the value, not
# `hasAttrByPath` alone (see experiments/validate-nixpkgs-names.nix's own header for the exact
# class of rename that check alone would miss) -- against the nixpkgs revision infra's own
# flake.lock had pinned at the time (1d4e0f865d68258aada31e68e6d79c8c463f3b34) for the nixpkgs
# side.
{ ... }:
{
  # ── Players ─────────────────────────────────────────────────────────────────────────────────
  players = {
    vlc = {
      arch = "vlc";
      nixpkgs = "vlc";
      note = "the graphical media player -- the everything-plays-it interface for the odd container or codec the terminal player (mpv, filed in nixsh) genuinely refuses to open.";
    };
  };
}
