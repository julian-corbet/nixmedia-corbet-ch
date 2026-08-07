# nixmedia

**What you play and what you re-encode, declared once for a whole host class — assuming no
hardware, and asking for hardware only when a host has named it.**

nixmedia is the *consumption* half of the media domain: the graphical players a person opens, the
plugin surface those players load to actually decode something, the transcoder that format-shifts a
file you already have, and the tools that maintain a collection you already own. Nothing here
captures, records, authors, or streams.

Unlike every other display-substrate repo in this family, nixmedia is **class-wide**: every host of
the `nixarch` class (Arch/CachyOS managed by system-manager + home-manager) composes it, not just
the ones with a particular GPU, a particular session, or a particular job. A NixOS host outside that
class composes it too, for its own seated development session. That single fact constrains the
catalogue harder than any style rule does — see
[Class-wide means no hardware may be assumed](#class-wide-means-no-hardware-may-be-assumed).

**Class-wide is about composition, not about selection.** Every group is empty until a host names
what it wants. "The repo is present everywhere" and "every host installs the same thing" are
different claims, and only the first one is made here.

## The placement rule

"It's media-ish" decides nothing, and media tooling sprawls further than almost any other domain —
a player, a codec library, a tag editor, a transcoder, a screen recorder and a video editor all
touch the same files. Three questions, asked **in this order**, decide where any new entry goes
without argument.

### 1. Is it a tool a person opens, or a library something else loads?

A library has no entry point of its own — it is loaded by an application that would still run
without it, just doing less. The display-mode test in question 2 does not even apply to it. Ask
instead: **which application loads it?**

| Loaded by | Goes to |
|---|---|
| a media application — a player, a transcoder | **`plugins`, here** |
| the desktop's file-manager preview pipeline (tumbler, gdk-pixbuf) | the file-manager role in [nixdesktop][nixdesktop] |
| code you write | [nixdev][nixdev] |
| *whatever GPU is present*, with no media application presupposed | [nixgpu][nixgpu]'s — hardware-keyed, never a class-wide declaration this repo can make honestly. See [What this repo does not own](#what-this-repo-does-not-own) |

That test is not academic. `ffmpegthumbnailer` and `libopenraw` look like media libraries and are
not: `pacman -Sii` reports their consumers as `tumbler`, `nemo`, `ranger` and `gdk-pixbuf2` — every
one of them a *file browser* rendering a preview grid, never a media player decoding a stream.
Both belong to the file-manager role that already declares them, and moving them here would split
one role's dependencies across two repos for no gain.

### 2. If it is a tool: does it default to a graphical window?

**No → [nixsh][nixsh]**, the terminal-tool catalogue. This is the family-wide layer test, stated in
full in that repo and mirrored in `lib/media.nix`'s header here.

"Can it be coaxed into a terminal" is deliberately **not** the test. `mpv` ships `--vo=sixel` and
OBS cannot run headless at all; a test built on capability rather than default misfiles both, in
opposite directions.

**`mpv` is the one deliberate exception**, called out so no reader concludes the rule was applied
loosely. It defaults to a graphical window, which by this test would put it here — but it is used
as the *terminal* video/audio player with vlc reserved as the graphical one, so it is filed in
nixsh **by stated use, not by its default**. That override happened once, for a named reason, and
is not a precedent. It is declared in exactly one place.

**A CLI that is the same tool as a catalogued GUI stays with the GUI.** `handbrake` and
`handbrake-cli` are two Arch packages of one program; splitting one tool across two repos by its
frontend is the worst available outcome, so question 2 is asked about the *tool*, not about each
package name a distro happens to cut it into.

### 3. If it defaults to a window: did the artifact already exist before the tool ran?

- **Yes** — you play it, browse it, tag it, or re-encode it → **consumption. Here.**
- **No** — the tool brings something into the world that was not there → **production**, and
  production splits by what is captured: `nixrecord` owns real-world capture only (camera,
  microphone, capture card); a digital interface is captured by whichever repo already owns that
  interface — the desktop's screen/window/region capture is [nixremote][nixremote]'s /
  [nixdesktop][nixdesktop]'s, never nixrecord's — and authoring (editing, compositing, mixing,
  painting) is `nixcreative`'s.

Stated as one line: **consumption and format-shifting live here; capture and authoring do not.**

### The transcoding case, decided once

Transcoding is the genuinely arguable one, and it is filed here on purpose. HandBrake sits right
against the production boundary: it drives an encoder, it has bitrate ladders and quality presets,
it looks exactly like the front end of a video pipeline. Every one of those observations is about
*mechanism*, and mechanism is not the test.

The rule that settles it, and that settles the next case like it:

> **You re-encode what you already have. You do not create anything new.**

A HandBrake job's input is a programme you already own; its output is the same programme in a
different container or codec. Nothing entered the world. Compare a video editor: the cut it emits
did not exist before, and no amount of "but it also runs an encoder" changes that. Same for OBS —
the recording is new. Format-shifting is a property of the artifact, not of the CPU work involved,
and the artifact-existed-first question answers it every time.

Two corollaries make the rule cheap to apply later:

- A transcoder belongs here **as a tool**, never **as a policy**. Its encode settings are not
  class-wide — see the next section.
- The rule is about the *artifact*, not about the direction of the bits. `vlc-plugins-all` pulls in
  `vlc-plugin-x264` and `vlc-plugin-x265` — genuine video **encoders** — because vlc can stream and
  transcode its own output. That is still format-shifting something you already opened, so it stays
  on this side of the line. An encoder is not evidence of production.

### Worked examples

| Entry | Kind | Test that decides it | Filed |
|---|---|---|---|
| `vlc` | tool | graphical default; the file exists first | **here** (`players`) |
| `shortwave` | tool | graphical default; a stream you tune into, not one you make | **here** (`players`) |
| `handbrake` | tool | graphical default; format-shift, not creation | **here** (`transcode`) |
| `easytag` | tool | graphical default; edits metadata on a collection you own | **here** (`library`) |
| `gst-libav`, `gst-plugins-*` | library | loaded by a media application | **here** (`plugins`) |
| `vlc-plugins-all` | library | loaded by vlc | **here** (`plugins`) |
| `libdvdcss` | library | loaded by vlc's DVD plugin *and* by HandBrake | **here** (`plugins`) |
| `intel-media-driver` | driver | keyed to one vendor's silicon, no application presupposed | [nixgpu][nixgpu] (`toolchain.capabilities.videoAccel`) — **never here** |
| `ffmpegthumbnailer` | library | loaded by tumbler/nemo/ranger — a file browser | [nixdesktop][nixdesktop] |
| `libopenraw` | library | loaded by gdk-pixbuf/tumbler — the preview pipeline | [nixdesktop][nixdesktop] |
| `mpv`, `cmus`, `ffmpeg`, `yt-dlp` | tool | no graphical default (mpv: stated exception) | [nixsh][nixsh] |
| OBS | tool | the recording is new — desktop capture, a digital interface | [nixremote][nixremote] / [nixdesktop][nixdesktop] |
| a video editor, a DAW, a raster editor | tool | the cut/mix/image is new | `nixcreative` |
| sunshine, moonlight | tool | transport, not content — see below | [nixremote][nixremote] |
| `zathura` | — | a GTK document viewer, never a TUI and never media | **dropped**, replaced by nothing |

## Class-wide means no hardware may be assumed

Every host of the class composes this repo, so **every unconditional declaration here lands on
hardware nobody checked first.** That is a stronger constraint than it sounds, and it is the reason
this repo is thin.

The test: *would this package be wrong, broken, or pointless on a host of the same class with
different silicon?* If yes, it is not an unconditional declaration, and it belongs either somewhere
keyed to the thing that actually varies, or in the one group here that carries a key of its own.

**Decode is safe to assume — and the repo does not even need to assume it.** Every unconditional
entry in the catalogue is decode-side, and every decode path here degrades to software. A host with
no video acceleration at all still plays everything; it just spends CPU doing it. A class-wide
declaration that is merely *slower* on some hosts is fine. One that is *broken* on some hosts is
not.

**Encode is where the asymmetry bites.** The class spans silicon with a hardware AV1 encoder
(Xe2-class integrated graphics: `vainfo` reports `VAProfileAV1Profile0` with both `VAEntrypointVLD`
**and** `VAEntrypointEncSlice`) and silicon without one (RDNA2 discrete: `VAProfileAV1Profile0` with
`VAEntrypointVLD` only — RDNA2 has no AV1 encode block at all). Both decode AV1. Only one produces
it.

What makes this genuinely dangerous rather than merely uneven: **the software is identical on both.**
The shipped HandBrake binary carries `qsv_av1`, `vce_av1`, `nvenc_av1` and `svt-av1` encoder strings
on every host of the class, regardless of what the card underneath can do. Nothing about the
installed package tells you which of those four will produce a file. Only `vainfo` does.

So:

- **`handbrake` the package is class-wide.** Identical on both, and it bundles SVT-AV1 for a
  software AV1 path where there is no hardware one. Slow, correct, never broken.
- **A HandBrake *preset* is not.** An encode profile naming `vce_av1` is offered by the same binary
  on both halves of the class and produces nothing on one of them. Presets, encoder selections and
  quality ladders are host-level or hardware-keyed declarations, and this repo does not carry them.
  It declares the transcoder; it never declares how to encode.
- **Whether a host should *run* the transcoder is also not this repo's call.** A host whose GPU is
  shared with a scheduler has a contention question no catalogue can answer. Selecting `transcode`
  is a per-host decision; carrying the entry is not.

This is also why the repo has no notion of a "default selection". Every group is empty until a host
names what it wants, and an empty selection is a legitimate answer for a machine with no seated
session at all.

## Hardware-keyed packages are never a class-wide declaration

A VA-API driver is keyed to **silicon**. The rest of this repo is keyed to a **host class**. Those
are different keys, and the naive resolutions of that conflict are both wrong: declaring a driver
unconditionally puts one vendor's driver on every host of a mixed-vendor class, and a group whose
every non-empty cell is one vendor's package is not "the media catalogue with an extra key" — it is
a second hardware catalogue wearing this repo's name.

This repo briefly carried exactly that group (`accel`, a VA-API driver selected by a host-declared
GPU vendor) and removed it: `intel-media-driver`, the one package it ever resolved to, was already
declared by [nixgpu][nixgpu]'s own `toolchain.capabilities.videoAccel`, keyed the identical way, for
the identical reason. One package belongs to one catalogue, and the catalogue a hardware-keyed
package belongs to is the hardware repo's, not the class-wide consumption repo's — see
[What this repo does not own](#what-this-repo-does-not-own).

## The catalogue

`lib/media.nix` is the single data table; `modules/nixmedia.nix` turns a selection into resolved
package lists. Each entry maps a name to a pacman package (`arch`), a nixpkgs attribute path
(`nixpkgs`), and an `aur` flag (default `false`).

`aur` is load-bearing even though nothing needs it today: `pacman -S` fails the **whole
transaction** on an AUR name with "target not found", taking every unrelated package in the same
converge down with it, so AUR names are published on a separate list the reconciler handles
differently.

Either channel may be `null`, meaning *verified absent*, not *unverified*:

- `gst-plugin-pipewire` has `nixpkgs = null` — the PipeWire GStreamer sink is compiled into the
  `pipewire` derivation itself (`-Dgstreamer=enabled`), which is [nixaudio][nixaudio]'s package to
  own. A NixOS host selecting it sees it in `unavailableOnNixos` with a warning. That is the
  correct outcome, not a bug.

Every `(arch, nixpkgs)` pair was verified against a real system — `pacman -Si` against a live
CachyOS box, and `nix eval` **forcing the value** (not `hasAttrByPath`, which cannot tell a real
package from nixpkgs' `throw "renamed to ..."` stub) against this flake's own pinned nixpkgs
revision.

### Groups today

| Group | Test | Entries |
|---|---|---|
| `players` | a tool you open to consume something that already exists | `vlc`, `shortwave` |
| `plugins` | a library with no entry point that extends what an installed media application can read | `gst-plugins-base`, `gst-plugins-good`, `gst-plugins-bad`, `gst-plugins-ugly`, `gst-libav`, `gst-plugin-pipewire`, `vlc-plugins-all`, `libdvdcss` |
| `transcode` | a tool that re-encodes an artifact you already have — neither a player nor a plugin | `handbrake` |
| `library` | a tool that maintains a collection you already own — edits metadata, never content | `easytag` |

The `plugins` group is named that rather than `codecs` on purpose: `gst-plugin-pipewire` is an
audio *sink*, not a codec, and `vlc-plugins-all`/`libdvdcss` are a whole-application plugin bundle
and a runtime-loaded decryption library respectively — the group is about the *shape* of an entry
(a library with no entry point of its own), not about a namespace.

**Why the whole GStreamer set, not a curated subset.** Capability packages accumulate by *accident*
when nothing declares them. Measured live across the class before this group existed: one host had
all six, arriving one at a time as some unrelated package's dependency; another had only three,
pulled in by an office suite, with `good` and `bad` missing for no better reason than "nothing
installed here happened to depend on them yet". Nobody chose either outcome — the dependency graph
did. Declaring the full set makes *"a GStreamer application plays anything, consistently, on every
host of the class"* true by policy instead of by coincidence. `shortwave`'s hard dependency on
`gst-plugins-{base,good,bad}` is a live example of the same coincidence in the other direction:
install one app and three plugins appear; skip it and they do not.

`vlc-plugins-all` is the same argument one level up: Arch splits vlc across ~40 packages and `vlc`
alone pulls a **minimal** set (`vlc-plugins-base`, `vlc-plugins-video-output`, `vlc-plugin-lua`,
`vlc-plugin-pulse`); `vlc-plugin-ffmpeg` and `vlc-plugin-aom` are both *optional* deps that never
arrive on their own, so **libavcodec decoding and AV1 decoding are both absent from a plain `vlc`
install**, on hardware that decodes AV1 in silicon. Also missing without it: DVD, Blu-ray, ASS/SSA
subtitles, MPEG-2, DTS, SFTP/NFS/UPnP/RTSP/SRT input, Chromecast. nixpkgs ships vlc as **one**
derivation with plugins built in — `vlc-plugins-all` force-evaluates to *absent* there, so
`nixpkgs = null` — meaning without this entry the identical `players = [ "vlc" ]` declaration
yields a materially weaker player on Arch than on NixOS, silently. `libdvdcss` closes the DVD-key
gap alongside it: `pacman -Qii libdvdcss` reports `Optional For: handbrake libdvdread
vlc-plugin-dvd`, and pacman never installs an optdepend — without it an encrypted DVD image on
disk simply fails to open, in both the player and the transcoder, with no missing-package error
anywhere.

`transcode` opened for `handbrake`, the format-shifter: a transcoder is neither a player nor a
plugin, which is exactly the pre-registered trigger for opening a third group (see "The
transcoding case, decided once" above for why it is filed as consumption rather than production).
Its Arch hard-dep on `gst-plugins-base` plus optdeps on `gst-plugins-good`/`gst-libav` (video
previews) already leans on the `plugins` group.

`shortwave` joined `players` alongside `vlc`: GTK4/libadwaita internet radio, a stream you tune
into rather than a file you already have, but still consumption by the artifact-existed-first test
— the station existed before the app opened it. Its Arch hard-dep on
`gst-plugins-base`/`-good`/`-bad` is the live example the "Why the whole GStreamer set" paragraph
above already named: install shortwave and three plugins arrive as a side effect, skip it and they
do not.

`library` opened for `easytag`, the second pre-registered trigger the transcoding section named in
advance: a tool that is neither a player (nothing is played through it) nor a transcoder (the
audio stream's bytes never change, only the ID3/Vorbis/etc. metadata wrapped around them does).
The group's test generalises cleanly to the obvious future additions this repo does not carry yet
— beets, picard.

### Deliberately not declared

Package-to-repo assignment is the operator's call. The names below were considered and rejected,
with reasons, so the same names do not come back as a "why isn't this here" question later. Every
Arch fact below is from `pacman -Si`/`-Qii` on a live host; every nixpkgs attribute was
force-evaluated against this flake's pinned revision.

- **`intel-media-driver`, `vpl-gpu-rt`, `intel-media-sdk`** — VA-API/QuickSync drivers and
  runtimes, all keyed to GPU silicon rather than to the host class. [nixgpu][nixgpu]'s domain, not
  this repo's — see [Hardware-keyed packages are never a class-wide declaration](#hardware-keyed-packages-are-never-a-class-wide-declaration).
- **`ffmpegthumbnailer`, `libopenraw`** — the file-manager preview pipeline's, already declared by
  that role. Their consumers are file browsers, not media applications.
- **`libaacs`** — the same *shape* as `libdvdcss` for Blu-ray, and rejected precisely because the
  shape is not the test: it does nothing without an external key database that no package ships.
  Declaring it would declare a capability that does not work. (It resolves fine on both planes —
  this is a functional rejection, not an availability one.)
- **`libdvdread`, `libdvdnav`, `libbluray`** — real hard dependencies of the vlc plugin split, so
  they arrive on their own. Declaring a package the graph already guarantees adds a maintenance
  surface and buys nothing.
- **`libva`, `libva-utils`, `mesa`** — the VA-API library and its probe (`vainfo`) are substrate
  underneath every consumer, media or not. `libva-utils` is already [nixgpu][nixgpu]'s, in the
  vendor-neutral `probes` cell where it belongs; `mesa` is the base graphics stack's.
- **`handbrake-cli`** — same tool as `handbrake`; see question 2. Not proposed separately, and if it
  is ever wanted it belongs to the same entry, not to nixsh.
- **`svt-av1`, `dav1d`** — present on the class as transitive dependencies of the tools that use
  them. Encoder/decoder implementation libraries with no independent consumer here; declaring them
  would restate the dependency graph.
- **`mpv`, `cmus`, `ffmpeg`, `yt-dlp`** — already declared through [nixsh][nixsh]'s tool catalogue.
  Not moved.
- **`playerctl`** — an MPRIS *control* client. It sends commands to whatever is playing and decodes
  nothing; its consumers are a status bar and a key binding, not a media application. Desktop
  session policy, not this repo.

## What moved out

`ffmpeg`, `mpv`, `cmus`, `yazi`, `chafa`, `timg` and `yt-dlp` were once catalogued here. All have no
graphical default (mpv by its stated exception) and live in [nixsh][nixsh] now. A consumer that used
to select any of them from `nixmedia` selects them from nixsh instead. `zathura` and
`zathura-pdf-poppler` moved nowhere — they were in this table by mistake, were never TUIs, and were
dropped outright.

## What this repo does not own

- **Terminal-shaped tools**, however media-adjacent — [nixsh][nixsh]'s.
- **Recording and authoring** — `nixrecord` (real-world capture — camera, microphone, capture
  card — as rendered OBS profile and scene files, not a package list; screen/window/region capture
  is a digital interface and belongs to whichever repo owns it instead, e.g.
  [nixremote][nixremote]/[nixdesktop][nixdesktop], never nixrecord) and `nixcreative` (editors and
  composition tools).
- **Streaming and remote-desktop transport** — [nixremote][nixremote] owns sunshine and moonlight.
  The boundary exists specifically so a headless box never acquires a reason to pull in a streaming
  client.
- **VA-API drivers, compute SDKs, Vulkan ICDs, vendor telemetry, 32-bit gaming stacks** —
  [nixgpu][nixgpu]'s. Any package whose correct variant depends on which GPU vendor a host has is
  hardware-keyed, and this repo does not carry hardware-keyed declarations at all — see
  [Hardware-keyed packages are never a class-wide declaration](#hardware-keyed-packages-are-never-a-class-wide-declaration).
- **The audio daemon itself** — [nixaudio][nixaudio]'s. This repo carries the GStreamer-side sink
  that reaches it, and nothing else, so the whole `gst-*` namespace has exactly one owner and two
  repos can never shadow each other on it.
- **Encode policy** — presets, encoder selections and quality ladders. Host-level, for the reason
  the class-wide section gives.

## Platform support

| Backend | Behaviour |
|---|---|
| `nixosModules.default` | Installs via `environment.systemPackages`. Force-evaluates every nixpkgs attribute first (`tryEval`, not `hasAttrByPath`) so one stale mapping in a data table degrades to a skip plus a warning instead of failing the whole system evaluation. |
| `homeManagerModules.default` | Same resolution, installing to `home.packages` — for a per-user selection on a host whose system layer is not yours to change. |
| `systemManagerModules.default` | Installs nothing. Publishes `nixmedia.archPackages` and `nixmedia.aurPackages` for the host's own [nixarch][nixarch] reconciler. **We do not shadow**: on Arch a selected package comes from pacman, never a second copy from nixpkgs. |

## Usage

```nix
{
  imports = [ inputs.nixmedia.nixosModules.default ]; # or .homeManagerModules.default
                                                      # or .systemManagerModules.default

  nixmedia = {
    players = [ "vlc" "shortwave" ];
    plugins = [
      "gst-plugins-base"
      "gst-plugins-good"
      "gst-plugins-bad"
      "gst-plugins-ugly"
      "gst-libav"
      "gst-plugin-pipewire"
      "vlc-plugins-all"
      "libdvdcss"
    ];
    transcode = [ "handbrake" ];
    library = [ "easytag" ];
  };
}
```

On Arch, wire the resolved lists into the reconciler — the module installs nothing itself:

```nix
{
  imports = [ inputs.nixmedia.systemManagerModules.default ];
  nixarch.packages.pacman = config.nixmedia.archPackages;
  nixarch.packages.aur    = config.nixmedia.aurPackages;
}
```

`nixmedia.aurPackages` is empty today — every catalogued entry is an official-repo package on Arch
— and is still worth wiring, because the next addition is not guaranteed to be.

## Repository layout

| Path | Purpose |
|---|---|
| `flake.nix` | `nixosModules.default`, `homeManagerModules.default`, `systemManagerModules.default`, `lib.catalogue`, `checks`. The `nixpkgs` input is used **only** by this flake's own checks — the exported modules take `pkgs` from whatever evaluation composes them, so composing this flake can never add a second nixpkgs to a consumer's closure. |
| `lib/media.nix` | The catalogue: one entry per selectable name, platform package names, and every placement rule in full with worked examples. |
| `modules/nixmedia.nix` | Policy: selection groups (`players`/`plugins`/`transcode`/`library`) and the resolved `archPackages`/`aurPackages`/`nixosPackages`/`unavailableOnNixos` lists. |
| `modules/nixos.nix`, `modules/arch.nix`, `home/nixmedia.nix` | The three backends. |
| `checks/` | `nix flake check`-wired proof that selection and resolution are wired correctly — including that a name which left the catalogue is *rejected*, not silently accepted. Module evaluation, not a package build. |
| `experiments/` | `validate-nixpkgs-names.nix` (force-eval every catalogued nixpkgs name against a real package set) and `verify-package-names.sh` (the full Arch + AUR + nixpkgs verification, reproducible). |
| `studies/` | Findings from those experiments that changed the catalogue's shape. |

## Related projects

Part of the same independently-usable module family. The ones this repo draws a boundary against:
[nixsh][nixsh] (terminal tools — the other side of the display-default test),
[nixgpu][nixgpu] (compute SDKs, ICDs, vendor telemetry, and every VA-API driver — the hardware-keyed
side of the class/silicon boundary), [nixremote][nixremote] (streaming transport),
[nixaudio][nixaudio] (the audio daemon),
[nixdesktop][nixdesktop] (desktop policy, including the file-manager preview pipeline), and
[nixarch][nixarch] (the Arch reconciler every `systemManagerModules` backend in this family
publishes into).

`nixrecord` (real-world capture — camera, microphone, capture card) and `nixcreative` (authoring)
are the production side of the artifact-existed-first test. Both are named throughout this README
as the destination for anything this repo turns away, and neither is published yet — the boundary
is decided even where the repo
behind it is not yet public.

[nixsh]: https://github.com/julian-corbet/nixsh-corbet-ch
[nixdesktop]: https://github.com/julian-corbet/nixdesktop-corbet-ch
[nixremote]: https://github.com/julian-corbet/nixremote-corbet-ch
[nixgpu]: https://github.com/julian-corbet/nixgpu-corbet-ch
[nixaudio]: https://github.com/julian-corbet/nixaudio-corbet-ch
[nixdev]: https://github.com/julian-corbet/nixdev-corbet-ch
[nixarch]: https://github.com/julian-corbet/nixarch-corbet-ch

## License

MIT.
