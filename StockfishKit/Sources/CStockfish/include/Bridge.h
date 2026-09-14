#ifndef BC_STOCKFISH_H
#define BC_STOCKFISH_H
#ifdef __cplusplus
extern "C" {
#endif
void *bc_request_create(void);
void bc_request_cancel(void *request);
void bc_request_destroy(void *request);
// 0 success, 1 cancelled, 2 error. Calls are serialized internally.
int bc_search(void *request, const char *network_directory, const char *fen, const char *moves,
              int elo, int skill, int milliseconds, char *result, int capacity);
#ifdef __cplusplus
}
#endif
#endif
