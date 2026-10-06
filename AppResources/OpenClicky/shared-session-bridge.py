#!/usr/bin/env python3
"""JSONL to Codex's local Unix WebSocket transport. No credentials or inference logic."""
import base64
import hashlib
import json
import os
import selectors
import socket
import struct
import sys

MAX_FRAME = 16 * 1024 * 1024

class WebSocket:
    def __init__(self, sock):
        self.sock = sock
        self.buffer = bytearray()
        self.fragments = bytearray()
        self.fragment_opcode = None

    def upgrade(self):
        key = base64.b64encode(os.urandom(16)).decode()
        self.sock.settimeout(5)
        self.sock.sendall(("GET / HTTP/1.1\r\nHost: localhost\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                           f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        while b"\r\n\r\n" not in self.buffer:
            chunk = self.sock.recv(4096)
            if not chunk: raise ConnectionError("Codex closed the connection during handshake")
            self.buffer.extend(chunk)
            if len(self.buffer) > 65536: raise ValueError("Oversized handshake")
        head, rest = bytes(self.buffer).split(b"\r\n\r\n", 1)
        self.buffer = bytearray(rest)
        lines = head.decode().split("\r\n")
        headers = {name.lower(): value for name, value in (line.split(":", 1) for line in lines[1:] if ":" in line)}
        expected = base64.b64encode(hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()).decode()
        if not lines[0].startswith("HTTP/1.1 101 ") or headers.get("sec-websocket-accept", "").strip() != expected:
            raise ConnectionError("Codex WebSocket handshake failed")
        self.sock.settimeout(None)

    def send(self, data, opcode=1):
        if len(data) > MAX_FRAME: raise ValueError("Oversized message")
        mask = os.urandom(4)
        size = len(data)
        length = bytes([128 | size]) if size < 126 else (b"\xfe" + struct.pack("!H", size) if size < 65536 else b"\xff" + struct.pack("!Q", size))
        self.sock.sendall(bytes([128 | opcode]) + length + mask + bytes(v ^ mask[i % 4] for i, v in enumerate(data)))

    def messages(self):
        while len(self.buffer) >= 2:
            a, b = self.buffer[:2]
            size = b & 127
            offset = 2
            if a & 0x70 or b & 128: raise ValueError("Invalid server frame")
            if size in (126, 127):
                count = 2 if size == 126 else 8
                if len(self.buffer) < offset + count: return
                size = int.from_bytes(self.buffer[offset:offset + count], "big")
                offset += count
            if size > MAX_FRAME: raise ValueError("Oversized frame")
            if len(self.buffer) < offset + size: return
            data = bytes(self.buffer[offset:offset + size])
            del self.buffer[:offset + size]
            opcode, final = a & 15, bool(a & 128)
            if opcode >= 8:
                if not final or size > 125: raise ValueError("Invalid control frame")
                if opcode == 8: raise ConnectionError("Codex closed the connection")
                if opcode == 9: self.send(data, opcode=10)
                continue
            if opcode == 1:
                if self.fragment_opcode is not None: raise ValueError("Unexpected text fragment")
                self.fragment_opcode = opcode
            elif opcode != 0 or self.fragment_opcode is None:
                raise ValueError("Unsupported WebSocket frame")
            self.fragments.extend(data)
            if len(self.fragments) > MAX_FRAME: raise ValueError("Oversized fragmented message")
            if final:
                message = bytes(self.fragments)
                self.fragments.clear()
                self.fragment_opcode = None
                json.loads(message)  # Reject non-JSON protocol data.
                yield message

def relay(path):
    sock = socket.socket(socket.AF_UNIX)
    sock.connect(path)
    ws = WebSocket(sock)
    ws.upgrade()
    pending = bytearray()
    with selectors.DefaultSelector() as selector:
        selector.register(sock, selectors.EVENT_READ, "socket")
        selector.register(sys.stdin.buffer, selectors.EVENT_READ, "stdin")
        try:
            while True:
                for message in ws.messages():
                    sys.stdout.buffer.write(message + b"\n")
                    sys.stdout.buffer.flush()
                for key, _ in selector.select():
                    data = os.read(key.fileobj.fileno(), 65536)
                    if not data: return
                    if key.data == "socket": ws.buffer.extend(data)
                    else:
                        pending.extend(data)
                        if len(pending) > MAX_FRAME: raise ValueError("Oversized input")
                        while b"\n" in pending:
                            line, _, pending = pending.partition(b"\n")
                            if line:
                                json.loads(line)
                                ws.send(line)
        finally: sock.close()

if __name__ == "__main__":
    try: relay(sys.argv[1])
    except Exception as exc:
        print(f"Shared Codex transport: {exc}", file=sys.stderr)
        sys.exit(1)
