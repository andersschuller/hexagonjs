describe 'hx-animate', ->
  now = -> Date.now()

  class Delay extends hx.EventEmitter
    constructor: (duration) ->
      super
      @timeout = setTimeout((=> @emit('end')), duration)

    cancel: => clearTimeout(@timeout)

  hx.morph.register 'delay', (node, duration=100) ->
    new Delay(duration)

  class FakeNode
    constructor: ->
      @styles = {}
      @attrs = {}
      self = this
      @style = {
        setProperty: (prop, value) ->
          self.styles[prop] = value
      }

      @setAttribute = (prop, value) ->
        self.attrs[prop] = value

      @getAttribute = (prop) -> self.attrs[prop]

  savedGetComputedStyle = undefined
  savedHxLoop = undefined
  beforeEach ->
    jasmine.clock().install()
    savedGetComputedStyle = window.getComputedStyle
    window.getComputedStyle = (node, thing) ->
      {
        getPropertyValue: (prop) -> node.styles[prop]
      }

    # mock hx.loop
    hx_requestAnimationFrame = (f) ->
      setTimeout(f, 1)
    hx_loop_update = (f, g) -> if not f() then hx_requestAnimationFrame(g)
    savedHxLoop = hx.loop
    hx.loop = hx_loop = (f) ->
      g = -> hx_loop_update(f, g)
      hx_loop_update(f, g)

    baseTime = new Date(2013, 0, 1)
    jasmine.clock().mockDate(baseTime)

  afterEach ->
    window.getComputedStyle = savedGetComputedStyle
    hx.loop = savedHxLoop
    jasmine.clock().uninstall()

  describe 'hx.animate', ->

    it 'hx.selection().animate should return an animation', ->
      node = hx.detached('div').node()
      ease = ->
      fromSelection = hx.select(node).animate(ease)
      normal = hx.animate(node, ease)
      expect(fromSelection.node).toEqual(normal.node)
      expect(fromSelection.ease).toEqual(normal.ease)

    describe 'style', ->
      it 'should emit end at the end of an animation', ->
        end = false
        hx.animate(new FakeNode)
          .style('height', '100%', 10)
          .on 'end', -> end = true

        jasmine.clock().tick(10)
        expect(end).toBe(true)

      it 'the easing function passed in should be used', ->
        ease = (d) -> Math.sqrt(Math.abs(d))
        anim = hx.animate(new FakeNode, ease)
        expect(anim.ease).toBe(ease)

      it 'should emit end at the end of an animation with multiple styles', ->
        end = false
        hx.animate(new FakeNode)
          .style('height', '100%', 10)
          .style('width', '100%', 10)
          .on 'end', -> end = true

        jasmine.clock().tick(10)
        expect(end).toBe(true)

      it 'should take roughly the amount of time requested', ->
        start = now()
        time = undefined
        hx.animate(new FakeNode)
          .style('height', '100%', 100)
          .style('width', '100%', 50)
          .on 'end', ->
            time = now() - start

        jasmine.clock().tick(100)

        expect(time).toEqual(100)

      it 'should take roughly the amount of time requested (using default)', ->
        start = now()
        time = undefined
        hx.animate(new FakeNode)
          .style('height', '100%')
          .style('width', '100%', 50)
          .on 'end', ->
            time = now() - start

        jasmine.clock().tick(200)
        expect(time).toEqual(200)

      it 'if you dont supply a node, then the end event should be emitted straight away', ->
        end = false
        hx.animate()
          .on 'end', -> end = true
          .style('height', '100%', 100)
          .style('width', '100%', 50)

        expect(end).toEqual(true)

      it 'should only emit end once', ->
        count = 0
        hx.animate()
          .on('end', -> count++)
          .style('height', '100%', 100)
          .style('width', '100%', 50)


        expect(count).toBe(1)

      it 'should end on the correct values', ->
        node = new FakeNode
        hx.animate(node)
          .style('height', '100%', 100)
          .style('width', '100%', 50)

        jasmine.clock().tick(100)
        expect(node.styles['height']).toEqual('100%')
        expect(node.styles['width']).toEqual('100%')

      it 'should end on the correct values', ->

        end = false
        node = new FakeNode
        node.styles['width'] = '0%'
        node.styles['height'] = '50%'

        hx.animate(node)
          .style('height', '100%', 100)
          .style('width', '100%', 50)

        jasmine.clock().tick(100)
        expect(node.styles['height']).toEqual('100%')
        expect(node.styles['width']).toEqual('100%')

      it 'should interpolate to the correct values', ->

        end = false
        node = new FakeNode
        node.styles['width'] = '0%'
        node.styles['height'] = '50%'

        hx.animate(node)
          .style('width', '100%', 100)
          .style('height', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('50%')
        expect(node.styles['height']).toEqual('75%')

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('100%')
        expect(node.styles['height']).toEqual('100%')

      it 'changing the easing function should affect the values', ->

        end = false
        node = new FakeNode
        node.styles['width'] = '0%'
        node.styles['height'] = '50%'

        hx.animate(node, hx.ease.cubic)
          .style('width', '100%', 100)
          .style('height', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('1.5625%')

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('12.5%')
        expect(node.styles['height']).toEqual('56.25%')

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('100%')
        expect(node.styles['height']).toEqual('100%')

      it 'changing the easing function should affect the values', ->

        end = false
        node = new FakeNode
        node.styles['width'] = '0%'
        node.styles['height'] = '50%'

        hx.animate(node, hx.ease.quad)
          .style('width', '100%', 100)
          .style('height', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('6.25%')

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('100%')
        expect(node.styles['height']).toEqual('100%')

      it 'should interpolate the correct values', ->

        end = false
        node = new FakeNode

        hx.animate(node)
          .style('width', '0%', '100%', 100)
          .style('height', '50%', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        jasmine.clock().tick(25)
        expect(node.styles['width']).toEqual('50%')
        expect(node.styles['height']).toEqual('75%')

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('100%')
        expect(node.styles['height']).toEqual('100%')

      it 'should interpolate the correct values', ->

        end = false
        node = new FakeNode

        hx.animate(node)
          .style('width', '0%', '100%', undefined)
          .style('height', '50%', '100%', undefined)

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('50%')
        expect(node.styles['height']).toEqual('75%')

        jasmine.clock().tick(100)
        expect(node.styles['width']).toEqual('100%')
        expect(node.styles['height']).toEqual('100%')

      it 'cancel should work for range animations', ->

        end = false
        node = new FakeNode

        anim = hx.animate(node)
          .style('width', '0%', '100%', undefined)
          .style('height', '50%', '100%', undefined)

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        anim.cancel()

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        jasmine.clock().tick(100)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

      it 'cancel should work for range animations', ->

        end = false
        node = new FakeNode
        node.styles['width'] = '0%'
        node.styles['height'] = '50%'

        anim = hx.animate(node)
          .style('width', '100%')
          .style('height', '100%')

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        anim.cancel()

        jasmine.clock().tick(50)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

        jasmine.clock().tick(100)
        expect(node.styles['width']).toEqual('25%')
        expect(node.styles['height']).toEqual('62.5%')

    describe 'attr', ->
      it 'should emit end at the end of an animation', ->
        end = false
        hx.animate(new FakeNode)
          .attr('height', '100%', 10)
          .on 'end', -> end = true

        jasmine.clock().tick(10)
        expect(end).toBe(true)

      it 'the easing function passed in should be used', ->
        ease = (d) -> Math.sqrt(Math.abs(d))
        anim = hx.animate(new FakeNode, ease)
        expect(anim.ease).toBe(ease)

      it 'should emit end at the end of an animation with multiple attrs', ->
        end = false
        hx.animate(new FakeNode)
          .attr('height', '100%', 10)
          .attr('width', '100%', 10)
          .on 'end', -> end = true

        jasmine.clock().tick(10)
        expect(end).toBe(true)

      it 'should take roughly the amount of time requested', ->
        start = now()
        time = undefined
        hx.animate(new FakeNode)
          .attr('height', '100%', 100)
          .attr('width', '100%', 50)
          .on 'end', ->
            time = now() - start

        jasmine.clock().tick(100)

        expect(time).toEqual(100)

      it 'should take roughly the amount of time requested (using default)', ->
        start = now()
        time = undefined
        hx.animate(new FakeNode)
          .attr('height', '100%')
          .attr('width', '100%', 50)
          .on 'end', ->
            time = now() - start

        jasmine.clock().tick(200)
        expect(time).toEqual(200)

      it 'if you dont supply a node, then the end event should be emitted straight away', ->
        end = false
        hx.animate()
          .on 'end', -> end = true
          .attr('height', '100%', 100)
          .attr('width', '100%', 50)

        expect(end).toEqual(true)

      it 'should only emit end once', ->
        count = 0
        hx.animate()
          .on 'end', -> count++
          .attr('height', '100%', 100)
          .attr('width', '100%', 50)


        expect(count).toBe(1)

      it 'should end on the correct values', ->
        node = new FakeNode
        hx.animate(node)
          .attr('height', '100%', 100)
          .attr('width', '100%', 50)

        jasmine.clock().tick(100)
        expect(node.attrs['height']).toEqual('100%')
        expect(node.attrs['width']).toEqual('100%')

      it 'should end on the correct values', ->

        end = false
        node = new FakeNode
        node.attrs['width'] = '0%'
        node.attrs['height'] = '50%'

        hx.animate(node)
          .attr('height', '100%', 100)
          .attr('width', '100%', 50)

        jasmine.clock().tick(100)
        expect(node.attrs['height']).toEqual('100%')
        expect(node.attrs['width']).toEqual('100%')

      it 'should interpolate to the correct values', ->

        end = false
        node = new FakeNode
        node.attrs['width'] = '0%'
        node.attrs['height'] = '50%'

        hx.animate(node)
          .attr('width', '100%', 100)
          .attr('height', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('50%')
        expect(node.attrs['height']).toEqual('75%')

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('100%')
        expect(node.attrs['height']).toEqual('100%')

      it 'changing the easing function should affect the values', ->

        end = false
        node = new FakeNode
        node.attrs['width'] = '0%'
        node.attrs['height'] = '50%'

        hx.animate(node, hx.ease.cubic)
          .attr('width', '100%', 100)
          .attr('height', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('1.5625%')

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('12.5%')
        expect(node.attrs['height']).toEqual('56.25%')

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('100%')
        expect(node.attrs['height']).toEqual('100%')

      it 'changing the easing function should affect the values', ->

        end = false
        node = new FakeNode
        node.attrs['width'] = '0%'
        node.attrs['height'] = '50%'

        hx.animate(node, hx.ease.quad)
          .attr('width', '100%', 100)
          .attr('height', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('6.25%')

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('100%')
        expect(node.attrs['height']).toEqual('100%')

      it 'should interpolate the correct values', ->

        end = false
        node = new FakeNode

        hx.animate(node)
          .attr('width', '0%', '100%', 100)
          .attr('height', '50%', '100%', 100)

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        jasmine.clock().tick(25)
        expect(node.attrs['width']).toEqual('50%')
        expect(node.attrs['height']).toEqual('75%')

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('100%')
        expect(node.attrs['height']).toEqual('100%')

      it 'should interpolate the correct values', ->

        end = false
        node = new FakeNode

        hx.animate(node)
          .attr('width', '0%', '100%', undefined)
          .attr('height', '50%', '100%', undefined)

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('50%')
        expect(node.attrs['height']).toEqual('75%')

        jasmine.clock().tick(100)
        expect(node.attrs['width']).toEqual('100%')
        expect(node.attrs['height']).toEqual('100%')

      it 'cancel should work for range animations', ->

        end = false
        node = new FakeNode

        anim = hx.animate(node)
          .attr('width', '0%', '100%', undefined)
          .attr('height', '50%', '100%', undefined)

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        anim.cancel()

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        jasmine.clock().tick(100)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

      it 'cancel should work for range animations', ->

        end = false
        node = new FakeNode
        node.attrs['width'] = '0%'
        node.attrs['height'] = '50%'

        anim = hx.animate(node)
          .attr('width', '100%')
          .attr('height', '100%')

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        anim.cancel()

        jasmine.clock().tick(50)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')

        jasmine.clock().tick(100)
        expect(node.attrs['width']).toEqual('25%')
        expect(node.attrs['height']).toEqual('62.5%')


  describe 'hx.morph', ->

    it 'hx.selection().morph should return a morph', ->
      node = hx.detached('div').node()
      fromSelection = hx.select(node).morph()
      normal = hx.morph(node)
      expect(fromSelection.node).toEqual(normal.node)

    it 'should proceed straight away for no argument functions that are not event emitters', ->
      called1 = false
      called2 = false
      hx.morph()
        .then -> called1 = true
        .then -> called2 = true
        .go()

      expect(called1).toEqual(true)
      expect(called2).toEqual(true)

    it 'should wait until async functions finish before continuing', ->
      called = false

      hx.morph()
        .then (done) -> setTimeout(done, 100)
        .then -> called = true
        .go()

      expect(called).toEqual(false)
      jasmine.clock().tick(25)
      expect(called).toEqual(false)
      jasmine.clock().tick(100)
      expect(called).toEqual(true)

    it 'should wait until event emitters emit end finish before continuing', ->
      called = false

      hx.morph()
        .then (done) ->
          ee = new hx.EventEmitter
          setTimeout((-> ee.emit('end')), 100)
          ee
        .then -> called = true
        .go()

      expect(called).toEqual(false)
      jasmine.clock().tick(25)
      expect(called).toEqual(false)
      jasmine.clock().tick(100)
      expect(called).toEqual(true)

    it 'should cancel ongoing morphs correctly', ->
      called1 = false
      called2 = false

      node = new FakeNode

      hx.morph(node)
        .then (done) -> setTimeout(done, 100)
        .then -> called1 = true
        .go()

      jasmine.clock().tick(25)

      hx.morph(node)
        .then (done) -> setTimeout(done, 100)
        .then -> called2 = true
        .go(true)

      jasmine.clock().tick(150)

      expect(called1).toEqual(false)
      expect(called2).toEqual(true)

    it 'should do nothing when you cancel an ongoing morph when a node isnt given', ->
      called1 = false
      called2 = false

      hx.morph()
        .then (done) -> setTimeout(done, 100)
        .then -> called1 = true
        .go()

      jasmine.clock().tick(25)

      hx.morph()
        .then (done) -> setTimeout(done, 100)
        .then -> called2 = true
        .go(true)

      jasmine.clock().tick(150)

      expect(called1).toEqual(true)
      expect(called2).toEqual(true)

    it 'should be fine with cancelling morphs on a node that hasnt got any', ->
      called = false

      hx.morph(new FakeNode)
        .then (done) ->
          setTimeout(done, 100)
        .then -> called = true
        .go(true)

      jasmine.clock().tick(150)

      expect(called).toEqual(true)

    it 'should be fine with cancelling morphs on a node that hasnt got any (due to them all expiring)', ->
      called = false
      node = new FakeNode

      node.__hx__ = {}

      hx.morph(node)
        .then (done) -> setTimeout(done, 100)
        .then -> called = true
        .go(true)

      jasmine.clock().tick(150)

      expect(called).toEqual(true)

    it 'should ignore things that have already been cancelled', ->
      called = false
      node = new FakeNode

      node.__hx__ = {
        morphs: [
          { cancelled: true, cancel: -> called = true }
        ]
      }

      hx.morph(node)
        .then (done) -> setTimeout(done, 100)
        .go(true)

      expect(called).toEqual(false)

    it 'cancelling a morph twice should be fine', ->
      node = new FakeNode

      morph = hx.morph(node)
        .then (done) -> setTimeout(done, 100)
        .go(true)

      morph.cancel()

      expect(-> morph.cancel()).not.toThrow()

    it 'when cancelling, the cancellers should be called', ->
      node = new FakeNode

      cancelled1 = false
      cancelled2 = false

      morph = hx.morph(node)
        .then (done) -> {cancel: -> cancelled1 = true}
        .and (done) -> {cancel: -> cancelled2 = true}
        .go()

      morph.cancel()

      expect(cancelled1).toEqual(true)
      expect(cancelled2).toEqual(true)

    it 'shouldnt fall over on cancel properties that isnt a function', ->
      node = new FakeNode

      cancelled1 = false
      cancelled2 = false

      morph = hx.morph(node)
        .then (done) -> {cancel: 'not-a-function'}
        .and (done) -> {cancel: -> cancelled1 = true}
        .and (done) -> {cancel: -> cancelled2 = true}
        .go()

      expect(-> morph.cancel()).not.toThrow()

    it 'should ignore things that have already finished', ->
      called = false
      node = new FakeNode

      node.__hx__ = {
        morphs: [
          { finished: true, cancel: -> called = true }
        ]
      }

      hx.morph(node).go(true)

      expect(called).toEqual(false)

    it 'should filter out cancelled morphs when a new one is started', ->
      called = false
      node = new FakeNode

      original = [
        { cancel: -> called = true }
        { finised: true, cancel: -> called = true }
        { cancelled: true, cancel: -> called = true }
      ]

      node.__hx__ = {
        morphs: original.slice()
      }

      hx.morph(node).go(false)

      expect(node.__hx__.morphs).toContain(original[0])

    it 'things with a cancel method should be put onto the cancellers array', ->
      node = new FakeNode

      obj = { cancel: -> }

      morph = hx.morph(node)
        .then (done) -> obj
        .and (done) -> obj
        .and (done) -> obj
        .go()

      expect(morph.cancelers).toEqual([obj, obj, obj])


    it 'should wait until all async things have finished before emitting end', ->
      called1 = false
      called2 = false
      called3 = false
      end = false

      hx.morph()
        .then (done) ->
          finish = ->
            called1 = true
            done()
          setTimeout(finish, 100)
        .and (done) ->
          finish = ->
            called2 = true
            done()
          setTimeout(finish, 200)
        .and (done) ->
          finish = ->
            called3 = true
            done()
          setTimeout(finish, 300)
        .go()
        .on 'end', -> end = true

      jasmine.clock().tick(101)
      expect(called1).toEqual(true)
      expect(called2).toEqual(false)
      expect(called3).toEqual(false)
      expect(end).toEqual(false)

      jasmine.clock().tick(100)
      expect(called1).toEqual(true)
      expect(called2).toEqual(true)
      expect(called3).toEqual(false)
      expect(end).toEqual(false)

      jasmine.clock().tick(100)
      expect(called1).toEqual(true)
      expect(called2).toEqual(true)
      expect(called3).toEqual(true)
      expect(end).toEqual(true)

    it 'with should do the same as then', ->
      called1 = false
      called2 = false
      called3 = false
      end = false

      hx.morph()
        .with (done) ->
          finish = ->
            called1 = true
            done()
          setTimeout(finish, 100)
        .and (done) ->
          finish = ->
            called2 = true
            done()
          setTimeout(finish, 200)
        .and (done) ->
          finish = ->
            called3 = true
            done()
          setTimeout(finish, 300)
        .on 'end', -> end = true
        .go()

      jasmine.clock().tick(101)
      expect(called1).toEqual(true)
      expect(called2).toEqual(false)
      expect(called3).toEqual(false)
      expect(end).toEqual(false)

      jasmine.clock().tick(100)
      expect(called1).toEqual(true)
      expect(called2).toEqual(true)
      expect(called3).toEqual(false)
      expect(end).toEqual(false)

      jasmine.clock().tick(100)
      expect(called1).toEqual(true)
      expect(called2).toEqual(true)
      expect(called3).toEqual(true)
      expect(end).toEqual(true)

    it 'named morphs should work', ->
      end = false

      class Delay extends hx.EventEmitter
        constructor: (duration) ->
          super
          @timeout = setTimeout((=> @emit('end')), duration)

        cancel: => clearTimeout(@timeout)

      hx.morph.register 'delay', (node, duration=100) ->
        new Delay(duration)

      hx.morph.register 'delay2', (node, duration=100) ->
        new Delay(duration)

      node = new FakeNode

      hx.morph(node)
        .with('delay', 500).and('delay2', 100)
        .on 'end', -> end = true
        .go()

      jasmine.clock().tick(101)
      expect(end).toEqual(false)

      jasmine.clock().tick(400)
      expect(end).toEqual(true)

    it 'named morphs should do nothing when you have no node', ->
      end = false

      class Delay extends hx.EventEmitter
        constructor: (duration) ->
          super
          @timeout = setTimeout((=> @emit('end')), duration)

        cancel: => clearTimeout(@timeout)

      hx.morph.register 'delay', (node, duration=100) ->
        new Delay(duration)

      hx.morph.register 'delay2', (node, duration=100) ->
        new Delay(duration)

      hx.morph()
        .with('delay', 500).and('delay2', 100)
        .on 'end', -> end = true
        .go()

      jasmine.clock().tick(101)
      expect(end).toEqual(true)

      jasmine.clock().tick(400)
      expect(end).toEqual(true)

    it 'a warning should be thrown when a named morph is used that doesnt exist', ->
      spyOn(console, 'warn')

      hx.morph(new FakeNode)
        .with('delay5', 500)
        .go()

      expect(console.warn).toHaveBeenCalled()

    it 'andStyle should affect an elements styles', ->
      node = new FakeNode

      node.styles['height'] = '0'

      hx.morph(node)
        .andStyle('height', '100')
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('100')

    it 'andStyle should affect an elements styles (with custom duration)', ->
      node = new FakeNode

      node.styles['height'] = '0'

      hx.morph(node)
        .andStyle('height', '100', 500)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('100')

    it 'andStyle should affect an elements styles (with start and end values)', ->
      node = new FakeNode

      hx.morph(node)
        .andStyle('height', '0', '100', undefined)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('100')

    it 'andStyle should affect an elements styles (with start and end values and custom duration)', ->
      node = new FakeNode

      hx.morph(node)
        .andStyle('height', '0', '100', 500)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('100')

    it 'thenStyle should affect an elements styles', ->
      node = new FakeNode

      node.styles['height'] = '0'

      hx.morph(node)
        .thenStyle('height', '100')
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('100')

    it 'thenStyle should affect an elements styles (with custom duration)', ->
      node = new FakeNode

      node.styles['height'] = '0'

      hx.morph(node)
        .thenStyle('height', '100', 500)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('100')

    it 'thenStyle should affect an elements styles (with start and end values)', ->
      node = new FakeNode

      hx.morph(node)
        .thenStyle('height', '0', '100', undefined)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('100')

    it 'thenStyle should affect an elements styles (with start and end values and custom duration)', ->
      node = new FakeNode

      hx.morph(node)
        .thenStyle('height', '0', '100', 500)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('100')

    it 'andAttr should affect an elements attributes', ->
      node = new FakeNode

      node.attrs['height'] = '0'

      hx.morph(node)
        .andAttr('height', '100')
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('100')

    it 'andAttr should affect an elements attributes (with custom duration)', ->
      node = new FakeNode

      node.attrs['height'] = '0'

      hx.morph(node)
        .andAttr('height', '100', 500)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('100')

    it 'andAttr should affect an elements attributes (with start and end values)', ->
      node = new FakeNode

      hx.morph(node)
        .andAttr('height', '0', '100', undefined)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('100')

    it 'andAttr should affect an elements attributes (with start and end values and custom duration)', ->
      node = new FakeNode

      hx.morph(node)
        .andAttr('height', '0', '100', 500)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('100')

    it 'thenAttr should affect an elements attributes', ->
      node = new FakeNode

      node.attrs['height'] = '0'

      hx.morph(node)
        .thenAttr('height', '100')
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('100')

    it 'thenAttr should affect an elements attributes (with custom duration)', ->
      node = new FakeNode

      node.attrs['height'] = '0'

      hx.morph(node)
        .thenAttr('height', '100', 500)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('100')

    it 'thenAttr should affect an elements attributes (with start and end values)', ->
      node = new FakeNode

      hx.morph(node)
        .thenAttr('height', '0', '100', undefined)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('100')

    it 'thenAttr should affect an elements attributes (with start and end values and custom duration)', ->
      node = new FakeNode

      hx.morph(node)
        .thenAttr('height', '0', '100', 500)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('100')

   it 'withStyle should affect an elements attributes', ->
      node = new FakeNode

      node.styles['height'] = '0'

      hx.morph(node)
        .withStyle('height', '100')
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('100')

    it 'withStyle should affect an elements attributes (with custom duration)', ->
      node = new FakeNode

      node.styles['height'] = '0'

      hx.morph(node)
        .withStyle('height', '100', 500)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('100')

    it 'withStyle should affect an elements attributes (with start and end values)', ->
      node = new FakeNode

      hx.morph(node)
        .withStyle('height', '0', '100', undefined)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.styles['height']).toEqual('100')

    it 'withStyle should affect an elements attributes (with start and end values and custom duration)', ->
      node = new FakeNode

      hx.morph(node)
        .withStyle('height', '0', '100', 500)
        .go()

      expect(node.styles['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.styles['height']).toEqual('100')

    it 'withAttr should affect an elements attributes', ->
      node = new FakeNode

      node.attrs['height'] = '0'

      hx.morph(node)
        .withAttr('height', '100')
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('100')

    it 'withAttr should affect an elements attributes (with custom duration)', ->
      node = new FakeNode

      node.attrs['height'] = '0'

      hx.morph(node)
        .withAttr('height', '100', 500)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('100')

    it 'withAttr should affect an elements attributes (with start and end values)', ->
      node = new FakeNode

      hx.morph(node)
        .withAttr('height', '0', '100', undefined)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(100)
      expect(node.attrs['height']).toEqual('100')

    it 'withAttr should affect an elements attributes (with start and end values and custom duration)', ->
      node = new FakeNode

      hx.morph(node)
        .withAttr('height', '0', '100', 500)
        .go()

      expect(node.attrs['height']).toEqual('0')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('50')
      jasmine.clock().tick(250)
      expect(node.attrs['height']).toEqual('100')