# Blind Chess: Voice Trainer

An iOS chess app for practicing blindfold play using on-device speech recognition.

## Build

Open BlindChess.xcodeproj in Xcode 26.2 or later. Resolve the pinned Swift packages, select the BlindChess scheme and an iOS simulator or device, and build. For device distribution, select your own signing team and provisioning configuration. Minimum iOS version: 17.

Stockfish 17.1 sources, bridge, NNUE networks and build configuration are included in StockfishKit. The Xcode project pins WhisperKit 1.1.0; the resolved package revision is retained in the project workspace. Voice recognition downloads its model on first use. No credentials are required to build the app for the simulator.

This source snapshot corresponds to version 1.1 (53). It is not a statement that Apple has approved or published the app. Private development logs and regression recordings are not included.

Interface, spoken moves and voice commands support English, Spanish, French, German, Italian, Portuguese (Brazilian voice), Polish, Russian and Ukrainian. The same multilingual Whisper model is used for every language.

Board move, capture, check and checkmate sounds are original generated assets; regenerate them with `python3 Scripts/generate_board_sounds.py`.

## Licensing

Original app source: GPL-3.0-or-later (LICENSE.md and COPYING).
Stockfish: GPL-3.0-or-later; attribution and exact upstream revision in StockfishKit/NOTICE.md.
Cburnett pieces: Colin M.L. Burnett, GPL-2.0-or-later; original SVGs and pinned attribution in Artwork/Cburnett.
Other dependencies retain their respective licenses. WhisperKit: https://github.com/argmaxinc/argmax-oss-swift (MIT).

## Support

large.coat.of.arms@gmail.com
