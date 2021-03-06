MmapStream = require "../src/mmap-stream"

describe "mmap-stream", ->
  beforeEach ->
    @stream = new MmapStream 100 * 1024
    @foo =
      cb: ->

  afterEach ->
    @stream = @foo = null

  it "should pass data while pushing", ->
    @stream.pushing = true

    spyOn @stream, "push"
    spyOn @foo, "cb"

    @stream._write "foo", null, =>
      @foo.cb()

    expect(@stream.push).toHaveBeenCalledWith "foo" 
    expect(@foo.cb).toHaveBeenCalled()

  it "should split into chunks when not pushing", ->
    @stream.pushing = false

    buf = new Buffer (5 * @stream.size + 3)
    buf[5 * @stream.size] = 113

    spyOn @stream, "push"
    spyOn @foo, "cb"

    @stream._write buf, null, =>
      @foo.cb()

    expect(@stream.push).not.toHaveBeenCalled()
    expect(@foo.cb).toHaveBeenCalled()
    expect(@stream.stack.length).toEqual 5 
    expect(@stream.position).toEqual 3
    expect(@stream.buffer[0]).toEqual 113

  it "should push while pushing", ->
    @stream.pushing = false

    callCount = 0
    pushed = []

    spyOn(MmapStream.__super__, "push").andCallFake (chunk) ->
      pushed.push chunk

      return false if callCount == 2

      callCount++
      true

    @stream.stack = [1, 2, 3, 4]

    @stream._read "foo"

    expect(pushed).toEqual [1, 2, 3]
    expect(@stream.stack).toEqual [4]
    expect(@stream.pushing).toEqual false 

  it "should push all the way when possible", ->
    @stream.pushing = false

    pushed = []

    spyOn(MmapStream.__super__, "push").andCallFake (chunk) ->
      pushed.push chunk
      true

    @stream.stack = [1, 2, 3, 4]
    @stream.buffer = new Buffer [5, 6, 7]
    @stream.position = 2

    @stream._read "foo"

    expect(pushed.length).toEqual 5
    expect(pushed.slice(0,4)).toEqual [1, 2, 3, 4]
    expect(Array.prototype.slice.call(pushed[4],0)).toEqual [5, 6]
    expect(@stream.stack.length).toEqual 0

  it "should push all remaining data when finished", ->
    pushed = []

    spyOn(MmapStream.__super__, "push").andCallFake (chunk) ->
      pushed.push chunk
      false

    @stream.stack = [1, 2, 3, 4]
    @stream.buffer = new Buffer [5, 6, 7]
    @stream.position = 2
    @stream.emit "finish"

    expect(pushed.length).toEqual 6
    expect(pushed.slice(0,4)).toEqual [1, 2, 3, 4]
    expect(Array.prototype.slice.call(pushed[4],0)).toEqual [5, 6]
    expect(pushed[5]).toEqual null

  it "should be able to malloc stuff", ->
    expect(@stream.buffer.length).toEqual @stream.size
