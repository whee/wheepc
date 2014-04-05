## Redis clients

The client handling needs actual thought. Waiting for a response with blpop
will block the Redis client (but not Node). This means nothing else can
use that particular client until a response comes back. Not that great.

One client per channel per endpoint may be a reasonable compromise between
overloading Redis with clients and blocking unrelated operations in the same
process.

## Research

In theory, one can start multiple handlers for the same channel in different
processes to scale. Need to test it.
