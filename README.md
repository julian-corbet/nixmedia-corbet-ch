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
| *whatever GPU is present*, with no media application presupposed | **`accel`, here — but only conditionally.** See [Hardware-keyed declarations are conditional](#hardware-keyed-declarations-are-conditional-never-class-wide) |

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
- **No** — the tool brings something into the world that was not there → **production**:
  `nixrecord` (screen/window/region capture), `nixcreative` (authoring — editing, compositing,
  mixing, painting).

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
| `intel-media-driver` | driver | keyed to one vendor's silicon, no application presupposed | **here** (`accel`) — **only under a host-declared vendor** |
| `ffmpegthumbnailer` | library | loaded by tumbler/nemo/ranger — a file browser | [nixdesktop][nixdesktop] |
| `libopenraw` | library | loaded by gdk-pixbuf/tumbler — the preview pipeline | [nixdesktop][nixdesktop] |
| `mpv`, `cmus`, `ffmpeg`, `yt-dlp` | tool | no graphical default (mpv: stated exception) | [nixsh][nixsh] |
| OBS | tool | the recording is new | `nixrecord` |
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

## Hardware-keyed declarations are conditional, never class-wide

A VA-API driver is keyed to **silicon**. The rest of this repo is keyed to a **host class**. Those
are different keys, and the naive resolutions of that conflict are both wrong: declaring a driver
unconditionally puts one vendor's driver on every host of a mixed-vendor class, and refusing to
declare it at all leaves the class-wide media stack unable to say why a video plays without burning
a CPU core.

The resolution is a group with a key of its own. **`accel` may declare hardware-specific packages,
conditional on a vendor the host itself has declared.** Four properties make it decidable, and each
one prevents a specific failure.

### 1. The condition keys off a host declaration, never detection

```nix
nixmedia.accel = "intel";   # null (the default) | "amd" | "intel" | "nvidia"
```

One option, `nullOr (enum [ "amd" "intel" "nvidia" ])`, default `null`. The host states its silicon.
The module never looks at `/sys/class/drm/*/device/vendor`, and never will.

Two reasons, either sufficient. Module evaluation is **pure and portable**: a config may be
evaluated on a build host and deployed to a different machine, so a `/sys` read at eval time
resolves against the *builder's* card and silently produces a driver for hardware that is somewhere
else entirely. And a detected value is a value nobody wrote down — the declaration stops being a
statement of intent you can diff, and becomes a function of whichever machine happened to run the
evaluation.

### 2. Single-valued, so the ambiguous state is unrepresentable

`accel` is one vendor, not a list. Installing two VA-API drivers at once leaves `libva` picking
between them, and the fix is an explicit `LIBVA_DRIVER_NAME` — host policy, not a catalogue entry.
Making the option single-valued means the broken state cannot be spelled, rather than being
discouraged in a comment nobody reads.

### 3. An empty cell is a correct answer, not an unfilled one

This is the property a flat *name → package* catalogue cannot express, and it is the whole reason
`accel` needs a shape of its own rather than another list of names.

| Vendor | Packages | Why |
|---|---|---|
| `amd` | **none, on either plane** | Mesa's `radeonsi` VA-API driver ships inside the `mesa` build itself. Arch's separate `libva-mesa-driver` package **no longer exists** — verified, `pacman -Si libva-mesa-driver` resolves nothing; it was folded into `mesa`. On NixOS `hardware.graphics.enable` already installs mesa. There is genuinely nothing to add. |
| `intel` | `intel-media-driver` | The iHD driver, Broadwell and newer. The one entry that closes a real gap: without it, `vainfo` on Intel silicon reports no profiles at all. |
| `nvidia` | **none** | NVENC/NVDEC are not exposed through VA-API; the proprietary runtime talks to them directly. The third-party `nvidia-vaapi-driver` shim is not carried, for lack of evidence anything in the class needs it. No host in the class has this silicon — the cell is empty for a stated reason, not for lack of research. |

A host declaring `accel = "amd"` therefore receives **zero packages and a working VA-API stack**.
That is the correct outcome. A catalogue that could only express "this name maps to a package" would
have had to invent one.

### 4. `null` contributes nothing by construction

```nix
accelEntries = if cfg.accel == null then [ ] else catalogue.accel.${cfg.accel}.packages;
```

Not a filter that can be forgotten, not a warning, not an error — a host that declares no vendor
resolves to the empty list before any lookup happens. It gets software decode, which the class-wide
rule above already establishes is an acceptable outcome. This is the same construction
[nixgpu][nixgpu]'s own `vendor = null` uses, reused rather than reinvented.

### The NixOS plane is an option, not a package list

`accel` is the first group here whose two planes are not the same kind of thing, and getting this
wrong produces a build that succeeds and a driver that is never loaded.

nixpkgs builds `libva` with `-Ddriverdir=${mesa.driverLink}/lib/dri:/usr/lib/dri:...`, and
`mesa.driverLink` is `/run/opengl-driver` — which the NixOS graphics module populates from
`hardware.graphics.package` plus **`hardware.graphics.extraPackages`**, and from nothing else.
(nixpkgs is explicit about this: the old `services.xserver.vaapiDrivers` option is a
`mkRenamedOptionModule` pointing straight at `extraPackages`.)

A VA-API driver placed in `environment.systemPackages` therefore lands in the store, appears in the
system closure, and is **never found by `libva`**. It is inert.

So the resolved lists split:

| Plane | Where `accel` entries go | Why |
|---|---|---|
| Arch (`archPackages`) | the same pacman list as everything else | `/usr/lib/dri` is already on libva's default `driverdir`. |
| NixOS | a separate `nixmedia.graphicsPackages`, wired to `hardware.graphics.extraPackages` — **never** `environment.systemPackages` | see above. `accel` entries are deliberately absent from `nixosPackages`. |
| home-manager | nothing; selected `accel` is refused with a warning | `hardware.graphics` is a system option. A per-user backend cannot install a GPU driver, and pretending otherwise is the same inert-install failure one layer up. |

### What stays out of `accel` regardless

The condition licenses *hardware-keyed*, not *vendor-everything*. `accel` carries the VA-API driver
a media application queries. It does not carry compute SDKs, Vulkan ICDs, 32-bit gaming stacks or
vendor telemetry — those are [nixgpu][nixgpu]'s `toolchain.capabilities.*`, keyed the same way and
already built for it.

**Consequence, and it is a move rather than a copy.** `intel-media-driver` is declared **today** by
nixgpu's `toolchain.capabilities.videoAccel`. One package, one catalogue — the family rule holds
across repos, not just within one. Ratifying `accel` therefore means nixgpu's `videoAccel` intel
cell empties out and the host that enables it stops doing so, in the same change. Declaring it in
both is not a fallback position; it is the failure the rule exists to prevent.

## The catalogue

`lib/media.nix` is the single data table; `modules/nixmedia.nix` turns a selection into resolved
package lists. Each entry maps a name to a pacman package (`arch`), a nixpkgs attribute path
(`nixpkgs`), and an `aur` flag (default `false`). `accel` nests that same entry shape one level
deeper, under a vendor — the shape [nixgpu][nixgpu]'s catalogue already uses for the identical
reason.

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
| `players` | a tool you open to consume something that already exists | `vlc` |
| `plugins` | a library with no entry point that extends what an installed media application can read | `gst-plugins-base`, `gst-plugins-good`, `gst-plugins-bad`, `gst-plugins-ugly`, `gst-libav`, `gst-plugin-pipewire`, `vlc-plugins-all`, `libdvdcss` |
| `transcode` | a tool that re-encodes an artifact you already have — neither a player nor a plugin | `handbrake` |
| `accel` | the one hardware-keyed group — a VA-API driver, selected by a host-declared vendor, never autodetected | `intel`: `intel-media-driver` · `amd`, `nvidia`: none, by design — see [Hardware-keyed declarations are conditional](#hardware-keyed-declarations-are-conditional-never-class-wide) |

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

`accel` carries `intel-media-driver` in its one non-empty cell — a **move out of
[nixgpu][nixgpu]'s** `toolchain.capabilities.videoAccel`, not a duplicate; see the consequence note
in the hardware-keyed section above. `amd` and `nvidia` resolve to zero packages each, correctly:
Mesa's own `radeonsi` VA-API driver ships inside `mesa`, and NVENC/NVDEC are not exposed through
VA-API at all.

### Proposed, not yet declared

Package-to-repo assignment is the operator's call, so these are recommendations the catalogue does
not yet carry. Every Arch fact below is from `pacman -Si`/`-Qii` on a live host; every nixpkgs
attribute was force-evaluated against this flake's pinned revision.

| Proposed | Group | Why, and the failure it prevents |
|---|---|---|
| `shortwave` | `players` | Internet radio — a stream you tune into. Graphical by default, consumption-only. |
| `easytag` | `library` (new) | Audio tag editing: maintenance of a collection you already own, changing metadata and never content. Not a player, not a transcoder — the second pre-registered trigger. The group's test generalises cleanly to the obvious future additions (beets, picard). |
| `vpl-gpu-rt` | `accel`, `intel` cell — **lowest confidence of anything here** | The oneVPL runtime HandBrake's QuickSync path (`qsv_av1`) actually loads on Tiger Lake and newer. Proposed because the obvious alternative is a **trap**: HandBrake's own Arch optdep line still names `intel-media-sdk`, which is described upstream as the *legacy* API for "Broadwell to Rocket Lake" — it does not cover Xe2-class silicon at all, and its nixpkgs attribute **throws** (removed, kept only as a stub). Following the optdep would install a package that is wrong on this silicon and unbuildable on the other plane. Still the most arguable entry in this table: it is an *encode*-side runtime, and the operator may reasonably decide the class-wide repo should stop at decode. If so, this row never lands and nothing else changes. |

Deliberately **not** proposed, with reasons, so the same names do not come back:

- **`intel-media-sdk`** — see `vpl-gpu-rt` above. Legacy, wrong generation, and a throwing nixpkgs
  stub. This is the one name in the domain that looks correct because a package's own metadata
  recommends it.
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
- **Recording and authoring** — `nixrecord` (screen capture, as rendered OBS profile and scene
  files, not a package list) and `nixcreative` (editors and composition tools).
- **Streaming and remote-desktop transport** — [nixremote][nixremote] owns sunshine and moonlight.
  The boundary exists specifically so a headless box never acquires a reason to pull in a streaming
  client.
- **Compute SDKs, Vulkan ICDs, vendor telemetry, 32-bit gaming stacks** — [nixgpu][nixgpu]'s. The
  `accel` group above takes the VA-API driver *only*, under a declared vendor, and takes nothing
  else with it.
- **The audio daemon itself** — [nixaudio][nixaudio]'s. This repo carries the GStreamer-side sink
  that reaches it, and nothing else, so the whole `gst-*` namespace has exactly one owner and two
  repos can never shadow each other on it.
- **Encode policy** — presets, encoder selections and quality ladders. Host-level, for the reason
  the class-wide section gives.

## Platform support

| Backend | Behaviour |
|---|---|
| `nixosModules.default` | Installs via `environment.systemPackages`. Force-evaluates every nixpkgs attribute first (`tryEval`, not `hasAttrByPath`) so one stale mapping in a data table degrades to a skip plus a warning instead of failing the whole system evaluation. `accel` entries bypass this list entirely and go to `hardware.graphics.extraPackages` — see [the NixOS plane is an option](#the-nixos-plane-is-an-option-not-a-package-list). |
| `homeManagerModules.default` | Same resolution, installing to `home.packages` — for a per-user selection on a host whose system layer is not yours to change. A selected `accel` vendor is refused with a warning rather than installed inertly. |
| `systemManagerModules.default` | Installs nothing. Publishes `nixmedia.archPackages` and `nixmedia.aurPackages` for the host's own [nixarch][nixarch] reconciler. **We do not shadow**: on Arch a selected package comes from pacman, never a second copy from nixpkgs. |

## Usage

```nix
{
  imports = [ inputs.nixmedia.nixosModules.default ]; # or .homeManagerModules.default
                                                      # or .systemManagerModules.default

  nixmedia = {
    players = [ "vlc" ];
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
    accel = "intel"; # null (the default) | "amd" | "intel" | "nvidia" -- state the host's own silicon
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
| `modules/nixmedia.nix` | Policy: selection groups (`players`/`plugins`/`transcode`, plus the single-vendor `accel`) and the resolved `archPackages`/`aurPackages`/`nixosPackages`/`unavailableOnNixos`/`graphicsPackages` lists. |
| `modules/nixos.nix`, `modules/arch.nix`, `home/nixmedia.nix` | The three backends. |
| `checks/` | `nix flake check`-wired proof that selection and resolution are wired correctly — including that a name which left the catalogue is *rejected*, not silently accepted. Module evaluation, not a package build. |
| `experiments/` | `validate-nixpkgs-names.nix` (force-eval every catalogued nixpkgs name against a real package set) and `verify-package-names.sh` (the full Arch + AUR + nixpkgs verification, reproducible). |
| `studies/` | Findings from those experiments that changed the catalogue's shape. |

## Related projects

Part of the same independently-usable module family. The ones this repo draws a boundary against:
[nixsh][nixsh] (terminal tools — the other side of the display-default test),
[nixgpu][nixgpu] (compute SDKs, ICDs and vendor telemetry — the other side of the `accel` boundary),
[nixremote][nixremote] (streaming transport), [nixaudio][nixaudio] (the audio daemon),
[nixdesktop][nixdesktop] (desktop policy, including the file-manager preview pipeline), and
[nixarch][nixarch] (the Arch reconciler every `systemManagerModules` backend in this family
publishes into).

`nixrecord` (screen capture) and `nixcreative` (authoring) are the production side of the
artifact-existed-first test. Both are named throughout this README as the destination for anything
this repo turns away, and neither is published yet — the boundary is decided even where the repo
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
