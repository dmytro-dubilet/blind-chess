# Stockfish 17.1

Official upstream: https://github.com/official-stockfish/Stockfish
Release tag: sf_17.1
Commit: 03e27488f3d21d8ff4dbf3065603afa21dbd0ef3
License: GPL-3.0-or-later; see COPYING and AUTHORS.

The complete upstream src directory is retained in Sources/CStockfish/Stockfish,
unchanged. Its standalone main.cpp is excluded from the library build. Bridge.cpp,
Bridge.h, Stockfish.swift and Package.swift are the application integration added
on 2026-09-12. Build with SwiftPM / Xcode using C++17, IS_64BIT, USE_POPCNT and
NNUE_EMBEDDING_OFF. No external engine process is launched on iOS.

Networks from https://github.com/official-stockfish/networks (included offline):
- nn-1c0000000000.nnue: SHA-256 1c0000000000a67d629999d932d0c373f7450ce43cd12d0562868f4eaf9ae2ad
- nn-37f18f62d772.nnue: SHA-256 37f18f62d772f3107e1d6aaca3898c130c3c86f2ab63e6555fbbca20635a899d

The Stockfish source and these integration files are provided under GPL-3.0-or-later.
Distribution of a combined application must comply with the applicable GPL terms,
including corresponding source. Cburnett piece artwork is separately attributed in ../Artwork/Cburnett/SOURCE.txt.
