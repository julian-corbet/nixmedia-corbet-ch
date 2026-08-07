#
# The media catalogue: consumption and format-shifting, never capture or authoring. A
# terminal-shaped tool, no matter how media-adjacent it looks, is nixsh's problem now.
#
# FOUR GROUPS below, tested four different ways. `players` is tools a person launches -- the
# display-mode-and-default test right below decides those. `plugins` is GStreamer libraries that
# extend what an already-installed GStreamer application can decode -- a different test, explained
# in that group's own section further down, because the players test does not even apply to a
# library with no entry point of its own. `transcode` is opened for the tool that re-encodes an
# artifact you already have -- neither a player nor a plugin -- see "THE THIRD GROUP" below.
# `accel` is the one HARDWARE-KEYED group: a VA-API driver, selected by a single host-declared
# vendor rather than a name list -- see "THE FOURTH GROUP" below and the README's "Hardware-keyed
# declarations are conditional, never class-wide" for the full argument.
#
# THE PLACEMENT RULE FOR `players`, stated as a test so the next addition is decided rather than
# argued: does the tool have a display mode at all, and is that mode its DEFAULT?
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
# What the `players` rule leaves in that table: vlc, the graphical media interface. Everything
# else this catalogue used to carry -- ffmpeg, mpv, cmus, yazi, chafa, timg, yt-dlp -- has no
# display mode by default (mpv's stated exception above) and moved to nixsh. zathura and
# zathura-pdf-poppler did not move anywhere; see above.
#
# One `players` entry is not a placeholder for one package, and this repo is not being retired to
# it: the operator has confirmed a graphical image viewer (imv or swayimg) and a comics reader are
# both coming, both belonging in `players` by the same display-and-default test. Add them as their
# own entries when actually decided -- verified against a real system the same way vlc is below --
# not pre-declared empty ahead of that. If a second kind of graphical entry stops fitting
# comfortably under `players`, that is the point to open a second group, not before.
#
# THE SECOND GROUP, opened for exactly the reason the paragraph above named in advance. `plugins`
# does not fit `players` at all, because the display-mode-and-default test doesn't even apply to
# it. A GStreamer plugin (gst-plugins-base, -good, -bad, -ugly, gst-libav, gst-plugin-pipewire) is
# not a tool a person launches -- it has no display mode, default or otherwise, because it has no
# entry point of its own. It is a shared library a GStreamer-based application (vlc above, or any
# other GStreamer app the host happens to run) LOADS to gain container/codec support, without ever
# depending on it in the Nix sense -- the application still builds and runs with zero plugins
# installed, it just decodes less. So the placement test for THIS group is stated the same shape
# as the `players` test, but asks something different: does the entry extend what an
# already-installed GStreamer application can play, without itself being something a person opens
# directly? Yes -> `plugins`, filed in THIS repo because it is graphical-media-consumption
# infrastructure -- the same domain `players` is -- not nixdev (which owns libraries you script
# against, never ones that back a person's own media playback) and not nixsh (which owns the
# terminal-shaped players themselves, not the shared library surface a GRAPHICAL player on this
# host reads from).
#
# WHY "ALL SIX", not a curated subset. Capability packages accumulate by ACCIDENT, not by choice,
# when nothing declares them: measured live across the fleet before this group existed, the laptop
# (an Arch host with an ordinary desktop session) already had all six -- nothing put them there on
# purpose, they arrived one at a time as some other package's dependency -- while the Arch desktop
# container had only gst-plugins-base, gst-plugins-ugly and gst-plugin-pipewire: `ugly` and `base`
# solely because onlyoffice-bin depends on them, `plugin-pipewire` the same way via a different
# consumer, and `good`/`bad` absent for no better reason than "nothing on that host happened to
# depend on them yet" (it has neither shortwave nor spice-gtk, the two apps that would have pulled
# them in). Nobody chose either outcome; the dependency graph did. Declaring the full set is what
# makes "a GStreamer app plays anything, consistently, on every host that has a display" true by
# policy instead of by whichever other package happened to pull a plugin in first.
#
# gst-plugin-pipewire IS an entry here, deliberately, even though it sits right next to nixaudio's
# own territory (the PipeWire daemon stack). It is the GStreamer-side SINK a GStreamer app uses to
# reach that daemon -- part of the plugin surface, not part of the daemon itself -- and keeping the
# whole gst-* namespace in one repo is what stops two repos from ever declaring a gst-* package
# each and shadowing one another. Its `nixpkgs` field is `null`, not an oversight: on Arch it is
# its own pacman package (confirmed live, `pacman -Si gst-plugin-pipewire`, official `extra` repo),
# but nixpkgs ships no separate `gst_all_1.gst-plugin-pipewire` attribute at all -- the PipeWire
# GStreamer sink is built INTO the `pipewire` derivation itself (`-Dgstreamer=enabled` is one of
# its default mesonFlags, confirmed against the pinned nixpkgs revision below), which is
# nixaudio's package to own and build, not a second copy for this repo to add. A NixOS host that
# selects this entry will see it surface in `unavailableOnNixos` and the matching build warning --
# EXPECTED, not a bug: there is genuinely nothing separate for the NixOS backend to install, and
# nixaudio already provides the real thing.
#
# THE THIRD GROUP: `transcode`. Not a tool that fits `players` (the artifact-existed-first test
# below is not the display-mode test above) and not a library that fits `plugins` (it has an entry
# point of its own). Opened once a genuinely third KIND of entry arrived, the same way the header
# above says a THIRD kind, not a second `players`-shaped one, is what earns a new group at all. The
# test that decides it, restated as one line (the README's "The transcoding case, decided once"
# has the full argument, including why HandBrake -- which drives an encoder and looks exactly like
# a production tool -- is filed here anyway):
#
#   You RE-ENCODE what you already have. You do not create anything new.
#
# A HandBrake job's input is a programme you already own; its output is the same programme in a
# different container/codec. Nothing entered the world -- unlike a video editor's cut or an OBS
# recording, neither of which existed before the tool ran (nixcreative, nixrecord). The rule is
# about the ARTIFACT, not the direction of the bits: `vlc-plugins-all` pulling in real video
# ENCODERS (`vlc-plugin-x264`, `vlc-plugin-x265`) does not move it out of `plugins` either, for the
# identical reason -- vlc can stream/transcode its own output, but the source is still something
# already opened.
#
# THE FOURTH GROUP: `accel`. The one group in this catalogue that is NOT a flat name -> entry map
# -- it is vendor -> { packages; note; }, the same shape nixgpu's own lib/catalogue.nix uses for
# the identical reason (capability -> vendor -> [ entries ]), because "which package" genuinely
# depends on "which silicon" here in a way nothing else in this table does. Selected by a single
# host-declared `nixmedia.accel = "amd" | "intel" | "nvidia" | null` (modules/nixmedia.nix), never
# by autodetection -- module evaluation must stay pure and portable (a config evaluated on one
# machine and deployed to another must not silently pick up the BUILDER's card), and a detected
# value is a value nobody wrote down. Full argument: the README's "Hardware-keyed declarations are
# conditional, never class-wide".
#
# An EMPTY `packages` list is a correct answer for a vendor cell, not an unfilled one -- this is
# the property a flat name -> package catalogue cannot express, and the whole reason `accel` needs
# a shape of its own. `amd` and `nvidia` both resolve to `[ ]` below for a stated reason each (see
# each cell's own `note`), not for lack of research. Decode is safe to assume class-wide -- every
# OTHER group's entries degrade to software on any silicon -- but encode is not: the class spans an
# Xe2-class iGPU with a hardware AV1 encoder and an RDNA2 card with none, and the shipped HandBrake
# binary carries encoder strings for both regardless of what the card underneath can do. `accel`
# closes the one real gap (`vainfo` reporting zero profiles without it on Intel silicon); it never
# carries an encode PRESET, which is host-level, not class-wide -- see the README's class-wide
# section for why that split matters.
#
# `arch` is the pacman package, `nixpkgs` the attribute (or `null`, see gst-plugin-pipewire above).
# An `aur` field (default false) exists in this table's shape for a pacman name that lives in the
# AUR rather than an official repo -- see nixfont's own lib/fonts.nix header for why that
# distinction is load-bearing: `pacman -S` fails the WHOLE transaction on an AUR name with "target
# not found", taking every other package in the same converge down with it. No entry needs it
# today -- every entry across all four groups below is an official-repo package on Arch -- the
# field stays in the shape because the next addition is not guaranteed to be.
#
# Every (arch, nixpkgs) pair below was verified against a REAL system, not guessed: `pacman -Si
# <name>` against a live CachyOS box for the Arch side, and `nix eval` -- forcing the value, not
# `hasAttrByPath` alone (see experiments/validate-nixpkgs-names.nix's own header for the exact
# class of rename that check alone would miss) -- against the nixpkgs revision infra's own
# flake.lock had pinned at the time (1d4e0f865d68258aada31e68e6d79c8c463f3b34) for the nixpkgs
# side. The one deliberate exception is gst-plugin-pipewire's `nixpkgs = null` -- not unverified,
# verified ABSENT, for the reason given above.
#
# `vlc-plugins-all`, `libdvdcss`, `handbrake` and `intel-media-driver` were verified live the same
# way, 2026-08-07, against this flake's OWN pinned nixpkgs revision
# (a5cbcfe954791221bfffe2307f7d1a1bf61a871e -- see flake.lock): `pacman -Si` for all four Arch
# names (including confirming `libva-mesa-driver` no longer exists as a separate package, folded
# into `mesa`), and a force-evaluating `nix eval` for the three real nixpkgs attributes plus
# `vlc-plugins-all`'s verified-ABSENT one.
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

  # ── Plugins: the GStreamer plugin/codec surface ────────────────────────────────────────────
  # Libraries, not tools -- see the header's "THE SECOND GROUP" section for the placement test and
  # why it differs from the one `players` uses above.
  plugins = {
    "gst-plugins-base" = {
      arch = "gst-plugins-base";
      nixpkgs = "gst_all_1.gst-plugins-base";
      note = "core elements almost every GStreamer pipeline needs -- typefind, playbin, the basic audio/video sinks.";
    };

    "gst-plugins-good" = {
      arch = "gst-plugins-good";
      nixpkgs = "gst_all_1.gst-plugins-good";
      note = "LGPL, well-maintained container/codec set.";
    };

    "gst-plugins-bad" = {
      arch = "gst-plugins-bad";
      nixpkgs = "gst_all_1.gst-plugins-bad";
      note = "less mature but widely needed -- many modern container/codec paths live here, not in \"good\".";
    };

    "gst-plugins-ugly" = {
      arch = "gst-plugins-ugly";
      nixpkgs = "gst_all_1.gst-plugins-ugly";
      note = "good code, patent-encumbered formats.";
    };

    "gst-libav" = {
      arch = "gst-libav";
      nixpkgs = "gst_all_1.gst-libav";
      note = "the FFmpeg-backed decoder set -- the broadest single-entry coverage of the five plugin groups.";
    };

    "gst-plugin-pipewire" = {
      arch = "gst-plugin-pipewire";
      # No separate nixpkgs attribute -- baked into the `pipewire` derivation itself
      # (`-Dgstreamer=enabled`). See the header's "gst-plugin-pipewire IS an entry here" paragraph.
      nixpkgs = null;
      note = "the PipeWire SINK for GStreamer -- how a GStreamer app reaches the audio daemon nixaudio owns. Filed here, with the rest of the gst-* surface, so one repo owns all of it.";
    };

    "vlc-plugins-all" = {
      arch = "vlc-plugins-all";
      # Verified ABSENT, not unverified: nixpkgs ships vlc as ONE derivation with plugins built
      # in -- `vlc-plugins-all` force-evaluates to no such attribute against this flake's own
      # pinned nixpkgs revision. See the header's verification paragraph.
      nixpkgs = null;
      note = "Arch splits vlc across ~40 packages and `vlc` alone pulls a MINIMAL set (vlc-plugins-base, vlc-plugins-video-output, vlc-plugin-lua, vlc-plugin-pulse). Absent without this entry: libavcodec decoding AND AV1 decoding (vlc-plugin-ffmpeg, vlc-plugin-aom are both optional deps, never pulled automatically -- on hardware that decodes AV1 in silicon), DVD, Blu-ray, ASS/SSA subtitles, MPEG-2, DTS, SFTP/NFS/UPnP/RTSP/SRT input, Chromecast. Without it, the identical `players = [ \"vlc\" ]` declaration yields a materially weaker player on Arch than on NixOS, silently.";
    };

    libdvdcss = {
      arch = "libdvdcss";
      nixpkgs = "libdvdcss";
      note = "`pacman -Qii libdvdcss` reports Optional For: handbrake libdvdread vlc-plugin-dvd -- three consumption-side consumers, and pacman never installs an optdepend. Absent from nixpkgs' vlc build inputs too (loaded at runtime, not linked). Without it, an encrypted DVD image on disk simply fails to open, in both the player and the transcoder, with no missing-package error anywhere.";
    };
  };

  # ── Transcode: format-shifting, not creation ───────────────────────────────────────────────
  # See the header's "THE THIRD GROUP" section for the placement test and why HandBrake is filed
  # here rather than as a production tool.
  transcode = {
    handbrake = {
      arch = "handbrake";
      nixpkgs = "handbrake";
      note = "the format-shifter -- re-encodes a programme already on disk into a different container/codec. Its Arch hard-dep on gst-plugins-base, plus optdeps on gst-plugins-good/gst-libav for video previews, already lean on the `plugins` group above. The package itself is class-wide (it bundles SVT-AV1, a software AV1 encode path with no hardware dependency, alongside encoder strings for hardware paths the class's own silicon may or may not back) -- an ENCODE PRESET naming one of those hardware paths is not, and this repo does not carry one. It declares the transcoder; it never declares how to encode.";
    };
  };

  # ── Accel: the one hardware-keyed group ────────────────────────────────────────────────────
  # See the header's "THE FOURTH GROUP" section for the shape, the selection mechanism
  # (modules/nixmedia.nix's single `nixmedia.accel` option, never autodetected), and why an empty
  # `packages` list is a correct answer for `amd`/`nvidia` below, not an unfilled one.
  accel = {
    amd = {
      packages = [ ];
      note = "Mesa's radeonsi VA-API driver ships inside the mesa build itself. Arch's separate libva-mesa-driver package no longer exists -- verified live, `pacman -Si libva-mesa-driver` resolves nothing; folded into mesa. On NixOS, hardware.graphics.enable already installs mesa. Nothing to add, on either plane.";
    };

    intel = {
      packages = [
        {
          arch = "intel-media-driver";
          nixpkgs = "intel-media-driver";
        }
      ];
      note = "The iHD driver, Broadwell and newer. The one cell that closes a real gap: without it, `vainfo` on Intel silicon reports no profiles at all. A MOVE out of nixgpu's toolchain.capabilities.videoAccel intel cell, not a duplicate -- one package belongs to one catalogue.";
    };

    nvidia = {
      packages = [ ];
      note = "NVENC/NVDEC are not exposed through VA-API; the proprietary runtime talks to them directly. The third-party nvidia-vaapi-driver shim is not carried, for lack of evidence anything in the class needs it. No host in the class has this silicon -- the cell is empty for a stated reason, not for lack of research.";
    };
  };
}
