module main

import vweb

// WebSnapshot helper struct that contains all available RpvWebProcessInformation
// and all WebIdlInterface structs.
struct WebSnapshot {
	processes []RpvWebProcessInformation
	idl_data []WebIdlInterface
}


// create_snapshot creates a new RPC snapshot and returns the corresponding
// WebSnapshot struct within the response. This struct represents a full mirror
// of the currently available RPC data and can be later imported back within
// the frontend.
@['/api/snapshot'; get]
pub fn (mut app App) create_snapshot() vweb.Result
{
	if g_processes.len == 0 || app.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return app.server_error(501)
		}
	}

	snapshot := take_snapshot()
	return app.json(snapshot)
}
