import { defineStore } from 'pinia';
import { parse, stringify } from '@iarna/toml/toml';

var tabs = [];
var processTree = [];

var symbols = {};
var symbolExport = {};
var refreshTimer = 30;
var refreshOngoing = false;

var selectedPane = null;
var selectedProcess = null;
var selectedInterface = null;
var processFilter = null;

export const processStore = defineStore(
{
    id: 'processes',
    state: () => (
    {
        tabs,
        symbols,
        processTree,
        refreshTimer,
        selectedPane,
        symbolExport,
        refreshOngoing,
        selectedProcess,
        selectedInterface,
        processFilter,
    }),

    actions:
    {
        tabExists(name)
        {
            for (const tab of this.tabs)
            {
                if (tab.name == name)
                {
                    return true;
                }
            }

            return false;
        },

        loadSnapshot(name, snapshot)
        {
            if (this.tabExists(name))
            {
                console.log(`Snapshot with name ${name} already exists.`);
                return;
            }

            const snapshotID = crypto.randomUUID();
            this.addSnapshotID(snapshotID, snapshot.processes);

            this.tabs.push(
                {
                    'type': 'snapshot',
                    'snapshotId': snapshotID,
                    'name': name,
                    'data': snapshot
                }
            );

            this.applySymbolsToAll();
        },

        compareSnapshots(name, first, second)
        {
            if (this.tabExists(name))
            {
                console.log(`Snapshot with name ${name} already exists.`);
                return;
            }

            const flat_first = this.flatProcesses(first.processes);
            const flat_second = this.flatProcesses(second.processes);

            let processes = []

            outer:
            for (let process of flat_second)
            {
                for (const other of flat_first)
                {
                    if (process.cmdline == other.cmdline)
                    {
                        const hash_first = this.calcRpcHash(other.rpc_info);
                        const hash_second = this.calcRpcHash(process.rpc_info);

                        if (hash_first != hash_second)
                        {
                            process.changed = true;
                        }

                        continue outer;
                    }
                }

                process.added = true;
                processes.push(process);
            }

            outer2:
            for (let process of flat_first)
            {
                for (const other of flat_second)
                {
                    if (process.cmdline == other.cmdline)
                    {
                        continue outer2;
                    }
                }

                process.removed = true;
                processes.push(process);
            }

            const snapshotID = crypto.randomUUID();

            this.tabs.push(
                {
                    'type': 'snapshot',
                    'snapshotId': snapshotID,
                    'name': name,
                    'data': {
                        'processes': processes,
                        'idl_data': {...first.idl_data, ...second.idl_data}
                    }
                }
            );

            this.applySymbolsToAll();
        },

        async decompile(pid, uuid, snapshotID)
        {
            if (this.tabExists(uuid))
            {
                console.log(`Decompiled IDL for ${uuid} already exists.`);
                return;
            }

            if (snapshotID)
            {
                for (const tab of tabs)
                {
                    if (tab.type === 'snapshot' && tab.snapshotId === snapshotID)
                    {
                        for (const idl of tab.data.idl_data)
                        {
                            if (idl.id === uuid)
                            {
                                this.tabs.push(
                                {
                                    'type': 'idl',
                                    'name': uuid,
                                    'data': idl.code
                                });

                                return;
                            }
                        }
                    }
                }
            }

            fetch(`/api/process/${pid}/${uuid}/decompile`).then( (response) =>
            {
                if (response.ok)
                {
                    response.text().then( (decompiled) =>
                    {
                        this.tabs.push(
                        {
                            'type': 'idl',
                            'name': uuid,
                            'data': decompiled
                        });
                    });
                }

                else
                {
                    console.log("Decompilation failed");
                }
            });
        },

        remove_tab(name)
        {
            for (let ctr = 0; ctr < this.tabs.length; ctr++)
            {
                if (this.tabs[ctr].name == name)
                {
                    this.tabs.splice(ctr, 1);
                    return ctr;
                }
            }
        },

        async updateProcessTree()
        {
            if (import.meta.env.VITE_OFFLINE_MODE != 0)
            {
                console.log('Refresh is disabled when running in offline mode.');
                return;
            }

            if (refreshOngoing)
            {
                console.log('Already refreshing.');
                return;
            }

            refreshOngoing = true;

            fetch('/api/process/tree?refresh=true').then( (response) =>
            {
                if (response.ok)
                {
                    response.json().then( (jsonResponse) =>
                    {
                        this.processTree = jsonResponse;
                        let selectedInterfaceId = null;

                        if (this.selectedInterface != null)
                        {
                            selectedInterfaceId = this.selectedInterface.id;
                        }

                        if (this.selectedProcess != null)
                        {
                            this.selectProcess(this.selectedProcess.pid);
                        }

                        if (selectedInterfaceId != null)
                        {
                            this.selectInterface(selectedInterfaceId);
                        }

                        this.applySymbolsToAll();

                    }).catch( (error) =>
                    {
                        console.log('Error while parsing process tree');
                        console.log(error);
                    });
                }

                else
                {
                    console.log('Failed to retrieve process tree from server.');
                }
            }).finally(() =>
            {
                refreshOngoing = false;
            });
        },

        selectProcess(pid, processes = null)
        {
            if (processes === null)
                processes = this.processTree;

            for (let process of processes)
            {
                if (process.pid == pid)
                {
                    this.selectedProcess = process;
                    this.selectedInterface = null;
                    return true;
                }

                if (process.childs.length > 0)
                {
                    if (this.selectProcess(pid, process.childs))
                        return true;
                }
            }

            return false;
        },

        selectInterface(id, processes = null)
        {
            if (processes === null)
                processes = this.processTree;

            for (let process of processes)
            {
                for (let intfInfo of process.rpc_info.interface_infos)
                {
                    if (intfInfo.id == id)
                    {
                        this.selectedInterface = intfInfo;
                        return true;
                    }
                }

                if (process.childs.length > 0)
                {
                    if (this.selectInterface(id, process.childs))
                        return true;
                }
            }

            return false;
        },

        addSnapshotID(id, processes)
        {
            for (let process of processes)
            {
                process.snapshotID = id;

                if (process.childs.length > 0)
                {
                    this.addSnapshotID(id, process.childs)
                }
            }
        },

        async calcRpcHash(rpc_info)
        {
            let infos = []

            for (const info of rpc_info.interface_infos)
            {
                let clone = structuredClone(info);

                clone.base = "";
                clone.dispatch_table_addr = "";
                clone.sec_callback = "";

                for (let ctr = 0; ctr < clone.methods.length; ctr++)
                {
                    clone.methods[ctr].base = "";
                    clone.methods[ctr].format = "";
                }

                infos.push(clone);
            }

            const intfStr = JSON.stringify({
                'endpoints': rpc_info.server_info.endpoints,
                'auth_info': rpc_info.server_info.auth_info,
                'intf_info': infos
            });

            const msgBuffer = new TextEncoder().encode(intfStr);

            const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
            const hashArray = Array.from(new Uint8Array(hashBuffer));

            const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
            return hashHex;
        },

        flatProcesses(processes)
        {
            let flat = [];

            for (const process of processes)
            {
                flat.push(process);

                if (process.childs)
                {
                    const childs = this.flatProcesses(process.childs);
                    flat = flat.concat(childs);
                }
            }

            return flat;
        },

        loadSymbols(data)
        {
            this.symbols = parse(data);
            this.applySymbolsToAll();
        },

        addCallbackName(callbackName, secCallback)
        {
            if (secCallback.location in this.symbols)
            {
                this.symbols[secCallback.location][secCallback.base] = callbackName;
            }

            else
            {
                this.symbols[secCallback.location] = { [secCallback.base]: callbackName };
            }

            this.applySymbolsToAll();
        },

        addInterfaceName(interfaceName, uuid)
        {
            if (uuid in this.symbols)
            {
                this.symbols[uuid]['name'] = interfaceName;
            }

            else
            {
                this.symbols[uuid] = { name: interfaceName };
            }

            this.applySymbolsToAll();
        },

        addMethodName(methodName, base, location)
        {
            if (location in this.symbols)
            {
                this.symbols[location][base] = methodName;
            }

            else
            {
                this.symbols[location] = { [base]: methodName };
            }

            this.applySymbolsToAll();
        },

        addMethodNotes(methodNotes, index, uuid)
        {
            if (uuid in this.symbols)
            {
                this.symbols[uuid][index] = methodNotes;
            }

            else
            {
                this.symbols[uuid] = { [index]: methodNotes };
            }

            this.applySymbolsToAll();
        },

        addInterfaceNotes(interfaceNotes, uuid)
        {
            if (uuid in this.symbols)
            {
                this.symbols[uuid]['notes'] = interfaceNotes;
            }

            else
            {
                this.symbols[uuid] = { notes: interfaceNotes };
            }

            this.applySymbolsToAll();
        },

        applySymbolsToAll()
        {
            this.applySymbols(this.processTree);

            for (const tab of this.tabs)
            {
                if (tab.type === 'snapshot')
                {
                    this.applySymbols(tab.data.processes);
                }
            }
        },

        applySymbols(tree)
        {
            if (Object.keys(this.symbols).length === 0)
            {
                return;
            }

            for (const process of this.flatProcesses(tree))
            {
                for (const info of process.rpc_info.interface_infos)
                {
                    if (info.id in this.symbols)
                    {
                        if ('name' in this.symbols[info.id])
                        {
                            info.name = this.symbols[info.id].name;
                        }

                        if ('notes' in this.symbols[info.id])
                        {
                            info.notes = this.symbols[info.id].notes;
                        }

                        for (let ctr = 0; ctr < info.methods.length; ctr++)
                        {
                            if (ctr in this.symbols[info.id])
                            {
                                info.methods[ctr].notes = this.symbols[info.id][ctr];
                            }
                        }
                    }

                    if (info.location in this.symbols)
                    {
                        for (const method of info.methods)
                        {
                            if (method.base in this.symbols[info.location])
                            {
                                method.name = this.symbols[info.location][method.base];
                            }
                        }
                    }

                    if (info.sec_callback.location in this.symbols)
                    {
                        if (info.sec_callback.base in this.symbols[info.sec_callback.location])
                        {
                            info.sec_callback.name = this.symbols[info.sec_callback.location][info.sec_callback.base];
                        }
                    }
                }
            }
        },

        exportSymbols()
        {
            return stringify(this.symbols);
        },
    }
})
