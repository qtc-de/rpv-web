module main

import os
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

	if !C.EnumProcesses(pids.data, u32(pids.cap) * sizeof(u32), &arr_size)
	{
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

		for mut web_info in app.processes
		{
			if web_info.pid == pid
			{
				web_info.rpv_info.update(mut app.symbol_resolver) or { break }
				rpv_infos << web_info.rpv_info
				continue pid_loop
			}
		}

		if rpv_process_info := rpv.get_rpv_process_info(pid, mut app.symbol_resolver)
		{
			rpv_infos << rpv_process_info
		}
	}

	app.processes.clear()

	for info in rpv_infos
	{
		app.processes << convert_rpv_process_info(info, mut app.icon_cache, app.symbol_resolver)
	}

	for child in app.processes
	{
		for mut parent in app.processes
		{
			if child.ppid == parent.pid
			{
				parent.childs << child
			}
		}
	}
}

// get_process returns the RpvWebProcessInformation associated with
// the specified pid. The pid is looked up in the global process array.
pub fn (app &App) get_process(pid u32)? RpvWebProcessInformation
{
	for ctr := 0; ctr < app.processes.len; ctr++
	{
		if app.processes[ctr].pid == pid
		{
			return app.processes[ctr]
		}
	}

	return none
}

// get_interface returns the RpvWebInterfaceInfo associated with the
// specified pid und interface uuid. The pid is looked up within the
// global interface array. The uuid is looked up within the rpc_info
// of the corresponding process.
pub fn (app &App) get_interface(pid u32, uuid string)? RpcWebInterfaceInfo
{
	process := app.get_process(pid) or
	{
		return none
	}

	for ctr := 0; ctr < process.rpc_info.interface_infos.len; ctr++
	{
		if process.rpc_info.interface_infos[ctr].id == uuid
		{
			return process.rpc_info.interface_infos[ctr]
		}
	}

	return none
}

// get_rpv_interface returns the rpv.RpcInterfaceInfo that is associated
// with the specified pid and interface uuid. rpv.RpcInterfaceInfo contains
// the full low level details of the RpcServer and can be used to e.g.
// decompile the available functions. However, it should not be returned
// within webserver responses, as it contains binary data.
pub fn (app &App) get_rpv_interface(pid u32, uuid string)? rpv.RpcInterfaceInfo
{
	process := app.get_process(pid) or
	{
		return none
	}

	for ctr := 0; ctr < process.rpv_info.rpc_info.interface_infos.len; ctr++
	{
		if process.rpv_info.rpc_info.interface_infos[ctr].id == uuid
		{
			return process.rpv_info.rpc_info.interface_infos[ctr]
		}
	}

	return none
}


// take_snapshot iterates over all objects within the global process array to
// calculate their child relationship and to decompile their RPC interfaces.
// All this information is stored in a WebSnapshot struct that is returned to
// the caller.
pub fn (app &App) take_snapshot() WebSnapshot
{
	mut childs := []u32{cap: app.processes.len}

	for process in app.processes
	{
		for child in process.childs
		{
			childs << child.pid
		}
	}

	mut process_tree := []RpvWebProcessInformation{cap: app.processes.len - childs.len}
	mut idl_data := []WebIdlInterface{cap: app.processes.len}

	for process in app.processes
	{
		if !childs.contains(process.pid)
		{
			process_tree << process
		}

		for intf_info in process.rpv_info.rpc_info.interface_infos
		{
			midl_interface := intf_info.decode_all_methods(process.pid) or { continue }
			idl_data << convert_rpv_midl_interface(midl_interface)
		}
	}

	return WebSnapshot {
		processes: process_tree
		idl_data: idl_data
	}
}
