# pokedex-greeting.zsh

A stylish terminal Pokémon greeting for Zsh featuring sprites, colored type badges, base stats, description, and dynamic weakness calculation.

```text
           ▄▄▄▄▄        #001 Bulbasaur (Species: Seed Pokémon)
        ▄▄▄▄▄▄▄▄▄▄      Type:  Grass   Poison 
   ▄  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄    Weak:  Fire   Ice   Flying   Psychic 
  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄    ─────────────────────────────────────────────────
 ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▀    HT: 0.7 m    WT: 6.9 kg
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄      HP 45  ATK 49  DEF 49  SP.A 65  SP.D 65  SPD 45
▀▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄     ─────────────────────────────────────────────────
 ▀▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▀     Bulbasaur can be seen napping in bright
    ▀▀▀▀▀▄▄▄▄▄▄▀▀       sunlight. There is a seed on its back. By
          ▀▀▀▀          soaking up the sun’s rays, the seed grows
                        progressively larger.
```

## Dependencies

This plugin requires two command-line tools:

1. **[pokeget](https://github.com/talwat/pokeget-rs)** (for terminal Pokémon sprites):
   ```bash
   cargo install pokeget
   ```
2. **[jq](https://jqlang.github.io/jq/)** (for parsing the offline Pokédex dataset):
   ```bash
   brew install jq       # macOS
   sudo apt install jq   # Ubuntu / Debian
   ```

If either dependency is missing when your shell opens, the plugin prints a friendly prompt with instructions and repository links.



## Installation

### With [Zinit](https://github.com/zdharma-continuum/zinit)

Add to your `~/.zshrc`:

```zsh
zinit light yourusername/pokedex-greeting.zsh
```

Or for testing locally from this folder:

```zsh
zinit ice
zinit load ~/pokedex-greeting.zsh
```

### With Oh My Zsh

Clone into your custom plugins directory:

```bash
git clone https://github.com/yourusername/pokedex-greeting.zsh.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/pokedex-greeting
```

Add `pokedex-greeting` to your plugin list in `~/.zshrc`:

```zsh
plugins=(... pokedex-greeting)
```

## Features

- **Side-by-side terminal layout** (sprite on the left, info aligned on the right)
- **Official color palette badges** for all 18 Pokémon types
- **Automatic dual/single-type weakness calculator** (accounts for resistances, 4x weaknesses, and immunities)
- **Zero latency**: Completely offline database bundled directly in the repository
