// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "StockfishKit", platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "StockfishKit", targets: ["StockfishKit"])],
    targets: [
        .target(name: "CStockfish", exclude: ["Stockfish/main.cpp", "Stockfish/Makefile"],
                publicHeadersPath: "include", cxxSettings: [.headerSearchPath("Stockfish"),
                    .define("NNUE_EMBEDDING_OFF"), .define("IS_64BIT"), .define("USE_POPCNT")]),
        .target(name: "StockfishKit", dependencies: ["CStockfish"], resources: [.copy("Networks")])
    ], cxxLanguageStandard: .cxx17)
