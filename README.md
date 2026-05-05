# fledge-plugin-codegolf

Code golf arena for fledge -- write the shortest solution to programming puzzles.

Compete against yourself (or your team) to solve classic programming challenges in the fewest bytes possible. Solutions are verified against test cases and scored by file size.

## Install

```bash
fledge plugins install corvid-agent/fledge-plugin-codegolf
```

Or from a local clone:

```bash
fledge plugins install ./codegolf
```

## Usage

```bash
# List all challenges
fledge golf list

# View a specific challenge (or omit the id for a random one)
fledge golf challenge fizzbuzz

# Verify your solution without recording a score
fledge golf verify fizzbuzz solution.py

# Submit a solution -- verifies correctness and records byte count
fledge golf submit fizzbuzz solution.py

# View the leaderboard (all challenges or a specific one)
fledge golf leaderboard
fledge golf leaderboard fizzbuzz
```

## Challenges

| ID | Name | Difficulty |
|----|------|------------|
| `reverse` | Reverse String | Easy |
| `fizzbuzz` | FizzBuzz | Easy |
| `fibonacci` | Fibonacci | Medium |
| `prime` | Prime Check | Medium |
| `caesar` | Caesar Cipher | Hard |

Each challenge lives in `challenges/<id>.toml` with test cases in `challenges/tests/<id>/`.

## Supported Languages

Solutions can be written in any language. Built-in interpreter detection covers:

- Python (`.py`)
- JavaScript (`.js`)
- Ruby (`.rb`)
- Bash (`.sh`)
- Perl (`.pl`)
- Lua (`.lua`)

Executable files with any other extension are run directly.

## Scoring

Scores are measured in bytes (file size). Only correct solutions that pass all test cases are scored. Your personal best is tracked per challenge -- submitting a longer solution won't overwrite a shorter one.

Set `FLEDGE_GOLF_PLAYER` to customize your player name (defaults to `whoami`).

## Dependencies

- **bash** >= 4.0
- **jq** -- required for leaderboard and score tracking

## Development

```bash
# Run the test suite
bash tests/run_tests.sh

# Lint with ShellCheck
shellcheck bin/codegolf
```

## License

MIT
