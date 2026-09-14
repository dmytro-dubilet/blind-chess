#include "Bridge.h"
#include "engine.h"
#include "bitboard.h"
#include "misc.h"
#include <atomic>
#include <chrono>
#include <cstring>
#include <fstream>
#include <mutex>
#include <sstream>
#include <thread>

namespace {
struct Request { std::atomic<bool> cancelled{false}; };
std::mutex lock;
std::unique_ptr<Stockfish::Engine> engine;
std::once_flag initialized;
void option(const std::string &name, const std::string &value) {
    std::istringstream command("name " + name + " value " + value);
    engine->get_options().setoption(command);
}
}
void *bc_request_create() { return new Request; }
void bc_request_cancel(void *p) { static_cast<Request *>(p)->cancelled = true; }
void bc_request_destroy(void *p) { delete static_cast<Request *>(p); }
int bc_search(void *p, const char *directory, const char *fen, const char *moves,
              int elo, int skill, int milliseconds, char *result, int capacity) {
    auto &request = *static_cast<Request *>(p);
    std::lock_guard<std::mutex> guard(lock);
    result[0] = '\0';
    if (request.cancelled) return 1;
    try {
        if (!engine) {
            const std::string path(directory);
            if (!std::ifstream(path + "/nn-1c0000000000.nnue").good()
                || !std::ifstream(path + "/nn-37f18f62d772.nnue").good()) return 2;
            std::call_once(initialized, [] { Stockfish::Bitboards::init(); Stockfish::Position::init(); });
            engine = std::make_unique<Stockfish::Engine>(path + "/stockfish");
            option("Threads", "1");
            option("Hash", "32");
            engine->set_on_update_no_moves([](const auto &) {});
            engine->set_on_update_full([](const auto &) {});
            engine->set_on_iter([](const auto &) {});
            engine->set_on_verify_networks([](std::string_view) {});
        }
        if (request.cancelled) return 1;
        option("UCI_LimitStrength", elo > 0 ? "true" : "false");
        if (elo > 0) option("UCI_Elo", std::to_string(std::max(1320, std::min(3190, elo))));
        option("Skill Level", std::to_string(std::max(0, std::min(20, skill))));
        engine->search_clear();
        std::istringstream stream(moves);
        std::vector<std::string> history;
        for (std::string move; stream >> move;) history.push_back(move);
        engine->set_position(fen, history);
        std::string best;
        std::atomic<bool> done{false};
        engine->set_on_bestmove([&](std::string_view move, std::string_view) {
            best = move;
            done.store(true, std::memory_order_release);
        });
        Stockfish::Search::LimitsType limits;
        limits.startTime = Stockfish::now();
        limits.movetime = std::max(50, std::min(10000, milliseconds));
        engine->go(limits);
        while (!done.load(std::memory_order_acquire)) {
            if (request.cancelled) engine->stop();
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
        engine->wait_for_search_finished();
        engine->set_on_bestmove([](std::string_view, std::string_view) {});
        if (request.cancelled) return 1;
        if (best.empty() || best == "(none)" || best == "0000") return 2;
        std::strncpy(result, best.c_str(), capacity - 1);
        result[capacity - 1] = '\0';
        return 0;
    } catch (...) { return 2; }
}
