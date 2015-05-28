Demo
----

	npm install
	python -m SimpleHTTPServer

... and open [the demo][].

Reuse
-----

	npm install time-range-slider

And include like this:

	<script src="node_modules/webcomponents.js/webcomponents.js"></script>
	<link rel="import" href="node_modules/time-range-slider/time-range-slider.html">
	<time-range-ruler min="8:15" max="19:00" border-color="darkblue"></time-range-ruler>
	<time-range-slider min="8:15" max="19:00" color="lightblue" border-color="darkblue" border-radius="6px">
		<input type="text" name="start" value="9:00">
		<input type="text" name="end" value="18:00">
	</time-range-slider>

For more details, see [the demo][].

Caveats
-------

- In general, the `input`s inside the slider's light DOM are considered internal, so access/modify them only through `time-range-slider` methods
- To programmatically change the values of the inputs, use e.g. `slider.startValue = slider.parseTime('11:00')`. See [issue 3][] for more details.

[the demo]: http://localhost:8000/demo/
[issue 3]: https://github.com/webthusiast/time-range-slider/issues/3
