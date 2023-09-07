module main

import os
import vweb
import qtc_de.rpv


// refresh obtains RPC information for currently running processes and stores
// them within the internal context. If RPC information is already available, the
// method attempts first to renew the already existing RPC info instead of requesting
// new data.
//
// The method obtains a list of currently running process ids and iterates over them.
// For each PID where an RpvProcessInformation is already present, it calls the update
// method. For other processes, RpvProcessInformation is obtained via get_rpv_process_info.
//
// The method uses a global context and is currently not thread safe.
fn (mut app App) refresh()!
{
	self_pid := os.getpid()

	arr_size := u32(0)
	mut pids := []u32{len: 1024}

	if !C.EnumProcesses(pids.data, u32(pids.cap) * sizeof(u32), &arr_size) {
		return error('Failed to enumerate processes.')
	}

	pids.trim(int(arr_size / sizeof(u32)))
	mut rpv_infos := []rpv.RpvProcessInformation{cap: int(arr_size / sizeof(u32)) - 1}

	pid_loop:
	for pid in pids
	{
		if pid == self_pid
		{
			continue
		}

		for mut web_info in g_processes
		{
			if web_info.pid == pid
			{
				web_info.rpv_info.update(mut g_symbol_resolver) or { break }
				rpv_infos << web_info.rpv_info
				continue pid_loop
			}
		}

		if rpv_process_info := rpv.get_rpv_process_info(pid, mut g_symbol_resolver)
		{
			rpv_infos << rpv_process_info
		}
	}

	g_processes.clear()

	for info in rpv_infos
	{
		g_processes << convert_rpv_process_info(info, mut g_icon_cache)
	}

	for child in g_processes
	{
		for mut parent in g_processes
		{
			if child.ppid == parent.pid
			{
				parent.childs << child
			}
		}
	}
}

// process_refresh can be used to manually trigger a refresh of the cached RPC information.
['/api/process/refresh'; get]
pub fn (mut app App) process_refresh() vweb.Result
{
	app.refresh() or {
		return app.server_error(501)
	}

	return app.json(g_processes.len)
}

// process_all returns a list of all RpvWebProcessInformation objects currently stored
// in the global context. If no processes exist yet, the refresh function is called.
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
// The list returned by this API endpoint is flat and does not contain parent-child
// relationships between the different processes.
['/api/process/all'; get]
pub fn (mut app App) process_all() vweb.Result
{
	if g_processes.len == 0 || app.query['refresh'] == 'true' {
		app.refresh() or {
			return app.server_error(501)
		}
	}

	return app.json(g_processes)
}

// process_tree returns a tree of all RpvWebProcessInformation objects currently stored
// in the global context. If no processes exist yet, the refresh function is called.
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
//
// The difference to process_all is that the `childs` field of the returned processes
// is populated. Processes listed as child process are no longer contained within the
// toplevel of the tree.
['/api/process/tree'; get]
pub fn (mut app App) process_tree() vweb.Result
{
	if g_processes.len == 0 || app.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return app.server_error(501)
		}
	}

	mut childs := []u32{cap: g_processes.len}

	for process in g_processes
	{
		for child in process.childs
		{
			childs << child.pid
		}
	}

	mut process_tree := []RpvWebProcessInformation{cap: g_processes.len - childs.len}

	for process in g_processes
	{
		if !childs.contains(process.pid)
		{
			process_tree << process
		}
	}

	return app.json(process_tree)
}

// process_pid returns an RpvWebProcessInformation that belongs to the requested pid.
// If the target PID does not exist on the system, a 404 error is returned. 
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
['/api/process/:pid'; get]
pub fn (mut app App) process_pid(pid u32) vweb.Result
{
	if g_processes.len == 0 || app.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return app.server_error(501)
		}
	}

	process := get_process(pid) or
	{
		app.set_status(404, 'Not Found')
		return app.json('')
	}

	return app.json(process)
}

// process_interface returns an RpvWebInterfaceInfo that belongs to the requested pid.
// Callers have to specify the interface uuid of the interface they want to obtain.
// Callers can use the `refresh=true` query parameter to enforce a refresh of RPC data.
['/api/process/:pid/:uuid'; get]
pub fn (mut app App) process_interface(pid u32, uuid string) vweb.Result
{
	if g_processes.len == 0 || app.query['refresh'] == 'true'
	{
		app.refresh() or
		{
			return app.server_error(501)
		}
	}

	intf := get_interface(pid, uuid) or
	{
		app.set_status(404, 'Not Found')
		return app.json('')
	}

	return app.json(intf)
}

// decompile_interface allows callers to decompile the specified RPC interface.
// The interface needs to be specified by it's uuid and the associated pid has
// also to be supplied.
['/api/process/:pid/:uuid/decompile'; get]
pub fn (mut app App) decompile_interface(pid u32, uuid string) vweb.Result
{
	mut intf := get_rpv_interface(pid, uuid) or {
		app.set_status(404, 'Not Found')
		return app.json('')
	}

	decompiled := intf.decode_all_methods(pid) or {
		return app.server_error(501)
	}

	return app.text(decompiled.format())
}
