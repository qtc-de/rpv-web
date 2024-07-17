module main

import toml
import vweb
import x.json2
import qtc_de.rpv

// update_symbols allows callers to merge an rpv-web symbol file with
// the symbol file that is currently used by the server.
@['/api/symbols'; post]
pub fn (mut app App) update_symbols() vweb.Result
{
	if json_body := json2.raw_decode(app.req.data)
	{
		json_map := json_body.as_map()

		if toml_data := toml.parse_text(json_map['symbols'].str())
		{
			symbol_resolver := rpv.parse_resolver(toml_data, g_symbol_resolver.symbol_path, '')
			g_symbol_resolver.merge(symbol_resolver) or
			{
				return app.server_error(501)
			}

			return app.text('success')

		}
	}

	return app.server_error(501)
}
