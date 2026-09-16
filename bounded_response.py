#!/usr/bin/env python3

import sys


MAX_BYTES = 1_048_576
CHUNK_SIZE = 65_536


def main():
    remaining = MAX_BYTES

    try:
        while remaining:
            chunk = sys.stdin.buffer.read(min(CHUNK_SIZE, remaining))
            if not chunk:
                break
            sys.stdout.buffer.write(chunk)
            remaining -= len(chunk)

        sys.stdout.buffer.flush()

        # Read one byte beyond the limit so oversized input is rejected.
        if sys.stdin.buffer.read(1):
            return 1
    except OSError:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
