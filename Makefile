prepublish: time-range-slider.html

%.html: %.html.m4 %.css %.js.base64
	m4 -I $(@D) $< > $@

%.css: %.less
	lessc $< | autoprefixer > $@

%.base64: %
	base64 -i $< -o $@

%.js: %.coffee
	coffee -cs <$< >$@
