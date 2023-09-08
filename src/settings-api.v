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
	if json_body := json2.raw_decode(app.req.data)
	{
		json_map := json_body.as_map()

		if symbol_path := json_map['symbol_path']
		{
		    g_symbol_resolver.symbol_path = symbol_path.str()
		    g_settings.symbol_path = symbol_path.str()
		}
	}

	return app.json(g_settings)
}
