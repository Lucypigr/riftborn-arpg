# Riftborn Combat Specification — BUILD 001

This is an original ruleset for Riftborn. It does not reproduce or claim to describe another game's engine.

## Units and numeric rules

* Life, mana, barrier, armour and damage are non-negative integers. Stored values are clamped to `0..2,000,000,000`.
* Percentages use percentage points (`25` means 25%); resistance is clamped to `-50..75`, conversion to `0..100`, critical chance to `0..100`, and all non-negative multipliers to `0..1000`.
* Time is seconds in gameplay and integer milliseconds in combat snapshots. World distances are pixels. Speed is pixels/second.
* Each pipeline stage retains decimal precision. Only the final damage of each hit/tick is rounded once, half upward (`floor(x + 0.5)`), then clamped to the integer range. No successful damaging hit deals less than 1.

## Hit pipeline (strict order)

1. **Base:** collect the skill's base damage by type (`physical`, `arcane`, `fire`).
2. **Conversion:** move base damage according to the skill's source-to-target conversion map. Conversion out of any source is proportionally normalised if it exceeds 100%. Converted damage never converts again.
3. **Source bonuses:** add source global and resulting-type increased damage once: `amount × (1 + (global + type) / 100)`. This deliberately happens after conversion, preventing both original and destination type bonuses from applying.
4. **Critical:** make one deterministic RNG roll per hit. If it succeeds, multiply every type by the critical multiplier. Values below `100%` are promoted to `100%`. DoTs do not critically strike.
5. **Target taken modifiers:** multiply each type by its target type-specific damage-taken multiplier.
6. **Defence:** physical armour reduction is `armour / (armour + 100 + 10 × attacker_level)`, clamped to `0..85%`. Elemental/arcane mitigation is the target's current resistance.
7. **Apply:** sum types and round once. Barrier absorbs first; only the remainder removes life. Barrier absorption and life loss are separately emitted in the result.

## Damage over time

A DoT snapshots at application: converted base damage, source increased modifiers, attacker level, tick interval, and duration. It never snapshots target defences. It never crits. Every complete 500 ms interval produces one tick; partial intervals at expiry do not. Each tick independently runs target-taken and current defence stages, then Barrier/Life application. Refreshing creates a new snapshot rather than mutating the old one.

## Reproducible RNG

Combat uses the explicitly implemented 32-bit `xorshift32` algorithm, not an engine/global RNG. State and operations use unsigned 32-bit masking. Seed zero is replaced by hexadecimal `6D2B79F5`. A roll consumes one state and compares that unsigned integer with `floor(chance / 100 × 2^32)`. Given the same seed and hit order, results are identical across supported runtimes.
