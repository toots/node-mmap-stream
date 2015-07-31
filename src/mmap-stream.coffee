fs       = require "fs"
mmap     = require "mmap.js"
{Duplex} = require "stream"
tmp      = require "tmp"

class module.exports extends Duplex
  constructor: (@size) ->
    @stack = []
    @pushing = true
    @malloc()

    @on "finish", =>
      @push chunk for chunk in @stack
      @push @buffer.slice(0, @position) if 0 < @position
      @push null

    super decodeStrings: true

  push: ->
    @pushing = super

  malloc: ->
    {fd, removeCallback} = tmp.fileSync()

    fs.ftruncateSync fd, @size

    @buffer = mmap.alloc @size, mmap.PROT_READ | mmap.PROT_WRITE,
      mmap.MAP_SHARED, fd, 0
    @position = 0

    removeCallback()

  _write: (chunk, encoding, cb) ->
    if @pushing and @stack.length == 0 and @position == 0
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

    return unless @pushing and 0 < @position

    @push @buffer.slice(0, @position)
    @position = 0
