import socket, ssl, threading, random
BIG = open('./big.bin','rb').read()
ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
ctx.load_cert_chain('./cert.pem', './key.pem')
def resp(status, body=b'', extra=b''):
    return b'HTTP/1.1 ' + status + b'\r\n' + extra + b'Content-Length: ' + str(len(body)).encode() + b'\r\n\r\n' + body
def handle(c):
    try:
        data = b''
        while b'\r\n\r\n' not in data:
            d = c.recv(4096)
            if not d: return
            data += d
        head, rest = data.split(b'\r\n\r\n', 1)
        lines = head.decode().split('\r\n')
        method, path, _ = lines[0].split(' ')
        hdr = {k.lower(): v for k, v in (l.split(': ', 1) for l in lines[1:])}
        n = int(hdr.get('content-length', '0'))
        while len(rest) < n: rest += c.recv(4096)
        if path == '/plain': c.sendall(resp(b'200 OK', b'hello world\n'))
        elif path == '/chunked':
            c.sendall(b'HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n')
            for part in [b'chunk-one;', b'chunk-two;', b'last']:
                c.sendall(b'%x;ext=1\r\n' % len(part) + part + b'\r\n')
            c.sendall(b'0\r\nX-Trailer: y\r\n\r\n')
        elif path == '/close': c.sendall(b'HTTP/1.0 200 OK\r\nConnection: close\r\n\r\nuntil close\n')
        elif path == '/redirect': c.sendall(resp(b'302 Found', extra=b'Location: https://localhost:8443/redirect2\r\n'))
        elif path == '/redirect2': c.sendall(resp(b'301 Moved', extra=b'Location: /plain\r\n'))
        elif path == '/echo':
            c.sendall(resp(b'200 OK', ('%s %s %d ' % (method, hdr.get('content-type',''), n)).encode() + rest))
        elif path == '/see-other': c.sendall(resp(b'303 See Other', extra=b'Location: /echo\r\n'))
        elif path == '/temp-redirect': c.sendall(resp(b'307 Temporary Redirect', extra=b'Location: echo\r\n'))
        elif path == '/busy': c.sendall(resp(b'429 Too Many Requests', b'slow down'))
        elif path == '/loop': c.sendall(resp(b'302 Found', extra=b'Location: /loop\r\n'))
        elif path == '/continue': c.sendall(b'HTTP/1.1 100 Continue\r\n\r\n' + resp(b'200 OK', b'after continue\n'))
        elif path == '/big': c.sendall(resp(b'200 OK', BIG))
        elif path == '/big-chunked':
            c.sendall(b'HTTP/1.1 200 OK\r\ntransfer-encoding: CHUNKED\r\n\r\n')
            i = 0
            while i < len(BIG):
                k = random.randint(1, 70000); part = BIG[i:i+k]; i += k
                c.sendall(b'%X\r\n' % len(part) + part + b'\r\n')
            c.sendall(b'0\r\n\r\n')
        elif path == '/truncated': c.sendall(b'HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\nshort')
        else: c.sendall(resp(b'404 Not Found', b'nope'))
    except Exception as e:
        print('server error', e)
    finally:
        try: c.shutdown(socket.SHUT_RDWR)
        except Exception: pass
        c.close()
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(('127.0.0.1', 8443)); s.listen(20)
while True:
    raw, _ = s.accept()
    try: c = ctx.wrap_socket(raw, server_side=True)
    except Exception as e: print('tls fail', e); raw.close(); continue
    threading.Thread(target=handle, args=(c,), daemon=True).start()
