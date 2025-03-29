module main

import veb
import toml
import x.json2
import qtc_de.rpv

// update_symbols allows callers to merge an rpv-web symbol file with
// the symbol file that is currently used by the server.
@['/api/symbols'; post]
pub fn (mut app App) update_symbols(mut ctx Context) veb.Result
{
	if json_body := json2.raw_decode(ctx.req.data)
	{
		json_map := json_body.as_map()

		if toml_data := toml.parse_text(json_map['symbols'].str())
		{
			symbol_resolver := rpv.parse_resolver(toml_data, app.symbol_resolver.symbol_path, '')
			app.symbol_resolver.merge(symbol_resolver) or
			{
				return ctx.server_error('Merging resolvers failed.')
			}

			return ctx.text('success')

		}
	}

	return ctx.server_error('Unexpected error.')
}
