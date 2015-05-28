# TODO: web-component styling (currently, Element.style property is used)
# TODO: allow disabling the inputs
# TODO: allow multiple ranges (a multi-range-slider)
# TODO: allow different value-formats
# TODO: add tooltip

rulerTemplate = document._currentScript.ownerDocument.querySelector 'template.ruler'
sliderTemplate = document._currentScript.ownerDocument.querySelector 'template.slider'


timeRangePrototype = Object.create HTMLElement::,

  # Properties

  rangeContainer:
    get: -> @_shadowRoot.querySelector('[range-container]')

  minValue:
    get: -> @parseTime(@getAttribute 'min') ? 0

  maxValue:
    get: -> @parseTime(@getAttribute 'max') ? (24 * 60)

  borderColor:
    get: -> @getAttribute('border-color')

  borderRadius:
    get: -> @getAttribute('border-radius')

  # Utilities

  formatTime:
    value: (timeInt) ->
      result = ''
      timeInt = Math.floor(timeInt)
      while 0 < timeInt
        result = ('0' + (timeInt % 60)).slice(-2) + ':' + result
        timeInt = Math.floor(timeInt / 60)
      result.replace(/^0/, '').replace(/:$/, '')

  parseTime:
    value: (timeString) ->
      result = 0
      timeString.split(':').forEach (x) ->
        result *= 60
        result += parseInt(x) ? 0
      result


document.registerElement 'time-range-ruler', prototype: Object.create timeRangePrototype,

  createdCallback:
    value: ->
      @_shadowRoot = @createShadowRoot()
      @_shadowRoot.appendChild(document.importNode(rulerTemplate.content, true))
      for h in [@firstHour..@lastHour]
        el = document.createElement('div')
        subel = document.createElement('div')
        subel.innerHTML = ('0' + h).slice(-2)
        el.appendChild(subel)
        @rangeContainer.appendChild(el)
        [.25, .5, .25].forEach (em) =>
          el = document.createElement('div')
          @rangeContainer.appendChild(el)
      @setStyle()

  # Properties

  rangeContainerWrapper:
    get: -> @_shadowRoot.querySelector('[range-container-wrapper]')

  firstHour:
    get: -> parseInt(Math.floor(@minValue / 60))

  lastHour:
    get: -> parseInt(Math.ceil(@maxValue / 60))

  # Commands

  setStyle:
    value: ->
      @rangeContainer.style.width = (100 * (@lastHour + 1 - @firstHour) * 60 / (@maxValue - @minValue)) + '%'
      @rangeContainer.style.left = (100 * (@firstHour * 60 - @minValue) / (@maxValue - @minValue)) + '%'
      Array::forEach.call @rangeContainer.children, (child, i) =>
        child.style.borderLeftColor = @borderColor
        beforeMinValue = 60 * @firstHour + 15 * (i - 1) < @minValue
        afterMaxValue = @maxValue < 60 * @firstHour + 15 * (i - 1)
        child.style.visibility = 'hidden' if beforeMinValue or afterMaxValue


document.registerElement 'time-range-slider', prototype: Object.create timeRangePrototype,

  # Event handlers
  createdCallback:
    value: ->
      @_shadowRoot = @createShadowRoot()
      @_shadowRoot.appendChild(document.importNode(sliderTemplate.content, true))
      @setStyle()
      @addEventListener('change', @inputChangedCallback)
      @range.addEventListener('touchstart', @slideListener)
      @leftHandle.addEventListener('touchstart', @slideListener)
      @rightHandle.addEventListener('touchstart', @slideListener)
      @range.addEventListener('mousedown', @slideListener)
      @leftHandle.addEventListener('mousedown', @slideListener)
      @rightHandle.addEventListener('mousedown', @slideListener)

  attributeChangedCallback:
    value: (attrName, oldVal, newVal) ->
      switch attrName
        when 'min', 'max' then @setPositioning()

  inputChangedCallback:
    value: (e) ->
      @setPositioning()

  slideListener:
    get: ->
      timeRangeSlider = @
      changingEvent = new CustomEvent('changing', {bubbles: true, cancelable: true})
      changedEvent = new CustomEvent('changed', {bubbles: true, cancelable: true})

      result =
        handleEvent: (e) ->
          switch e.type
            when 'mousedown', 'touchstart'
              @handleDragStartEvent(e)
            when 'mousemove', 'touchmove'
              @handleMoveEvent(e)
            when 'mouseup', 'touchend'
              @handleDragEndEvent(e)

        handleDragStartEvent: (e) ->
          switch e.type
            when 'mousedown'
              @moveEventType = 'mousemove'
              @dragendEventType = 'mouseup'
              @startPageX = e.pageX
            when 'touchstart'
              @moveEventType = 'touchmove'
              @dragendEventType = 'touchend'
              @startPageX = e.touches[0].pageX
            else return
          e.preventDefault()
          e.stopPropagation()
          @target = e.target
          @startOffsetLeft = timeRangeSlider.range.offsetLeft
          @startClientWidth = timeRangeSlider.range.clientWidth
          document.addEventListener @moveEventType, @
          document.addEventListener @dragendEventType, @

        handleMoveEvent: (e) ->
          pageX = null
          switch e.type
            when 'mousemove' then pageX = e.pageX
            when 'touchmove' then pageX = e.touches[0].pageX
            else return
          e.preventDefault()
          e.stopPropagation()
          dx = pageX - @startPageX
          containerWidth = timeRangeSlider.rangeContainer.clientWidth
          minValue = timeRangeSlider.minValue
          maxValue = timeRangeSlider.maxValue
          switch @target
            when timeRangeSlider.range
              offsetLeft = @startOffsetLeft + dx
              offsetLeft = Math.max(offsetLeft, 0)
              offsetLeft = Math.min(offsetLeft, containerWidth - @startClientWidth)
              offsetRight = @startOffsetLeft + @startClientWidth + dx
              offsetRight = Math.max(offsetRight, @startClientWidth)
              startValue = minValue + (maxValue - minValue) * offsetLeft / containerWidth
              endValue = minValue + (maxValue - minValue) * (offsetLeft + @startClientWidth) / containerWidth
              timeRangeSlider.startInput.value = timeRangeSlider.formatTime(startValue)
              timeRangeSlider.endInput.value = timeRangeSlider.formatTime(endValue)
            when timeRangeSlider.leftHandle
              offsetLeft = @startOffsetLeft + dx
              offsetLeft = Math.max(offsetLeft, 0)
              offsetLeft = Math.min(offsetLeft, @startOffsetLeft + @startClientWidth)
              startValue = minValue + (maxValue - minValue) * offsetLeft / containerWidth
              timeRangeSlider.startInput.value = timeRangeSlider.formatTime(startValue)
            when timeRangeSlider.rightHandle
              offsetRight = @startOffsetLeft + @startClientWidth + dx
              offsetRight = Math.max(offsetRight, @startOffsetLeft)
              offsetRight = Math.min(offsetRight, containerWidth)
              endValue = minValue + (maxValue - minValue) * offsetRight / containerWidth
              timeRangeSlider.endInput.value = timeRangeSlider.formatTime(endValue)
          timeRangeSlider.setPositioning()
          timeRangeSlider.dispatchEvent(changingEvent)

        handleDragEndEvent: (e) ->
          switch e.type
            when 'mouseup', 'touchend' then null
            else return
          e.preventDefault()
          e.stopPropagation()
          document.removeEventListener @moveEventType, @
          document.removeEventListener @dragendEventType, @
          timeRangeSlider.dispatchEvent(changedEvent)

  # Properties

  range:
    get: -> @rangeContainer.children[0]

  handles:
    get: -> @range.querySelectorAll('div')

  leftHandle:
    get: -> @handles[0]

  rightHandle:
    get: -> @handles[1]

  startValue:
    get: -> @parseTime(@startInput.value)
    set: (value) ->
      @startInput.value = @formatTime(value)
      @setPositioning()

  endValue:
    get: -> @parseTime(@endInput.value)
    set: (value) ->
      @endInput.value = @formatTime(value)
      @setPositioning()

  inputs:
    get: -> @querySelectorAll('input')

  startInput:
    get: -> @inputs[0]

  endInput:
    get: -> @inputs[1]

  startPercentage:
    get: ->
      100 * (@startValue - @minValue) / (@maxValue - @minValue)

  endPercentage:
    get: ->
      100 * (@endValue - @minValue) / (@maxValue - @minValue)

  color:
    get: -> @getAttribute('color')

  # Commands

  setStyle:
    value: ->
      @rangeContainer.style.borderColor = @borderColor or 'silver'
      @rangeContainer.style.borderRadius = @borderRadius

      @range.style.backgroundColor = @color or 'gray'
      @range.style.borderRadius = @borderRadius
      @setPositioning()

  setPositioning:
    value: ->
      @range.style.left = @startPercentage + '%'
      @range.style.width = (@endPercentage - @startPercentage) + '%'
