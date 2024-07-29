module main

import qtc_de.rpv
import qtc_de.rpv.win

// For the json output generated by rpv-web we use v's native json module.
// The rpv structures contain to many non printable data that needs to be
// stripped. For this purpose, we redeclare some structure for rpv-web. This
// file contains the code to transform the structures from one to the other.

// RpvWebProcessInformation is the rpv-web version of RpvProcessInformation
// The main differences are that the rpc_info field is now of type RpcWebInfo
// and that the childs field contains all the processes childs as structs.
// The structure also contains the original rpv.RpcInfo struct in case one needs
// access to more detailed RPC data. However, this structure is excluded from
// the json output.
@[heap]
struct RpvWebProcessInformation {
	pub:
	pid		u32
	ppid	u32
	name	string
	path	string
	cmdline string
	user	string
	version u64
	icon    string
	desc	string
	rpc_info RpcWebInfo
	mut:
	rpv_info rpv.RpvProcessInformation @[skip]
	childs  []RpvWebProcessInformation
}

// RpcWebInfo is the rpv-web version of RpcInfo. All fields from the corresponding
// rpv type are replaced with rpv-web versions except of rpc_type which contains
// the original rpv.RpcType value.
@[heap]
struct RpcWebInfo {
	pub:
	server_info RpcWebServerInfo
	interface_infos []RpcWebInterfaceInfo
	rpc_type rpv.RpcType
}

// RpcWebServerInfo is the rpv-web version of RpcServerInfo. Fields contained in
// this structure were reduced to the one that are displayed within the graphical
// user interface. Binary types like pointers were converted to strings.
@[heap]
struct RpcWebServerInfo {
	pub:
	base string
	out_calls u32
	in_calls u32
	in_packets u32
	out_packets u32
	intf_count int
	auth_info []RpcWebAuthInfo
	endpoints []rpv.RpcEndpoint
}

// RpcWebInterfaceInfo is the rpv-web version of RpcInterfaceInfo. Fields contained in
// this structure were reduced to the one that are displayed within the graphical
// user interface. Binary types like pointers were converted to strings.
@[heap]
struct RpcWebInterfaceInfo {
	pub:
	id string
	version string
	base string
	dispatch_table_addr string
	annotation string
	location string
	module_base string
	description string
	ep_registered bool
	ndr_info WebNdrInfo
	typ rpv.RpcType
	methods []RpcWebMethod
	flags []string
	mut:
	name string
	notes string
	sec_callback WebSecurityCallback
}

// RpcWebMethod is the rpv-web version of rpv.RpcMethod. Fields contained in
// this structure were reduced to the one that are displayed within the graphical
// user interface.
@[heap]
struct RpcWebMethod {
	addr string
	offset string
	fmt string
	mut:
	name string
	notes string
}

// RpcWebAuthInfo is the rpv-web version of RpcAuthInfo. Fields contained in
// this structure were reduced to the one that are displayed within the graphical
// user interface.
@[heap]
struct RpcWebAuthInfo {
	principal string
	name string
	dll string
}

// WebNdrInfo is the rpv-web version of NdrInfo. Fields contained in
// this structure were reduced to the one that are displayed within the graphical
// user interface.
@[heap]
struct WebNdrInfo {
	ndr_version u32
	midl_version u32
	flags []string
	syntax string
}

// WebSecurityCallback is the rpv-web version of SecurityCallback. Fields contained in
// this structure were reduced to the one that are displayed within the graphical
// user interface.
@[heap]
struct WebSecurityCallback {
	addr string
	offset string
	location string
	description string
	mut:
	name string
}

// WebIdlInterface is the rpv-web version of MidlInterface. Fields contained in
// this structure were reduced to the one that are displayed within the graphical
// user interface.
@[heap]
struct WebIdlInterface {
	id string
	name string
	version string
	code string
}

// convert_rpv_process_info converts an rpv.RpvProcessInformation structure to the
// corresponding RpvWebProcessInformation structure.
fn convert_rpv_process_info(info rpv.RpvProcessInformation, mut icon_cache win.IconCache) RpvWebProcessInformation
{
	return RpvWebProcessInformation {
		pid:	info.pid
		ppid:	info.ppid
		name:	info.name
		path:	info.path
		cmdline: info.cmdline
		user:	info.user
		version: info.version
		icon:   icon_cache.get(info.path) or { '' }
		desc:	info.desc
		rpc_info: RpcWebInfo {
			server_info: convert_rpv_server_info(info.rpc_info.server_info)
			interface_infos: convert_rpv_interface_infos(info.rpc_info.interface_infos)
			rpc_type: info.rpc_info.rpc_type
		}
		rpv_info: info
		childs: []RpvWebProcessInformation{cap: info.childs.len}
	}
}

// convert_rpv_server_info converts an rpv.RpvServerInfo structure to the corresponding
// RpvWebServerInfo structure.
fn convert_rpv_server_info(info rpv.RpcServerInfo) RpcWebServerInfo {
	return RpcWebServerInfo {
		base: '0x${info.base.hex_full()}'
		out_calls: info.server.out_calls
		in_calls: info.server.in_calls
		in_packets: info.server.in_packets
		out_packets: info.server.out_packets
		intf_count: info.intf_count
		auth_info: convert_rpv_auth_infos(info.auth_infos)
		endpoints: info.endpoints
	}
}

// convert_rpv_auth_infos converts a list of rpv.RpcAuthInfo structs into a list of
// RpcWebAuthInfo structs.
fn convert_rpv_auth_infos(infos []rpv.RpcAuthInfo) []RpcWebAuthInfo {
	mut rpv_web_auth_infos := []RpcWebAuthInfo{cap: infos.len}

	for info in infos {
		rpv_web_auth_infos << RpcWebAuthInfo {
			principal: info.principal
			name: info.package.name
			dll: info.dll
		}
	}

	return rpv_web_auth_infos
}

// convert_rpv_interface_infos converts a list of rpv.RpcInterfaceInfo structs into a
// list of RpcWebInterfaceInfo structs
fn convert_rpv_interface_infos(infos []rpv.RpcInterfaceInfo) []RpcWebInterfaceInfo
{
	mut rpv_web_intf_infos := []RpcWebInterfaceInfo{cap: infos.len}

	for info in infos
	{
		mut rpc_flags := []string{cap: 6}

		if info.intf.flags & u32(C.RPC_IF_ALLOW_CALLBACKS_WITH_NO_AUTH) != 0
		{
			rpc_flags << 'RPC_IF_ALLOW_CALLBACKS_WITH_NO_AUTH'
		}

		if info.intf.flags & u32(C.RPC_IF_ALLOW_LOCAL_ONLY) != 0
		{
			rpc_flags << 'RPC_IF_ALLOW_LOCAL_ONLY'
		}

		if info.intf.flags & u32(C.RPC_IF_AUTOLISTEN) != 0
		{
			rpc_flags << 'RPC_IF_AUTOLISTEN'
		}

		if info.intf.flags & u32(C.RPC_IF_OLE) != 0
		{
			rpc_flags << 'RPC_IF_OLE'
		}

		if info.intf.flags & u32(C.RPC_IF_ALLOW_SECURE_ONLY) != 0
		{
			rpc_flags << 'RPC_IF_ALLOW_SECURE_ONLY'
		}

		if info.intf.flags & u32(C.RPC_IF_SEC_NO_CACHE) != 0
		{
			rpc_flags << 'RPC_IF_SEC_NO_CACHE'
		}

		rpv_web_intf_infos << RpcWebInterfaceInfo {
			id: info.id
			version: info.version
			base: '0x${info.base.hex_full()}'
			name: info.name
			dispatch_table_addr: '0x${info.dispatch_table_addr.hex_full()}'
			annotation: info.annotation
			location: info.location.path
			module_base: '0x${info.location.base.hex_full()}'
			description: info.location.desc
			ep_registered: info.ep_registered
			sec_callback: convert_rpv_security_callback(info.sec_callback)
			typ: info.typ
			ndr_info: convert_rpv_ndr_info(info.ndr_info)
			methods: convert_rpv_rpc_methods(info.id, info.methods)
			flags: rpc_flags
			notes: g_symbol_resolver.load_uuid_notes(info.id) or { '' }
		}
	}

	return rpv_web_intf_infos
}

// convert_rpv_ndr_info converts an rpv.NdrInfo struct in WebNdrInfo
fn convert_rpv_ndr_info(info rpv.NdrInfo) WebNdrInfo
{
	mut flag_str := []string{cap: 3}

	if info.flags & usize(C.RPCFLG_HAS_MULTI_SYNTAXES) != 0 {
		flag_str << "RPCFLG_HAS_MULTI_SYNTAXES"
	}

	if info.flags & usize(C.RPCFLG_HAS_CALLBACK) != 0 {
		flag_str << "RPCFLG_HAS_CALLBACK"
	}

	if info.flags & usize(C.RPC_INTERFACE_HAS_PIPES) != 0 {
		flag_str << "RPC_INTERFACE_HAS_PIPES"
	}

	return WebNdrInfo {
		ndr_version: info.ndr_version
		midl_version: info.midl_version
		flags: flag_str
		syntax: info.syntax
	}
}

// convert_rpv_rpc_method converts an rpv.RpcMethod struct in RpcWebMethod
fn convert_rpv_rpc_methods(intf_id string, methods []rpv.RpcMethod) []RpcWebMethod
{
	mut index := 0
	mut web_methods := []RpcWebMethod{cap: methods.len}

	for method in methods {
		web_methods << RpcWebMethod {
			addr: '0x${method.addr.hex_full()}'
			offset: '0x${method.offset.hex_full()}'
			fmt: '0x${method.fmt.hex_full()}'
			name: method.name
			notes: g_symbol_resolver.load_uuid_method_notes(intf_id, index.str()) or { '' }
		}

		index++
	}

	return web_methods
}

// convert_rpv_security_callback converts an rpv.SecurityCallback struct to WebSecurityCallback
fn convert_rpv_security_callback(callback rpv.SecurityCallback) WebSecurityCallback
{
	return WebSecurityCallback {
		addr: '0x${callback.addr.hex_full()}'
		offset: '0x${callback.offset.hex_full()}'
		name: callback.name
		location: callback.location.path
		description: callback.location.desc
	}
}

// convert_rpv_midl_interface converts an rpv.MidlInterface struct to WebIdlInterface
fn convert_rpv_midl_interface(midl rpv.MidlInterface) WebIdlInterface
{
	return WebIdlInterface
	{
		id: midl.id
		name: midl.name
		version: midl.version
		code: midl.format()
	}
}
