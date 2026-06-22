# Verification Gates

Use gates to turn lab rituals into repeatable facts.

## Gate 1: Coldboot Golden

Required proof:

- golden magic is present
- ABI version is expected
- boot reason is readable
- temperature is under policy limit
- configuration status registers are readable

## Gate 2: App Slot Program

Required proof:

- target address is outside golden region
- target slot range does not overlap another slot
- flash write succeeds
- flash readback SHA-256 matches
- manifest matches readback hash

## Gate 3: Golden to App

Required proof:

- golden accepts warmboot request
- app identity appears after transport re-entry
- app heartbeat advances
- app product surfaces appear, if expected
- event log records the app-entry request

## Gate 4: App to Golden

Required proof:

- app return trigger is accepted
- golden identity returns
- app identity disappears
- boot reason or event log identifies app return

## Gate 5: A/B Good-Core

Required proof:

- slot A boots the known-good app
- slot B boots the same known-good app
- selected slot is reflected in evidence
- both slots can return to golden

## Gate 6: Bad-Slot Fallback

Required proof:

- deliberately bad slot is selected
- golden rejects or returns from it
- known-good slot remains intact
- boot reason identifies fallback

## Gate 7: Watchdog

Required proof:

- app watchdog is disabled and locked by default
- host explicitly unlocks and arms watchdog
- app petting keeps watchdog alive
- stopped petting expires watchdog
- expiry returns to golden
- final golden identity is proven

## Evidence Discipline

Every gate should record:

- UTC timestamp
- git commit or source hash
- bitstream SHA-256
- slot id and flash address
- programmed image hash
- board temperature
- boot reason
- final identity page
- pass/fail stage

