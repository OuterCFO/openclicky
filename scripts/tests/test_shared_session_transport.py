import base64
import hashlib
import importlib.util
from pathlib import Path
import socket
import struct
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('shared_transport', ROOT / 'AppResources/OpenClicky/shared-session-bridge.py')
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)

class HandshakeSocket:
    def settimeout(self, _): pass
    def sendall(self, data): self.request = data
    def recv(self, _):
        key = self.request.split(b'Sec-WebSocket-Key: ')[1].split(b'\r\n')[0]
        accept = base64.b64encode(hashlib.sha1(key + b'258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest())
        return b'HTTP/1.1 101 Switching Protocols\r\nSec-WebSocket-Accept: ' + accept + b'\r\n\r\n'

class SharedTransportTests(unittest.TestCase):
    def test_valid_handshake_preserves_case_sensitive_accept(self):
        bridge.WebSocket(HandshakeSocket()).upgrade()

    def test_fragmented_json_waits_for_complete_message(self):
        left, right = socket.socketpair()
        try:
            ws = bridge.WebSocket(left)
            ws.buffer.extend(b'\x01\x08{"id":1,')
            self.assertEqual(list(ws.messages()), [])
            tail = b'"result":{}}'
            ws.buffer.extend(bytes([0x80, len(tail)]) + tail)
            self.assertEqual(list(ws.messages()), [b'{"id":1,"result":{}}'])
        finally: left.close(); right.close()

    def test_partial_and_multiple_frames(self):
        ws = bridge.WebSocket(HandshakeSocket())
        ws.buffer.extend(b'\x81\x07{"a":1')
        self.assertEqual(list(ws.messages()), [])
        ws.buffer.extend(b'}\x81\x07{"b":2}')
        self.assertEqual(list(ws.messages()), [b'{"a":1}', b'{"b":2}'])

    def test_oversized_frame_rejected_before_payload(self):
        ws = bridge.WebSocket(HandshakeSocket())
        ws.buffer.extend(b'\x81\x7f' + struct.pack('!Q', bridge.MAX_FRAME + 1))
        with self.assertRaises(ValueError): list(ws.messages())

    def test_ping_gets_masked_pong(self):
        left, right = socket.socketpair()
        try:
            ws = bridge.WebSocket(left); ws.buffer.extend(b'\x89\x02hi')
            self.assertEqual(list(ws.messages()), [])
            frame = right.recv(64)
            self.assertEqual(frame[:2], b'\x8a\x82')
            self.assertEqual(bytes(v ^ frame[2+i%4] for i,v in enumerate(frame[6:])), b'hi')
        finally: left.close(); right.close()
