#!/usr/bin/env zsh
# ==============================================================================
# pokedex-greeting.zsh
# A terminal Pokémon greeting with sprites, type badges, stats, and weaknesses.
# Automatically switches between side-by-side and stacked layout based on width.
# ==============================================================================

# Determine directory where this plugin resides
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"
POKEDEX_PLUGIN_DIR="${0:A:h}"

# Badge color function
poke_type_badge() {
    local t="${1:l}" r g b fg=15
    case "$t" in
        normal)   r=168; g=167; b=122; fg=0 ;;
        fire)     r=238; g=129; b=48 ;;
        water)    r=99;  g=144; b=240 ;;
        electric) r=247; g=208; b=44;  fg=0 ;;
        grass)    r=122; g=199; b=76;  fg=0 ;;
        ice)      r=150; g=217; b=214; fg=0 ;;
        fighting) r=194; g=46;  b=40 ;;
        poison)   r=163; g=62;  b=161 ;;
        ground)   r=226; g=191; b=101; fg=0 ;;
        flying)   r=169; g=143; b=243; fg=0 ;;
        psychic)  r=249; g=85;  b=135 ;;
        bug)      r=166; g=185; b=26;  fg=0 ;;
        rock)     r=182; g=161; b=54;  fg=0 ;;
        ghost)    r=115; g=87;  b=151 ;;
        dragon)   r=111; g=53;  b=252 ;;
        dark)     r=112; g=87;  b=70 ;;
        steel)    r=183; g=183; b=206; fg=0 ;;
        fairy)    r=214; g=133; b=173; fg=0 ;;
        *)        r=100; g=100; b=100 ;;
    esac
    printf '\e[38;5;%sm\e[48;2;%d;%d;%dm %s \e[0m' "$fg" "$r" "$g" "$b" "${(C)t}"
}

# Pokémon Type Chart for Weakness calculation
typeset -gA _POKE_SUPER_EFF _POKE_RESIST _POKE_IMMUNE
_POKE_SUPER_EFF[Normal]=""
_POKE_SUPER_EFF[Fire]="Grass Ice Bug Steel"
_POKE_SUPER_EFF[Water]="Fire Ground Rock"
_POKE_SUPER_EFF[Electric]="Water Flying"
_POKE_SUPER_EFF[Grass]="Water Ground Rock"
_POKE_SUPER_EFF[Ice]="Grass Ground Flying Dragon"
_POKE_SUPER_EFF[Fighting]="Normal Ice Rock Dark Steel"
_POKE_SUPER_EFF[Poison]="Grass Fairy"
_POKE_SUPER_EFF[Ground]="Fire Electric Poison Rock Steel"
_POKE_SUPER_EFF[Flying]="Grass Fighting Bug"
_POKE_SUPER_EFF[Psychic]="Fighting Poison"
_POKE_SUPER_EFF[Bug]="Grass Psychic Dark"
_POKE_SUPER_EFF[Rock]="Fire Ice Flying Bug"
_POKE_SUPER_EFF[Ghost]="Psychic Ghost"
_POKE_SUPER_EFF[Dragon]="Dragon"
_POKE_SUPER_EFF[Steel]="Ice Rock Fairy"
_POKE_SUPER_EFF[Dark]="Psychic Ghost"
_POKE_SUPER_EFF[Fairy]="Fighting Dragon Dark"

_POKE_RESIST[Normal]="Rock Steel"
_POKE_RESIST[Fire]="Fire Water Rock Dragon"
_POKE_RESIST[Water]="Water Grass Dragon"
_POKE_RESIST[Electric]="Electric Grass Dragon"
_POKE_RESIST[Grass]="Fire Grass Poison Flying Bug Dragon Steel"
_POKE_RESIST[Ice]="Fire Water Ice Steel"
_POKE_RESIST[Fighting]="Poison Flying Psychic Bug Fairy"
_POKE_RESIST[Poison]="Poison Ground Rock Ghost"
_POKE_RESIST[Ground]="Grass Bug"
_POKE_RESIST[Flying]="Electric Rock Steel"
_POKE_RESIST[Psychic]="Psychic Steel"
_POKE_RESIST[Bug]="Fire Fighting Poison Flying Ghost Steel Fairy"
_POKE_RESIST[Rock]="Fighting Ground Steel"
_POKE_RESIST[Ghost]="Dark"
_POKE_RESIST[Dragon]="Steel"
_POKE_RESIST[Steel]="Fire Water Electric Steel"
_POKE_RESIST[Dark]="Fighting Dark Fairy"
_POKE_RESIST[Fairy]="Fire Poison Steel"

_POKE_IMMUNE[Normal]="Ghost"
_POKE_IMMUNE[Fighting]="Ghost"
_POKE_IMMUNE[Poison]="Steel"
_POKE_IMMUNE[Ground]="Flying"
_POKE_IMMUNE[Ghost]="Normal"
_POKE_IMMUNE[Electric]="Ground"
_POKE_IMMUNE[Psychic]="Dark"
_POKE_IMMUNE[Dragon]="Fairy"

poke_get_weaknesses() {
    local def_types=($@)
    local all_types=(Normal Fire Water Electric Grass Ice Fighting Poison Ground Flying Psychic Bug Rock Ghost Dragon Steel Dark Fairy)
    local atk def weaknesses=()

    for atk in "${all_types[@]}"; do
        local mult=100
        for def in "${def_types[@]}"; do
            def="${(C)def}"
            if [[ " ${_POKE_IMMUNE[$atk]} " == *" $def "* ]]; then
                mult=0; break
            fi
            [[ " ${_POKE_SUPER_EFF[$atk]} " == *" $def "* ]] && mult=$(( mult * 2 ))
            [[ " ${_POKE_RESIST[$atk]} " == *" $def "* ]] && mult=$(( mult / 2 ))
        done
        (( mult > 100 )) && weaknesses+=("$atk")
    done
    echo "${weaknesses[@]}"
}

# Ensure dependencies (jq and pokeget) are installed
_pokedex_ensure_deps() {
    if ! command -v pokeget >/dev/null && [[ -x "$HOME/.cargo/bin/pokeget" ]]; then
        path+=("$HOME/.cargo/bin")
        typeset -U PATH path
    fi

    local missing=()
    command -v jq >/dev/null || missing+=(jq)
    command -v pokeget >/dev/null || missing+=(pokeget)

    if (( ${#missing[@]} > 0 )); then
        print "\e[1;33m[pokedex-greeting.zsh]\e[0m Missing dependencies: \e[1;37m${(j:, :)missing}\e[0m"
        return 1
    fi
    return 0
}

pokedex_greeting() {
    [[ -t 1 ]] || return
    _pokedex_ensure_deps || return

    local term_width="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
    (( term_width < 40 )) && return # Skip if terminal is extremely narrow

    local pokedex_file="${POKEDEX_JSON_PATH:-$POKEDEX_PLUGIN_DIR/pokedex.json}"
    [[ -s "$pokedex_file" ]] || return

    local count
    count=$(jq 'length' "$pokedex_file" 2>/dev/null) || return
    (( count > 0 )) || return

    local idx=$((RANDOM % count))
    local entry
    entry=$(jq -c ".[$idx]" "$pokedex_file" 2>/dev/null) || return

    local id name species types_raw height weight hp atk def spatk spdef spd desc
    id=$(print -r -- "$entry" | jq -r '.id')
    name=$(print -r -- "$entry" | jq -r '.name.english')
    species=$(print -r -- "$entry" | jq -r '.species // "Pokémon"')
    types_raw=$(print -r -- "$entry" | jq -r '.type | join(" ")')
    height=$(print -r -- "$entry" | jq -r '.profile.height // "???"')
    weight=$(print -r -- "$entry" | jq -r '.profile.weight // "???"')
    hp=$(print -r -- "$entry" | jq -r '.base.HP // "—"')
    atk=$(print -r -- "$entry" | jq -r '.base.Attack // "—"')
    def=$(print -r -- "$entry" | jq -r '.base.Defense // "—"')
    spatk=$(print -r -- "$entry" | jq -r '.base["Sp. Attack"] // "—"')
    spdef=$(print -r -- "$entry" | jq -r '.base["Sp. Defense"] // "—"')
    spd=$(print -r -- "$entry" | jq -r '.base.Speed // "—"')
    desc=$(print -r -- "$entry" | jq -r '.description // ""')

    local badges=""
    for t in ${(s: :)types_raw}; do
        [[ -n $badges ]] && badges="$badges "
        badges="$badges$(poke_type_badge "$t")"
    done

    local weak_types_raw weak_badges=""
    weak_types_raw=$(poke_get_weaknesses ${(s: :)types_raw})
    for t in ${(s: :)weak_types_raw}; do
        [[ -n $weak_badges ]] && weak_badges="$weak_badges "
        weak_badges="$weak_badges$(poke_type_badge "$t")"
    done
    [[ -z $weak_badges ]] && weak_badges=$'\e[2mNone\e[0m'

    local sprite_lines=("${(@f)$(pokeget "$id" --hide-name 2>/dev/null)}")

    # Calculate max width of sprite
    local max_w=0
    for s in "${sprite_lines[@]}"; do
        local clean=$(print -rn -- "$s" | sed $'s/\x1b\\[[0-9;]*m//g')
        local len=${#clean}
        (( len > max_w )) && max_w=$len
    done

    # Determine layout mode: Side-by-side requires enough space for sprite + gap + ~50 chars of text
    local min_side_by_side_width=$(( max_w + 55 ))
    local use_side_by_side=0
    (( term_width >= min_side_by_side_width )) && use_side_by_side=1

    # Set description text wrapping width based on active layout
    local desc_width
    if (( use_side_by_side )); then
        desc_width=48
    else
        desc_width=$(( term_width - 4 ))
        (( desc_width > 70 )) && desc_width=70
    fi

    local info_lines=(
        $'\e[1;37m#'"$(printf '%03d' "$id") ${name}"$'\e[0m \e[2m('"Species: ${species}"$')\e[0m'
        $'\e[1;33mType:\e[0m '"${badges}"
        $'\e[1;31mWeak:\e[0m '"${weak_badges}"
        $'\e[2m─────────────────────────────────────────────────\e[0m'
        $'\e[1;34mHT:\e[0m '"${height}"$'    \e[1;34mWT:\e[0m '"${weight}"
        $'\e[1;31mHP\e[0m '"${hp}"$'  \e[1;33mATK\e[0m '"${atk}"$'  \e[1;34mDEF\e[0m '"${def}"$'  \e[1;35mSP.A\e[0m '"${spatk}"$'  \e[1;36mSP.D\e[0m '"${spdef}"$'  \e[1;32mSPD\e[0m '"${spd}"
        $'\e[2m─────────────────────────────────────────────────\e[0m'
    )

    while [[ -n $desc ]]; do
        if [[ ${#desc} -le $desc_width ]]; then
            info_lines+=($'\e[3m'"${desc}"$'\e[0m')
            desc=""
        else
            local chunk="${desc[1,$desc_width]}"
            local last_space="${chunk[(r) ]}"
            local split_idx=$desc_width
            [[ -n $last_space ]] && split_idx=${chunk[(I) ]}
            info_lines+=($'\e[3m'"${desc[1,$split_idx-1]}"$'\e[0m')
            desc="${desc[$split_idx+1,-1]}"
        fi
    done

    print
    if (( use_side_by_side )); then
        # Side-by-side Layout
        local total_lines=$(( ${#sprite_lines[@]} > ${#info_lines[@]} ? ${#sprite_lines[@]} : ${#info_lines[@]} ))
        for ((i=1; i<=total_lines; i++)); do
            local s="${sprite_lines[i]:-}"
            local inf="${info_lines[i]:-}"
            local clean_s=$(print -rn -- "$s" | sed $'s/\x1b\\[[0-9;]*m//g')
            local pad=$(( max_w - ${#clean_s} + 4 ))
            local pad_spaces=$(printf '%*s' "$pad" "")
            print -r -- "${s}${pad_spaces}${inf}"
        done
    else
        # Stacked Layout (Image on top, text below)
        for s in "${sprite_lines[@]}"; do
            print -r -- "  ${s}"
        done
        print
        for inf in "${info_lines[@]}"; do
            print -r -- "  ${inf}"
        done
    fi
    print
}

# # Auto-run when sourced in interactive terminal
# if [[ $- == *i* && -t 1 ]]; then
#     pokedex_greeting
# fi
