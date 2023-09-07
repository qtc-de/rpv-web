module main

import rpv

// get_process returns the RpvWebProcessInformation associated with
// the specified pid. The pid is looked up in the global process array.
pub fn get_process(pid u32)? RpvWebProcessInformation
{
	for ctr := 0; ctr < g_processes.len; ctr++
	{
		if g_processes[ctr].pid == pid
		{
			return g_processes[ctr]
		}
	}

	return none
}

// get_interface returns the RpvWebInterfaceInfo associated with the
// specified pid und interface uuid. The pid is looked up within the
// global interface array. The uuid is looked up within the rpc_info
// of the corresponding process.
pub fn get_interface(pid u32, uuid string)? RpcWebInterfaceInfo
{
	process := get_process(pid) or
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
pub fn get_rpv_interface(pid u32, uuid string)? rpv.RpcInterfaceInfo
{
	process := get_process(pid) or
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
pub fn take_snapshot() WebSnapshot
{
	mut childs := []u32{cap: g_processes.len}

	for process in g_processes
	{
		for child in process.childs
		{
			childs << child.pid
		}
	}

	mut process_tree := []RpvWebProcessInformation{cap: g_processes.len - childs.len}
	mut idl_data := []WebIdlInterface{cap: g_processes.len}

	for process in g_processes
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
