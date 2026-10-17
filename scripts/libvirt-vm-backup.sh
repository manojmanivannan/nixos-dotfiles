#!/usr/bin/env bash
# libvirt VM full backup / restore to an external USB disk.
#
# Backs up:  the qcow2 disk image + UEFI NVRAM vars + `virsh dumpxml` into
#              <dest>/<vm>_backup_<YYYYMMDD_HHMMSS>/
# Restores:  copies those back, rewrites the host-specific paths (emulator,
#            OVMF loader, nvram, disk) to this host's real locations, and
#            re-defines the VM.
#
# Usage: run the script, follow the prompts. Needs sudo at define/copy time
# (and to shut down/undefine the VM); sudo will prompt once.
#
# Notes:
#   - exFAT/fat backup destinations cannot store sparse files, so a 74G
#     qcow2 occupies its full ~79G there. Free space is checked first.
#   - When restoring, any USB device passthroughs in the XML are offered
#     for removal (they block the VM from starting on a machine without
#     that exact device).

set -euo pipefail

EMULATOR="/run/libvirt/nix-emulators/qemu-system-x86_64"
OVMF_LOADER="/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd"
NVRAM_DIR="/var/lib/libvirt/qemu/nvram"
IMAGES_DIR="/var/lib/libvirt/images"
DEFAULT_VM="win11"

# ---------------------------------------------------------------- helpers

die()  { printf '\e[31;1m✗ %s\e[0m\n' "$*" >&2; exit 1; }
info() { printf '\e[32;1m✓ %s\e[0m\n' "$1"; }
warn() { printf '\e[33;1m! %s\e[0m\n' "$1"; }
hdr()  { printf '\n\e[1;36m== %s\e[0m\n' "$1"; }

# sudo passthrough using cached credentials when they exist
as_root() {
    if sudo -n true 2>/dev/null; then sudo -n "$@"; else sudo "$@"; fi
}

human() { numfmt --to=iec --suffix=B "$1" 2>/dev/null || printf '%s bytes' "$1"; }

# ask [prompt] [default] -> echoes y or n
ask() {
    local reply
    read -r -p "$(printf '%s %s: ' "$1" "[${2:-y}/n]")" reply
    reply="${reply:-${2:-y}}"
    [[ "$reply" =~ ^[Yy] ]] && echo y || echo n
}

vm_state() { virsh domstate "$1" 2>/dev/null; }

disk_image_of() {
    # first file-backed disk source of a VM via domblklist (robust, no grep golf)
    virsh domblklist "$1" --details 2>/dev/null | awk '$1 == "file" && $2 == "disk" {print $4; exit}'
}

nvram_path_of() {
    virsh dumpxml "$1" 2>/dev/null | grep -oPm1 '<nvram[^>]*>\K[^<]+' || true
}

check_deps() {
    local cmd missing=()
    for cmd in virsh rsync numfmt perl; do
        command -v "$cmd" >/dev/null || missing+=("$cmd")
    done
    if ((${#missing[@]} > 0)); then
        die "missing commands: ${missing[*]}"
    fi
    virsh uri >/dev/null 2>&1 || die "cannot reach libvirt (is libvirtd running?)"
}

# pick_vm -> echoes the chosen VM name (menus go to stderr)
pick_vm() {
    local -a vms
    local vm
    mapfile -t vms < <(virsh list --all --name | grep -v '^$' || true)
    ((${#vms[@]})) || die "no libvirt VMs defined"
    printf 'Defined VMs:\n' >&2
    local i=1; for v in "${vms[@]}"; do printf '  %d) %s\n' "$i" "$v" >&2; i=$((i+1)); done
    read -r -p "VM [$DEFAULT_VM]: " vm >&2
    vm="${vm:-$DEFAULT_VM}"
    virsh dominfo "$vm" >/dev/null 2>&1 || die "VM '$vm' not found"
    echo "$vm"
}

# pick_mount -> echoes the chosen mount point under /run/media/$USER
pick_mount() {
    local -a mounts=()
    # findmnt escapes whitespace etc. as \xNN in the TARGET column (e.g.
    # "Seagate\x20HDD") — decode so df/rsync get a real path
    mapfile -t mounts < <(findmnt -rn -o TARGET -t exfat,vfat,ntfs,ntfs3,btrfs,ext4 2>/dev/null \
        | grep -E "^/run/media/${USER:-manoj}/" \
        | perl -pe 's{\\x([0-9a-fA-F]{2})}{chr(hex($1))}ge' || true)
    ((${#mounts[@]})) || die "no external drive mounted under /run/media/${USER:-manoj} — mount it first"
    printf 'Available destinations:\n' >&2
    local i=1 m f t
    for m in "${mounts[@]}"; do
        f=$(df -B1 --output=avail "$m" | tail -1)
        t=$(df -B1 --output=size  "$m" | tail -1)
        printf '  %d) %s  (%s free of %s, %s)\n' "$i" "$m" "$(human "$f")" "$(human "$t")" \
            "$(findmnt -no FSTYPE -T "$m")" >&2
        i=$((i+1))
    done
    local choice
    read -r -p "Number: " choice >&2
    local picked="${mounts[$((choice-1))]:-}"
    [[ -n "$picked" ]] || die "invalid choice: $choice"
    echo "$picked"
}

need_space() {   # need_space <dest> <apparent_bytes_needed>
    local avail
    avail=$(df -B1 --output=avail "$1" | tail -1)
    ((avail >= $2)) || die "only $(human "$avail") free on $1, need ~$(human "$2")"
}

# shut_down_if_running <vm> — offers graceful shutdown before a backup
shut_down_if_running() {
    if [[ "$(vm_state "$1")" != "running" ]]; then return 0; fi
    hdr "VM '$1' is running"
    echo "Copying the qcow2 of a running VM can capture inconsistent writes (the"
    echo "image may not boot). Safer to shut it down."
    local c
    read -r -p "[S]hut down (default), back [u]p anyway, or [a]bort? " c
    c="${c:-s}"
    case "$c" in
        [Ss])
            echo "Graceful shutdown (waits up to 120s)…"
            virsh shutdown "$1" || true
            for i in $(seq 1 60); do
                if [[ "$(vm_state "$1")" == "shut off" ]]; then break; fi
                sleep 2
            done
            if [[ "$(vm_state "$1")" != "shut off" ]]; then
                if [[ "$(ask "Did not shut off in 120s — force it? (unsaved work is lost)" n)" == y ]]; then
                    virsh destroy "$1"
                fi
            fi
            [[ "$(vm_state "$1")" == "shut off" ]] || die "VM still running — aborting"
            info "VM is off"
            ;;
        [Uu]) warn "proceeding on a running VM — image may be inconsistent" ;;
        *)    die "aborted" ;;
    esac
}

# ----------------------------------------------------------------- backup

do_backup() {
    hdr "Backup"
    local vm ts dest backup_dir img vars need

    vm=$(pick_vm)
    img=$(disk_image_of "$vm")
    [[ -n "$img" ]] || die "VM '$vm' has no file-backed disk"
    vars=$(nvram_path_of "$vm")

    printf 'VM:            %s  (%s)\n' "$vm" "$(vm_state "$vm")"
    printf 'Disk image:    %s\n' "$img"
    printf 'Image size:    ~%s (on-disk)\n' "$(human "$(du -B1 "$img" | cut -f1)")"
    printf 'NVRAM vars:    %s\n' "${vars:-<none — BIOS VM>}"

    dest=$(pick_mount)
    ts=$(date +%Y%m%d_%H%M%S)
    backup_dir="${dest}/${vm}_backup_${ts}"

    # apparent size + 2G headroom for the vars/xml/rounding
    need=$(($(stat -c '%s' "$img") + 2147483648))
    if [[ -n "$vars" && -f "$vars" ]]; then
        need=$((need + $(stat -c '%s' "$vars")))
    fi
    need_space "$dest" "$need"

    printf 'Backup to:     %s\n' "$backup_dir"
    [[ "$(ask "Start backup?" y)" == y ]] || die "aborted"

    shut_down_if_running "$vm"

    as_root mkdir -p "$backup_dir"
    printf '\nCopying disk image…\n'
    as_root rsync --info=progress2 --inplace -S --modify-window=2 --no-owner --no-group --no-perms \
        "$img" "$backup_dir/$(basename "$img")" \
        || die "copy to $dest failed (exit $?)"
    printf '\n'
    info "disk image copied"

    if [[ -n "$vars" && -f "$vars" ]]; then
        as_root cp "$vars" "$backup_dir/$(basename "$vars")"
        info "NVRAM vars copied"
    fi
    # backup_dir is root-owned (created via sudo), so write the XML as root too
    virsh dumpxml "$vm" | as_root tee "$backup_dir/${vm}.xml" >/dev/null
    info "domain XML written"

    hdr "Verify"
    if command -v qemu-img >/dev/null; then
        echo "Running qemu-img check on the copy (reads the whole image, a few minutes)…"
        if qemu-img check "$backup_dir/$(basename "$img")" > /dev/null 2>&1; then
            info "image copy is consistent"
        else
            warn "qemu-img check reported problems — run 'qemu-img check $backup_dir/$(basename "$img")' for detail"
        fi
    else
        warn "qemu-img not found — skipping verification"
    fi

    info "Done. Backup at: $backup_dir"
}

# ---------------------------------------------------------------- restore

do_restore() {
    hdr "Restore"
    local dest src vm xml qcow2 vars default_vm need tmp_xml

    dest=$(pick_mount)

    local -a backups=()
    mapfile -t backups < <(find "$dest" -maxdepth 1 -type d -name '*_backup_*' 2>/dev/null | sort)
    ((${#backups[@]})) || die "no *_backup_* directories on $dest"
    printf 'Backups on %s:\n' "$dest" >&2
    local i=1 b
    for b in "${backups[@]}"; do printf '  %d) %s\n' "$i" "$b" >&2; i=$((i+1)); done
    local choice
    read -r -p "Number: " choice >&2
    src="${backups[$((choice-1))]:-}"
    [[ -n "$src" ]] || die "invalid choice: $choice"

    qcow2=$(ls "$src"/*.qcow2 2>/dev/null | head -1)
    xml=$(ls   "$src"/*.xml  2>/dev/null | head -1)
    [[ -n "$qcow2" && -n "$xml" ]] || die "'$src' is not a complete backup (need *.qcow2 and *.xml)"
    vars=$(ls "$src"/*VARS*.fd 2>/dev/null | head -1)

    default_vm="$(basename "$src" | sed 's/_backup_[0-9_]*$//')"
    printf '\nBackup:        %s\n' "$src"
    printf 'Image:         %s (%s)\n' "$qcow2" "$(human "$(wc -c < "$qcow2")")"
    printf 'NVRAM vars:    %s\n' "${vars:-<none — BIOS VM>}"
    read -r -p "Restore as VM name [$default_vm]: " vm >&2 || true
    vm="${vm:-$default_vm}"
    printf '\n'
    [[ "$(ask "Copy $(human "$(wc -c < "$qcow2")") to $IMAGES_DIR/${vm}.qcow2 and define '$vm'?" y)" == y ]] \
        || die "aborted"

    if virsh dominfo "$vm" >/dev/null 2>&1; then
        warn "a VM named '$vm' already exists"
        [[ "$(ask "Undefine it, delete its NVRAM and old disk, then restore over it?" n)" == y ]] \
            || die "aborted"
        as_root virsh undefine --nvram "$vm" 2>/dev/null || as_root virsh undefine "$vm"
        as_root rm -f "$IMAGES_DIR/${vm}.qcow2"
    fi

    need_space / "$(wc -c < "$qcow2")"

    # ---- XML rewrite: point emulator/loader/nvram/disk to THIS host --------
    tmp_xml="/tmp/${vm}-restore.xml"
    perl -0777 - "$xml" "$tmp_xml" "$EMULATOR" "$OVMF_LOADER" "$NVRAM_DIR" "$IMAGES_DIR" "$vm" <<'PERL'
my ($in, $out, $emulator, $loader, $nvram_dir, $images_dir, $vm) = @ARGV;
open my $fh, '<', $in or die "cannot read $in: $!";
$/ = undef; my $s = <$fh>; close $fh;

my $is_efi = ($s =~ /<os[^>]*firmware=['"]efi['"]/ || $s =~ /<loader/);

$s =~ s{<emulator>.*?</emulator>}{<emulator>$emulator</emulator>}s;
$s =~ s{<source file=['"][^'"]*\.qcow2['"]\s*/>}{<source file="$images_dir/${vm}.qcow2"/>};

if ($is_efi) {
    $s =~ s{<loader[^>]*>.*?</loader>|<loader[^>]*/>}
          {<loader readonly="yes" secure="yes" type="pflash" format="raw">$loader</loader>}s;
    $s =~ s{<nvram[^>]*>.*?</nvram>|<nvram[^>]*/>}
          {<nvram format="raw">${nvram_dir}/${vm}_VARS.fd</nvram>}s;
} else {
    # BIOS VM — strip any pflash bits that should not be there
    $s =~ s{<loader.*?(?:</loader>|/>)}{}s;
    $s =~ s{<nvram.*?(?:</nvram>|/>)}{}s;
}

open my $w, '>', $out or die "cannot write $out: $!";
print $w $s; close $w;
PERL
    info "XML rewritten (emulator, loader, nvram, disk path -> this host)"

    # ---- actually move the data --------------------------------------------
    if [[ "$(ask "Also strip USB device passthroughs from the XML? (they block the VM starting without that very device plugged in)" y)" == y ]]; then
        perl -0777 -i - "$tmp_xml" <<'PERL'
my $f = $ARGV[0];
open my $fh, '<', $f or die "cannot read $f: $!"; my $s = <$fh>; close $fh;
$s =~ s{\n\s*<hostdev\b.*?</hostdev>}{}gs;
open my $w, '>', $f or die "cannot write $f: $!"; print $w $s; close $w;
PERL
        info "USB passthroughs removed from $tmp_xml"
    fi

    printf '\nCopying disk image to %s…\n' "$IMAGES_DIR"
    as_root rsync --info=progress2 --inplace -S "$qcow2" "$IMAGES_DIR/${vm}.qcow2" \
        || die "copy from $src failed"
    printf '\n'
    info "disk image copied"
    if [[ -n "$vars" ]]; then
        as_root cp "$vars" "$NVRAM_DIR/${vm}_VARS.fd"
        info "NVRAM vars copied"
    fi

    hdr "Define"
    as_root virsh define "$tmp_xml" || die "virsh define failed — fix $tmp_xml and run 'virsh define $tmp_xml'"
    rm -f "$tmp_xml"
    info "VM '$vm' defined"

    if command -v qemu-img >/dev/null; then
        echo "Running qemu-img check on the restored image…"
        if qemu-img check "$IMAGES_DIR/${vm}.qcow2" >/dev/null 2>&1; then
            info "restored image is consistent"
        else
            warn "qemu-img check flagged problems"
        fi
    fi

    if [[ "$(ask "Start '$vm' and open virt-manager now?" y)" == y ]]; then
        virsh start "$vm"
        (setsid virt-manager >/dev/null 2>&1 &) || true
        info "virt-manager launched — double-click '$vm' to watch it boot"
    fi
}

# ------------------------------------------------------------------- main

check_deps
printf '\e[1mlibvirt VM backup / restore\e[0m\n'
printf '  images:     %s\n  nvram:      %s\n  firmware:   %s\n' "$IMAGES_DIR" "$NVRAM_DIR" "$OVMF_LOADER"

PS3=$'\nAction: '
select action in Backup Restore Quit; do
    case "$action" in
        Backup)  do_backup  ;;
        Restore) do_restore ;;
        Quit)    exit 0      ;;
        *)       printf 'Pick 1–3\n'; continue ;;
    esac
    break
done