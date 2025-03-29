module main

import os
import veb
import json
import time
import qtc_de.rpv
import qtc_de.rpv.win
import cli { Command, Flag }


pub struct Context
{
	veb.Context
}

pub struct App
{
	veb.StaticHandler
	veb.Middleware[Context]
pub mut:
	refresh_error		string = 'Error while refreshing the process list.'
	icon_cache			win.IconCache
	settings			RpvWebSettings
	processes			[]RpvWebProcessInformation
	symbol_resolver		rpv.SymbolResolver
}

struct RpvWebSettings
{
	symbol_file string
mut:
	symbol_path string
}

pub fn before_request(mut ctx Context)
{
    println('[web] Incoming request: ${ctx.req.method} ${ctx.req.url}')
}

fn main()
{
	mut app := &App{}
	app.use(handler: before_request)

	app.serve_static('/favicon.ico', 'dist/favicon.ico') or
	{
		eprintln('[-] Unable to serve favicon.ico')
		return
	}

	app.serve_static('/', 'dist/index.html') or
	{
		eprintln('[-] Unable to serve index.html')
		return
	}

	app.handle_static('dist', true) or
	{
		eprintln('[-] Unable to serve dist folder')
		return
	}

	mut cmd := cli.Command
	{
		name: 'rpv-web'
		description: 'An web API interface to rpv'
		version: '1.4.0'
		execute: fn [mut app] (cmd cli.Command)!
		{
			snapshot := cmd.flags.get_bool('snapshot') or { false }
			symbol_file := cmd.flags.get_string('symbol-file') or { 'rpv-web-symbols.toml' }
			pdb_path := cmd.flags.get_string('pdb-path') or { '' }

			app.settings = RpvWebSettings { symbol_file: symbol_file, symbol_path: pdb_path }
			app.symbol_resolver = rpv.new_resolver(app.settings.symbol_file, app.settings.symbol_path) or
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
				snap := app.take_snapshot()

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
				host := cmd.flags.get_string('host') or { 'localhost' }

				veb.run_at[App, Context](mut app, veb.RunParams{ host: host, port: port, family: .ip }) or
				{
					eprintln('[-] Unable to start the web server on ${host}:${port}.')
				}
			}
		}
	}

	cmd.add_flag(Flag{
		flag: .bool
		name: 'snapshot'
		description: 'create a snapshot instead of starting the API server'
	})

	cmd.add_flag(Flag{
		flag: .string
		name: 'host'
		abbrev: 'h'
		default_value: ['localhost']
		description: 'ip address to listen on'
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
