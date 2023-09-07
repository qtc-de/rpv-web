module main

import vweb
import x.json2

// get_settings returns the currently configured rpv-web settings.
['/api/settings'; get]
pub fn (mut app App) get_settings() vweb.Result
{
	return app.json(g_settings)
}

// set_settings updates the rpv-web settings.
['/api/settings'; post]
pub fn (mut app App) set_settings() vweb.Result
{
	settings := json2.decode[RpvWebSettings](app.req.data) or
	{
		return app.json(g_settings)
	}

	g_symbol_resolver.symbol_path = settings.symbol_path
	g_settings = settings

	return app.json(g_settings)
}
