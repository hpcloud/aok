$().ready(function() {
    $('input').first().focus()

	function getParams() {
		var params = {};

		if (location.search) {
		    var parts = location.search.substring(1).split('&');

		    for (var i = 0; i < parts.length; i++) {
		        var nv = parts[i].split('=');
		        if (!nv[0]) continue;
		        params[nv[0]] = nv[1] || true;
		    }
		}

		return params;
	}

    var params = getParams();
    if ( params['message'] && (params['message'] == 'invalid_credentials') ) {
    	console.log("FAILED LOGIN");
    	$('#invalid_credentials').removeClass('hide');
    }

})

