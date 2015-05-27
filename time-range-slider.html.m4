<style>
include(`time-range-slider.css')
</style>

<template class="ruler">
	<div range-container-wrapper>
		<div range-container><content></content></div>
	</div>
</template>

<template class="slider">
	<div range-container>
		<div range>
			<div left-handle></div>
			<div right-handle></div>
			<content></content>
		</div>
	</div>
</template>

<!-- a single-range slider -->
<script type="text/javascript">
	'use strict';

	// TODO: web-component styling (currently, Element.style property is used)
	// TODO: allow disabling the inputs
	// TODO: allow multiple ranges (a multi-range-slider)
	// TODO: allow different value-formats
	// TODO: add tooltip

	// create a local scope
	(function() {
		var rulerTemplate = document._currentScript.ownerDocument.querySelector('template.ruler');
		var sliderTemplate = document._currentScript.ownerDocument.querySelector('template.slider');

		var timeRangePrototype = Object.create(HTMLElement.prototype, {

			// Properties

			rangeContainer: {
				get: function() { return this._shadowRoot.querySelector('[range-container]'); }
			},

			minValue: {
				get: function() {
					var result = this.parseTime(this.getAttribute('min'));
					return result === null ? 0 : result;
				}
			},

			maxValue: {
				get: function() {
					var result = this.parseTime(this.getAttribute('max'));
					return result === null ? 24 * 60 : result;
				}
			},

			borderColor: {
				get: function() { return this.getAttribute('border-color'); }
			},

			borderRadius: {
				get: function() { return this.getAttribute('border-radius'); }
			},

			// Utilities

			formatTime: {
				value: function(timeInt) {
					var result = '';
					timeInt = Math.floor(timeInt);
					while (0 < timeInt) {
						result = ('0' + (timeInt % 60)).slice(-2) + ':' + result;
						timeInt = Math.floor(timeInt / 60);
					}
					return result.replace(/^0/, '').replace(/:$/, '');
				}
			},

			parseTime: {
				value: function(timeString) {
					var result = 0;
					timeString.split(':').forEach(function(x) {
						result *= 60;
						result += parseInt(x) || 0;
					});
					return result;
				}
			},

		});

		var timeRangeRulerPrototype = Object.create(timeRangePrototype, {

			createdCallback: {
				value: function() {
					this._shadowRoot = this.createShadowRoot();
					this._shadowRoot.appendChild(document.importNode(rulerTemplate.content, true));
					for (var h = this.firstHour; h <= this.lastHour; h ++) {
						var el = document.createElement('div');
						var subel = document.createElement('div');
						subel.innerHTML = ('0' + h).slice(-2);
						el.appendChild(subel);
						this.rangeContainer.appendChild(el);
						var self = this;
						[.25, .5, .25].forEach(function(em) {
							var el = document.createElement('div');
							self.rangeContainer.appendChild(el);
						});
					}
					this.setStyle();
				}
			},

			// Properties

			rangeContainerWrapper: {
				get: function() { return this._shadowRoot.querySelector('[range-container-wrapper]'); }
			},

			firstHour: {
				get: function() { return parseInt(Math.floor(this.minValue / 60)); }
			},

			lastHour: {
				get: function() { return parseInt(Math.ceil(this.maxValue / 60)); }
			},

			// Commands

			setStyle: {
				value: function() {
					this.rangeContainer.style.width = (100 * (this.lastHour + 1 - this.firstHour) * 60 / (this.maxValue - this.minValue)) + '%';
					this.rangeContainer.style.left = (100 * (this.firstHour * 60 - this.minValue) / (this.maxValue - this.minValue)) + '%';
					var self = this;
					Array.prototype.forEach.call(this.rangeContainer.children, function(child, i) {
						child.style.borderLeftColor = self.borderColor;
						var beforeMinValue = 60 * self.firstHour + 15 * (i - 1) < self.minValue;
						var afterMaxValue = self.maxValue < 60 * self.firstHour + 15 * (i - 1);
						if (beforeMinValue || afterMaxValue) child.style.visibility = 'hidden';
					});
				}
			},

		});

		var timeRangeSliderPrototype = Object.create(timeRangePrototype, {

			// Event handlers
			createdCallback: {
				value: function() {
					this._shadowRoot = this.createShadowRoot();
					this._shadowRoot.appendChild(document.importNode(sliderTemplate.content, true));
					this.setStyle();
					this.addEventListener('change', this.inputChangedCallback);
					this.range.addEventListener('touchstart', this.slideListener);
					this.leftHandle.addEventListener('touchstart', this.slideListener);
					this.rightHandle.addEventListener('touchstart', this.slideListener);
					this.range.addEventListener('mousedown', this.slideListener);
					this.leftHandle.addEventListener('mousedown', this.slideListener);
					this.rightHandle.addEventListener('mousedown', this.slideListener);
				}
			},

			attributeChangedCallback: {
				value: function(attrName, oldVal, newVal) {
					switch (attrName) {
					case 'min':
					case 'max':
						this.setPositioning();
						break;
					}
				}
			},

			inputChangedCallback: {
				value: function(e) {
					this.setPositioning();
				}
			},

			slideListener: {
				get: function() {
					var timeRangeSlider = this;
					var changingEvent = new CustomEvent('changing', {bubbles: true, cancelable: true});
					var changedEvent = new CustomEvent('changed', {bubbles: true, cancelable: true});

					return {
						handleEvent: function(e) {
							switch (e.type) {
							case 'mousedown':
							case 'touchstart':
								return this.handleDragStartEvent(e);
							case 'mousemove':
							case 'touchmove':
								return this.handleMoveEvent(e);
							case 'mouseup':
							case 'touchend':
								return this.handleDragEndEvent(e);
							default: return;
							}
						},

						handleDragStartEvent: function(e) {
							switch (e.type) {
							case 'mousedown':
								this.moveEventType = 'mousemove';
								this.dragendEventType = 'mouseup';
								this.startPageX = e.pageX
								break;
							case 'touchstart':
								this.moveEventType = 'touchmove';
								this.dragendEventType = 'touchend';
								this.startPageX = e.touches[0].pageX
								break;
							default: return;
							}
							e.preventDefault();
							e.stopPropagation();
							this.target = e.target;
							this.startOffsetLeft = timeRangeSlider.range.offsetLeft;
							this.startClientWidth = timeRangeSlider.range.clientWidth;
							document.addEventListener(this.moveEventType, this);
							document.addEventListener(this.dragendEventType, this);
						},

						handleMoveEvent: function(e) {
							var pageX = null;
							switch (e.type) {
							case 'mousemove':
								pageX = e.pageX
								break;
							case 'touchmove':
								pageX = e.touches[0].pageX
								break;
							default: return;
							}
							e.preventDefault();
							e.stopPropagation();
							var dx = pageX - this.startPageX;
							var containerWidth = timeRangeSlider.rangeContainer.clientWidth;
							var minValue = timeRangeSlider.minValue;
							var maxValue = timeRangeSlider.maxValue;
							switch (this.target) {
							case timeRangeSlider.range:
								var offsetLeft = this.startOffsetLeft + dx;
								offsetLeft = Math.max(offsetLeft, 0);
								offsetLeft = Math.min(offsetLeft, containerWidth - this.startClientWidth);
								var offsetRight = this.startOffsetLeft + this.startClientWidth + dx;
								offsetRight = Math.max(offsetRight, this.startClientWidth);
								var startValue = minValue + (maxValue - minValue) * offsetLeft / containerWidth;
								var endValue = minValue + (maxValue - minValue) * (offsetLeft + this.startClientWidth) / containerWidth;
								timeRangeSlider.startInput.value = timeRangeSlider.formatTime(startValue);
								timeRangeSlider.endInput.value = timeRangeSlider.formatTime(endValue);
								break;
							case timeRangeSlider.leftHandle:
								var offsetLeft = this.startOffsetLeft + dx;
								offsetLeft = Math.max(offsetLeft, 0);
								offsetLeft = Math.min(offsetLeft, this.startOffsetLeft + this.startClientWidth);
								var startValue = minValue + (maxValue - minValue) * offsetLeft / containerWidth;
								timeRangeSlider.startInput.value = timeRangeSlider.formatTime(startValue);
								break;
							case timeRangeSlider.rightHandle:
								var offsetRight = this.startOffsetLeft + this.startClientWidth + dx;
								offsetRight = Math.max(offsetRight, this.startOffsetLeft);
								offsetRight = Math.min(offsetRight, containerWidth);
								var endValue = minValue + (maxValue - minValue) * offsetRight / containerWidth;
								timeRangeSlider.endInput.value = timeRangeSlider.formatTime(endValue);
								break;
							}
							timeRangeSlider.setPositioning();
							timeRangeSlider.dispatchEvent(changingEvent);
						},

						handleDragEndEvent: function(e) {
							switch (e.type) {
							case 'mouseup':
							case 'touchend':
								break;
							default: return;
							}
							e.preventDefault();
							e.stopPropagation();
							document.removeEventListener(this.moveEventType, this);
							document.removeEventListener(this.dragendEventType, this);
							timeRangeSlider.dispatchEvent(changedEvent);
						},
					}
				}
			},

			// Properties

			range: {
				get: function() { return this.rangeContainer.children[0]; }
			},

			handles: {
				get: function() { return this.range.querySelectorAll('div'); }
			},

			leftHandle: {
				get: function() { return this.handles[0]; }
			},

			rightHandle: {
				get: function() { return this.handles[1]; }
			},

			startValue: {
				get: function() { return this.parseTime(this.startInput.value); },
				set: function(value) {
					this.startInput.value = this.formatTime(value);
					this.setPositioning();
				}
			},

			endValue: {
				get: function() { return this.parseTime(this.endInput.value); },
				set: function(value) {
					this.endInput.value = this.formatTime(value);
					this.setPositioning();
				}
			},

			inputs: {
				get: function() { return this.querySelectorAll('input'); }
			},

			startInput: {
				get: function() { return this.inputs[0]; }
			},

			endInput: {
				get: function() { return this.inputs[1]; }
			},

			startPercentage: {
				get: function() {
					return 100 * (this.startValue - this.minValue) / (this.maxValue - this.minValue);
				}
			},

			endPercentage: {
				get: function() {
					return 100 * (this.endValue - this.minValue) / (this.maxValue - this.minValue);
				}
			},

			color: {
				get: function() { return this.getAttribute('color'); }
			},

			// Commands

			setStyle: {
				value: function() {
					this.rangeContainer.style.borderColor = this.borderColor || 'silver';
					this.rangeContainer.style.borderRadius = this.borderRadius;

					this.range.style.backgroundColor = this.color || 'gray';
					this.range.style.borderRadius = this.borderRadius;
					this.setPositioning()
				}
			},

			setPositioning: {
				value: function() {
					this.range.style.left = this.startPercentage + '%';
					this.range.style.width = (this.endPercentage - this.startPercentage) + '%';
				}
			},

		});

		var TimeRangeRuler = document.registerElement('time-range-ruler', {
			prototype: timeRangeRulerPrototype,
		});

		var TimeRangeSlider = document.registerElement('time-range-slider', {
			prototype: timeRangeSliderPrototype,
		});
	})();
</script>
