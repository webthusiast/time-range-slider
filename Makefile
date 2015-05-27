prepublish: time-range-slider.html

%.html: %.html.m4 %.css
	m4 -I $(@D) $< > $@

%.css: %.less
	lessc $< | autoprefixer > $@
