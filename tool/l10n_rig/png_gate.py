#!/usr/bin/env python3
"""Reject blank / uniform PNG frames from `screencap`.

Hardware-GPU Pixel AVDs are known to return a nonempty PNG of uniform
transparent black while the app has already drawn.
"""

from __future__ import annotations

import struct
import zlib

PNG_SIG = b"\x89PNG\r\n\x1a\n"
_SAMPLES = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


def png_reject_reason(data: bytes) -> str | None:
    if len(data) < 24 or not data.startswith(PNG_SIG):
        return "screenshot is not a PNG"
    try:
        width, height, bit_depth, color_type, raw = _decode(data)
        pixels = _unfilter(width, height, bit_depth, color_type, raw)
    except (ValueError, struct.error, zlib.error) as exc:
        return f"screenshot PNG could not be decoded: {exc}"
    if width < 2 or height < 2:
        return "screenshot PNG is too small"
    if not pixels:
        return "screenshot PNG has no pixels"
    if all(p[0] == 0 and p[1] == 0 and p[2] == 0 for p in pixels):
        return "blank framebuffer capture is not PASS"
    first = pixels[0]
    if all(p == first for p in pixels):
        return "uniform framebuffer capture is not PASS"
    return None


def _decode(data: bytes) -> tuple[int, int, int, int, bytes]:
    pos = 8
    width = height = bit_depth = color_type = None
    idat = bytearray()
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        tag = data[pos + 4 : pos + 8]
        start = pos + 8
        end = start + length
        if end + 4 > len(data):
            raise ValueError("truncated PNG chunk")
        chunk = data[start:end]
        pos = end + 4
        if tag == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk[:10])
        elif tag == b"IDAT":
            idat.extend(chunk)
        elif tag == b"IEND":
            break
    if width is None or height is None or bit_depth is None or color_type is None:
        raise ValueError("PNG missing IHDR")
    return width, height, bit_depth, color_type, zlib.decompress(bytes(idat))


def _paeth(left: int, up: int, up_left: int) -> int:
    estimate = left + up - up_left
    pa = abs(estimate - left)
    pb = abs(estimate - up)
    pc = abs(estimate - up_left)
    if pa <= pb and pa <= pc:
        return left
    if pb <= pc:
        return up
    return up_left


def _unfilter(
    width: int,
    height: int,
    bit_depth: int,
    color_type: int,
    raw: bytes,
) -> list[tuple[int, int, int, int]]:
    if bit_depth != 8 or color_type not in _SAMPLES:
        raise ValueError("unsupported PNG format")
    bpp = _SAMPLES[color_type]
    stride = width * bpp
    pos = 0
    prev = bytearray(stride)
    rows: list[bytes] = []
    for _ in range(height):
        if pos + 1 + stride > len(raw):
            raise ValueError("truncated PNG rows")
        filter_type = raw[pos]
        pos += 1
        filt = raw[pos : pos + stride]
        pos += stride
        recon = bytearray(stride)
        for index in range(stride):
            left = recon[index - bpp] if index >= bpp else 0
            up = prev[index]
            up_left = prev[index - bpp] if index >= bpp else 0
            x = filt[index]
            if filter_type == 0:
                recon[index] = x
            elif filter_type == 1:
                recon[index] = (x + left) & 255
            elif filter_type == 2:
                recon[index] = (x + up) & 255
            elif filter_type == 3:
                recon[index] = (x + (left + up) // 2) & 255
            elif filter_type == 4:
                recon[index] = (x + _paeth(left, up, up_left)) & 255
            else:
                raise ValueError("unsupported PNG filter")
        rows.append(bytes(recon))
        prev = recon
    pixels: list[tuple[int, int, int, int]] = []
    for row in rows:
        for x in range(width):
            off = x * bpp
            sample = row[off : off + bpp]
            if color_type == 6:
                pixels.append((sample[0], sample[1], sample[2], sample[3]))
            elif color_type == 2:
                pixels.append((sample[0], sample[1], sample[2], 255))
            elif color_type == 0:
                pixels.append((sample[0], sample[0], sample[0], 255))
            elif color_type == 4:
                pixels.append((sample[0], sample[0], sample[0], sample[1]))
            else:
                raise ValueError("unsupported PNG color type")
    return pixels
