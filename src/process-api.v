module main

import veb


// process_refresh can be used to manually trigger a refresh of the cached RPC information.
@['/api/process/refresh'; get]
pub fn (mut app App) process_refresh(mut ctx Context) veb.Result
{
	app.refresh() or
	{
		return ctx.server_error(app.refresh_error)
	}

	return ctx.json(app.processes.len)
}

// process_all returns a list of all RpvWebProcessInformation objects currently stored
// in the global context. If no processes exist yet, the refresh function is called.
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
// The list returned by this API endpoint is flat and does not contain parent-child
// relationships between the different processes.
@['/api/process/all'; get]
pub fn (mut app App) process_all(mut ctx Context) veb.Result
{
	if app.processes.len == 0 || ctx.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return ctx.server_error(app.refresh_error)
		}
	}

	return ctx.json(app.processes)
}

// process_tree returns a tree of all RpvWebProcessInformation objects currently stored
// in the global context. If no processes exist yet, the refresh function is called.
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
//
// The difference to process_all is that the `childs` field of the returned processes
// is populated. Processes listed as child process are no longer contained within the
// toplevel of the tree.
@['/api/process/tree'; get]
pub fn (mut app App) process_tree(mut ctx Context) veb.Result
{
	if app.processes.len == 0 || ctx.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return ctx.server_error(app.refresh_error)
		}
	}

	mut childs := []u32{cap: app.processes.len}

	for process in app.processes
	{
		for child in process.childs
		{
			childs << child.pid
		}
	}

	mut process_tree := []RpvWebProcessInformation{cap: app.processes.len - childs.len}

	for process in app.processes
	{
		if !childs.contains(process.pid)
		{
			process_tree << process
		}
	}

	return ctx.json(process_tree)
}

// process_pid returns an RpvWebProcessInformation that belongs to the requested pid.
// If the target PID does not exist on the system, a 404 error is returned. 
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
@['/api/process/:pid'; get]
pub fn (mut app App) process_pid(mut ctx Context, pid u32) veb.Result
{
	if app.processes.len == 0 || ctx.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return ctx.server_error(app.refresh_error)
		}
	}

	process := app.get_process(pid) or
	{
		ctx.res.set_status(.not_found)
		return ctx.json('')
	}

	return ctx.json(process)
}

// process_interface returns an RpvWebInterfaceInfo that belongs to the requested pid.
// Callers have to specify the interface uuid of the interface they want to obtain.
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
@['/api/process/:pid/:uuid'; get]
pub fn (mut app App) process_interface(mut ctx Context, pid u32, uuid string) veb.Result
{
	if app.processes.len == 0 || ctx.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return ctx.server_error(app.refresh_error)
		}
	}

	intf := app.get_interface(pid, uuid) or
	{
		ctx.res.set_status(.not_found)
		return ctx.json('')
	}

	return ctx.json(intf)
}

// decompile_interface allows callers to decompile the specified RPC interface.
// The interface needs to be specified by it's uuid and the associated pid has
// also to be supplied.
@['/api/process/:pid/:uuid/decompile'; get]
pub fn (app &App) decompile_interface(mut ctx Context, pid u32, uuid string) veb.Result
{
	mut intf := app.get_rpv_interface(pid, uuid) or
	{
		ctx.res.set_status(.not_found)
		return ctx.json('')
	}

	decompiled := intf.decode_all_methods(pid) or
	{
		return ctx.server_error('Decompilation failed.')
	}

	return ctx.text(decompiled.format())
}
