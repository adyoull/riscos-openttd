/* Host-test stand-in for AcornSSL: non-blocking TCP + OpenSSL, with reads and
 * writes randomly cut short to exercise the parser across boundaries. */
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <random>
extern int g_max_io;
namespace {
class SecureConnection {
public:
	~SecureConnection() { this->Close(); }
	bool Open(const std::string &host, const sockaddr *address, socklen_t address_len) {
		this->host = host;
		fd = socket(AF_INET, SOCK_STREAM, 0);
		fcntl(fd, F_SETFL, O_NONBLOCK);
		if (connect(fd, address, address_len) != 0 && errno != EINPROGRESS) { error = strerror(errno); return false; }
		ctx = SSL_CTX_new(TLS_client_method());
		SSL_CTX_load_verify_locations(ctx, "./cert.pem", nullptr);
		SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, nullptr); SSL_CTX_set_options(ctx, SSL_OP_IGNORE_UNEXPECTED_EOF);
		ssl = SSL_new(ctx); SSL_set_fd(ssl, fd);
		SSL_set_tlsext_host_name(ssl, this->host.c_str());
		SSL_set1_host(ssl, this->host.c_str());
		return true;
	}
	IoResult Handshake() {
		if (done_hs) return IoResult::Done;
		int r = SSL_connect(ssl);
		if (r == 1) { done_hs = true; return IoResult::Done; }
		int e = SSL_get_error(ssl, r);
		if (e == SSL_ERROR_WANT_READ || e == SSL_ERROR_WANT_WRITE) return IoResult::TryAgain;
		error = fmt::format("handshake failed ({})", e); return IoResult::Error;
	}
	size_t Limit(size_t n) { static std::mt19937 rng(42); size_t m = 1 + rng() % g_max_io; return std::min(n, m); }
	IoResult Write(const char *data, size_t length, size_t &done) {
		done = 0; IoResult h = Handshake(); if (h != IoResult::Done) return h;
		int r = SSL_write(ssl, data, (int)Limit(length));
		if (r > 0) { done = r; return IoResult::Done; }
		int e = SSL_get_error(ssl, r);
		if (e == SSL_ERROR_WANT_READ || e == SSL_ERROR_WANT_WRITE) return IoResult::TryAgain;
		error = "write failed"; return IoResult::Error;
	}
	IoResult Read(char *buffer, size_t length, size_t &done) {
		done = 0; IoResult h = Handshake(); if (h != IoResult::Done) return h;
		int r = SSL_read(ssl, buffer, (int)Limit(length));
		if (r > 0) { done = r; return IoResult::Done; }
		int e = SSL_get_error(ssl, r);
		if (e == SSL_ERROR_WANT_READ || e == SSL_ERROR_WANT_WRITE) return IoResult::TryAgain;
		if (e == SSL_ERROR_ZERO_RETURN || e == SSL_ERROR_SYSCALL) return IoResult::Done; /* closed */
		error = fmt::format("read failed ({})", e); return IoResult::Error;
	}
	void Close() { if (ssl) SSL_free(ssl); if (ctx) SSL_CTX_free(ctx); if (fd >= 0) ::close(fd); ssl = nullptr; ctx = nullptr; fd = -1; }
	const std::string &GetError() const { return error; }
private:
	int fd = -1; SSL_CTX *ctx = nullptr; SSL *ssl = nullptr; bool done_hs = false; std::string host, error;
};
}
