// disable console-related code
$().ready(function() {
	function isAbsoluteUrl(url){
		var absolute = RegExp('^(https?:)?//');
		return absolute.test(url)
	}

	function absolutize(url){
		if (isAbsoluteUrl(url)) {
			return url
		} else {
			var base = (/^\//.test(url) ? '' : '/') + $CC_URL;
			return base + url
		}
	}

    $('.stackato_logo').html('<img src="' + absolutize(theme_settings.login_logo) + '">');
})

