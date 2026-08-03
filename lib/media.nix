#
# The media catalogue: consumption tools, plus the ffmpeg/mpv pair every machine wants regardless
# of whether "media" is its job.
#
# SCOPE, stated as a boundary rather than a list (same test nixoffice draws for documents): this
# is what a person PLAYS, BROWSES, READS, or FETCHES. Two domains that look media-shaped are
# deliberately NOT here:
#   - PRODUCTION (recording your own screen/window/region) is nixrecord's — OBS
#     declared as a home-manager config that renders profile/scene files, not a package list.
#   - STREAMING TRANSPORT (screen-sharing a desktop session to another box over the network) is
#     nixremote's — it already owns sunshine (host) and moonlight (client). A media catalogue that
#     also carried transport would give a headless box a reason to pull in a
#     streaming client it will never run; the two do not overlap on purpose.
#
# The `base` group is different from the rest of this table on purpose: it is not a media DOMAIN,
# it is a base tool and a base viewer every machine wants, the same way nixfont's gsfonts is wanted
# by a machine with no desktop at all because ghostscript needs it. ffprobe to find out why a file
# is wrong, ffmpeg to cut a clip, mpv to look at what a script just produced — reached for while
# doing something else, not while "doing media" (see modules/nixmedia.nix's own header for the
# infra incident that is the reason ffmpeg/mpv are declared explicitly rather than left to arrive
# as somebody's dependency).
#
# `arch` is the pacman package, `nixpkgs` the attribute (or null where there is no equivalent).
# `aur` (default false, so most entries omit it) marks a pacman name that lives in the AUR rather
# than an official repo — see nixfont's own lib/fonts.nix header for why that distinction is
# load-bearing: `pacman -S` fails the WHOLE transaction on an AUR name with "target not found",
# taking every other package in the same converge down with it.
#
# Every (arch, nixpkgs) pair below was verified against a REAL system, not guessed: `pacman -Si
# <name>` against a live CachyOS box for the Arch side, and `nix
# eval` — forcing the value, not `hasAttrByPath` alone (see experiments/validate-nixpkgs-names.nix's
# own header for the exact class of rename that check alone would miss) — against the nixpkgs
# revision infra's own flake.lock had pinned at the time
# (1d4e0f865d68258aada31e68e6d79c8c463f3b34) for the nixpkgs side. Two names looked like they
# would obviously match and do not; both are recorded properly rather than left as a comment here
# — see studies/zathura-plugin-bundling.md and studies/timg-arch-aur-only.md.
{ ... }:
{
  # ── Base: wanted on every machine ──────────────────────────────────────────────────────────
  base = {
    ffmpeg = {
      arch = "ffmpeg";
      nixpkgs = "ffmpeg";
      note = "ffprobe/ffmpeg — transcode, inspect, and the thing half the rest of a fleet shells out to just to learn a file's real duration rather than trust its container's claim about it.";
    };
    mpv = {
      arch = "mpv";
      nixpkgs = "mpv";
      note = "the player. Declared explicitly rather than left to arrive as somebody's dependency — a package that exists only because something else wanted it can vanish the moment that something else changes its mind, discovered only the next time you try to watch a file.";
    };
  };

  # ── Players ─────────────────────────────────────────────────────────────────────────────────
  players = {
    vlc = {
      arch = "vlc";
      nixpkgs = "vlc";
      note = "the everything-plays-it fallback video player, for the odd container or codec mpv genuinely refuses to open.";
    };
    cmus = {
      arch = "cmus";
      nixpkgs = "cmus";
      note = "terminal music player — a library browser and playback engine with no GUI dependency at all, the audio-library equivalent of mpv's single-file focus.";
    };
  };

  # ── Terminal browsing / preview ────────────────────────────────────────────────────────────
  terminal = {
    yazi = {
      arch = "yazi";
      nixpkgs = "yazi";
      note = "terminal file manager with built-in image/video preview (shells out to a renderer like chafa, and ffmpegthumbnailer for video) — how a media tree gets browsed without a GUI file manager.";
    };
    chafa = {
      arch = "chafa";
      nixpkgs = "chafa";
      note = "renders an image as terminal graphics/ANSI art — what yazi's own preview pane, and anything else wanting a quick terminal look at an image, calls out to.";
    };
    # AUR-only on Arch, an ORDINARY nixpkgs attribute — the INVERSE of the usual drift direction
    # in this family of catalogues (usually Arch has the official package and nixpkgs has the
    # gap; see studies/timg-arch-aur-only.md for the confirmation of both halves).
    timg = {
      arch = "timg";
      aur = true;
      nixpkgs = "timg";
      note = "alternative terminal image/video viewer (sixel- and kitty-graphics-protocol aware). Catalogued alongside chafa as a genuine second choice, not a duplicate — pick the one a given terminal emulator renders better, or both.";
    };
  };

  # ── Viewing / reading ───────────────────────────────────────────────────────────────────────
  viewers = {
    zathura = {
      arch = "zathura";
      nixpkgs = "zathura";
      note = "minimal, keyboard-driven document viewer. On nixpkgs the `zathura` attribute already BUNDLES the poppler/djvu/ps/cb plugins (see zathura-pdf-poppler below, and studies/zathura-plugin-bundling.md for the source proof) — on Arch it ships with no rendering backend at all and needs one named explicitly, which is what the entry below is for.";
    };
    # nixpkgs = null here is not a gap in this catalogue: nixpkgs's own `zathura` attribute
    # (above) already wraps this plugin in by default, so there is no separate nixpkgs attribute
    # for it to point at — selecting `zathura` is the whole story on that platform. Arch's zathura
    # core ships with NO backend at all, so this is a genuine second package there, not
    # duplicated effort. See studies/zathura-plugin-bundling.md.
    zathura-pdf-poppler = {
      arch = "zathura-pdf-poppler";
      nixpkgs = null;
      note = "the PDF rendering backend zathura needs on Arch. Poppler over mupdf: the lighter dependency chain for the common case (zathura-pdf-mupdf also exists in the official repos, for the rarer document that needs mupdf's broader format support).";
    };
  };

  # ── Acquire ─────────────────────────────────────────────────────────────────────────────────
  acquire = {
    yt-dlp = {
      arch = "yt-dlp";
      nixpkgs = "yt-dlp";
      note = "video/audio downloader — the tool half a fleet's own media-ingest scripts already shell out to by this exact name.";
    };
  };
}
