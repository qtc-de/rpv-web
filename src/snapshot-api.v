module main

import veb


// create_snapshot creates a new RPC snapshot and returns the corresponding
// WebSnapshot struct within the response. This struct represents a full mirror
// of the currently available RPC data and can be later imported back within
// the frontend.
@['/api/snapshot'; get]
pub fn (mut app App) create_snapshot(mut ctx Context) veb.Result
{
	if app.processes.len == 0 || ctx.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return ctx.server_error(app.refresh_error)
		}
	}

	snapshot := app.take_snapshot()
	return ctx.json(snapshot)
}
