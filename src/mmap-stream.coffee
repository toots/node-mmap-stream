mmap     = require "mmap.js"
{Duplex} = require "stream"

class module.exports extends Duplex
  constructor: (@size) ->
    @stack = []
    @pushing = true
    @malloc()

    @on "finish", =>
      @push chunk for chunk in @stack
      @push null

    super decodeStrings: true

  push: ->
    @pushing = super

  malloc: ->
    @buffer = mmap.alloc @size, mmap.PROT_READ | mmap.PROT_WRITE,
      mmap.MAP_ANON | mmap.MAP_PRIVATE, -1, 0
    @position = 0

  _write: (chunk, encoding, cb) ->
    if @pushing
      @push chunk
      return cb()

    copied = 0

    while copied < chunk.length
      written = chunk.copy @buffer, @position, copied

      @position += written
      copied    += written

      if @size <= @position
        @stack.push @buffer
        @malloc()

    cb()

  _read: ->
    @pushing = true
    while @pushing and 0 < @stack.length
      @push @stack.shift()
