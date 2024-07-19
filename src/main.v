module main

import os
import json
import vweb
import time
import qtc_de.rpv
import qtc_de.rpv.win
import cli { Command, Flag }

// In the current state of vweb, we have to use globals to track our
// in memory state. Tracking this state within the App context does
// currently not work correctly. Using a dedicated solution like an
// sqlite database seems to be an overkill. Therefore, we use globals
// as a temporary workaround.
__global (
	g_icon_cache win.IconCache
	g_settings RpvWebSettings
	g_processes []RpvWebProcessInformation
	g_symbol_resolver rpv.SymbolResolver
)

struct App {
	vweb.Context
}

struct RpvWebSettings {
	symbol_file string
	mut:
	symbol_path string
}

pub fn (app App) before_request()
{
	println('[web] Incoming request: ${app.req.method} ${app.req.url}')
}

fn main()
{
	mut app := &App{}

	app.serve_static('/favicon.ico', 'dist/favicon.ico')
	app.serve_static('/', 'dist/index.html')
	app.handle_static('dist', true)

	mut cmd := cli.Command
	{
		name: 'rpv-web'
		description: 'An API interface to rpv'
		version: '1.0.0'
		execute: fn [mut app] (cmd cli.Command)!
		{
			snapshot := cmd.flags.get_bool('snapshot') or { false }
			symbol_file := cmd.flags.get_string('symbol-file') or { 'rpv-web-symbols.toml' }
			pdb_path := cmd.flags.get_string('pdb-path') or { '' }

			g_settings = RpvWebSettings { symbol_file: symbol_file, symbol_path: pdb_path }
			g_symbol_resolver = rpv.new_resolver(g_settings.symbol_file, g_settings.symbol_path) or
			{
				eprintln('[-] Unable to initialize global symbol resolver: ${err}')
				return
			}

			if snapshot
			{
				println('[+] Refreshing RPC processes list.')

				app.refresh() or
				{
					eprintln('[-] Unable to obtain RPC processes.')
					return
				}

				println('[+] Taking a snapshot.')
				snap := take_snapshot()

				filename := '${time.now().strftime('%Y.%m.%d-%H.%M')}-rpv-web-snapshot.json'
				println('[+] Writing result to ${filename}.')

				os.write_file(filename, json.encode(snap)) or
				{
					eprintln('[-] Unable to write file ${filename}.')
				}
			}

			else
			{
				port := cmd.flags.get_int('port') or { 8000 }
				vweb.run(app, port)
			}
		}
	}

	cmd.add_flag(Flag{
		flag: .bool
		name: 'snapshot'
		description: 'create a snapshot instead of starting the API server'
	})

	cmd.add_flag(Flag{
		flag: .int
		name: 'port'
		abbrev: 'p'
		default_value: ['8000']
		description: 'port to start the API server on'
	})

	cmd.add_flag(Flag{
		flag: .string
		name: 'symbol-file'
		default_value: ['rpv-web-symbols.toml']
		description: 'path to the rpv symbol file to use'
	})

	cmd.add_flag(Flag{
		flag: .string
		name: 'pdb-path'
		description: 'path to a folder containing pdb files'
	})

	cmd.setup()
	cmd.parse(os.args)
}
