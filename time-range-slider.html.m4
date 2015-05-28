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
<script src="data:application/javascript;base64,include(`time-range-slider.js.base64')"></script>
