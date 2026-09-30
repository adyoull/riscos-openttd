#include "src/stdafx.h"
#include "src/network/core/http.h"
#include <thread>
#include <chrono>
#include <cstdio>
int _debug_net_level = 3;
int g_max_io = 7;
void DebugPrint(const char *cat, int level, const std::string &msg) { fprintf(stderr, "[%s:%d] %s\n", cat, level, msg.c_str()); }
std::string_view GetNetworkRevisionString() { return "14.1"; }
struct Cb : HTTPCallback {
	std::string body; bool done = false, failed = false; bool cancel = false;
	void OnFailure() override { failed = true; }
	void OnReceiveData(std::unique_ptr<char[]> d, size_t n) override { if (!d) done = true; else body.append(d.get(), n); if (cancel_after && body.size() > cancel_after) cancel = true; }
	bool IsCancelled() const override { return cancel; }
	size_t cancel_after = 0;
};
static int run(const char *name, const std::string &uri, const std::string &post, bool expect_ok, const std::string &expect_body, size_t cancel_after = 0) {
	Cb cb; cb.cancel_after = cancel_after;
	NetworkHTTPSocketHandler::Connect(uri, &cb, post);
	auto t0 = std::chrono::steady_clock::now();
	while (!cb.done && !cb.failed && std::chrono::steady_clock::now() - t0 < std::chrono::seconds(60)) {
		NetworkHTTPSocketHandler::HTTPReceive();
		std::this_thread::sleep_for(std::chrono::milliseconds(5));
	}
	bool ok = expect_ok ? (cb.done && !cb.failed && (expect_body.empty() || cb.body == expect_body)) : (cb.failed && !cb.done);
	printf("%-28s %s (done=%d failed=%d bytes=%zu)\n", name, ok ? "PASS" : "FAIL", cb.done, cb.failed, cb.body.size());
	return ok ? 0 : 1;
}
int main(int argc, char **argv) {
	if (argc > 1) g_max_io = atoi(argv[1]);
	std::string big; { FILE *f = fopen("./big.bin", "rb"); char b[65536]; size_t n; while ((n = fread(b,1,sizeof b,f))) big.append(b,n); fclose(f); }
	NetworkHTTPInitialize();
	const std::string B = "https://localhost:8443";
	int fails = 0;
	fails += run("content-length", B + "/plain", "", true, "hello world\n");
	fails += run("chunked", B + "/chunked", "", true, "chunk-one;chunk-two;last");
	fails += run("close-delimited", B + "/close", "", true, "until close\n");
	fails += run("redirect abs+rel (302)", B + "/redirect", "", true, "hello world\n");
	fails += run("post json", B + "/echo", "{\"a\":1}", true, "POST application/json 7 {\"a\":1}");
	fails += run("post form", B + "/echo", "a=1&b=2", true, "POST application/x-www-form-urlencoded 7 a=1&b=2");
	fails += run("303 post->get", B + "/see-other", "x=1", true, "GET  0 ");
	fails += run("307 keeps post", B + "/temp-redirect", "x=1", true, "POST application/x-www-form-urlencoded 3 x=1");
	fails += run("404 fails", B + "/missing", "", false, "");
	fails += run("429 fails", B + "/busy", "", false, "");
	fails += run("redirect loop fails", B + "/loop", "", false, "");
	fails += run("100-continue skipped", B + "/continue", "", true, "after continue\n");
	fails += run("big chunked 3MB", B + "/big-chunked", "", true, big);
	fails += run("big length 3MB", B + "/big", "", true, big);
	fails += run("truncated body fails", B + "/truncated", "", false, "");
	fails += run("http:// refused", "http://localhost:8443/plain", "", false, "");
	fails += run("bad host fails", "https://no-such-host.invalid/", "", false, "");
	fails += run("wrong cert name fails", "https://127.0.0.1:8443/plain", "", false, "");
	if (g_max_io <= 64) fails += run("cancel mid-transfer", B + "/big", "", false, "", 200000);
	NetworkHTTPUninitialize();
	printf("%d failure(s)\n", fails);
	return fails;
}
