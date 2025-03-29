module main

import veb
import x.json2

// get_settings returns the currently configured rpv-web settings.
@['/api/settings'; get]
pub fn (app &App) get_settings(mut ctx Context) veb.Result
{
	return ctx.json(app.settings)
}

// set_settings updates the rpv-web settings.
@['/api/settings'; post]
pub fn (mut app App) set_settings(mut ctx Context) veb.Result
{
	if json_body := json2.raw_decode(ctx.req.data)
	{
		json_map := json_body.as_map()

		if symbol_path := json_map['symbol_path']
		{
		    app.symbol_resolver.symbol_path = symbol_path.str()
		    app.settings.symbol_path = symbol_path.str()
		}
	}

	return ctx.json(app.settings)
}
