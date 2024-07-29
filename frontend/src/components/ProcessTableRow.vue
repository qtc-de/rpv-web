<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'

    export default {
        props: ['process', 'indent', 'filter'],

        data()
        {
            return {
                hideChilds: false
            }
        },

        setup()
        {
            const store = processStore();
            const { selectedProcess, selectedInterface } = storeToRefs(store)
            return { selectedProcess, selectedInterface }
        },

        methods:
        {
            selectRow(process)
            {
                this.selectedProcess = process;
                this.selectedInterface = null;
            },

            listFilter(list, filter, lambda = (item) => item)
            {
                for (const item of list)
                {
                    var mod = lambda(item);

                    if (mod.toLowerCase().includes(filter))
                    {
                        return true;
                    }
                }

                return false;
            },

            methodFilter(process, filter)
            {
                const interfaces =  process.rpc_info.interface_infos;

                for (const intf of interfaces)
                {
                    if (this.listFilter(intf.methods, filter, (item) => item.name))
                    {
                        return true;
                    }
                }

                return false;
            },

            endpointFilter(process, filter)
            {
                const endpoints =  process.rpc_info.server_info.endpoints;
                return this.listFilter(endpoints, filter, (item) => `${item.protocol}:${item.name}`);
            },

            casualFilter(process, filter)
            {
                let inverse = false;

                if (filter.startsWith('!'))
                {
                    filter = filter.substring(1);
                    inverse = true;
                }

                return (process.path.toLowerCase().includes(filter) || process.cmdline.toLowerCase().includes(filter) ||
                        process.user.toLowerCase().includes(filter) || process.pid == filter || this.endpointFilter(process, filter) ||
                        this.methodFilter(process, filter)) != inverse;
            },

            applyFilter(filter, process)
            {
                if (filter)
                {
                    filter = filter.toLowerCase();

                    if (!filter.includes(':') && !this.casualFilter(process, filter))
                    {
                        return false;
                    }

                    else
                    {
                        const filterArray = filter.split(/\s*\|\s*/);

                        for (const entry of filterArray)
                        {
                            let key, value;
                            let inverse = false;

                            [key, value] = entry.split(':', 2);
                            
                            if (key === 'uuid')
                            {
                                key = 'id';
                            }

                            if (value === undefined)
                            {
                                if (!this.casualFilter(process, key))
                                {
                                    return false;
                                }

                                continue;
                            }

                            if (value.startsWith('!'))
                            {
                                value = value.substring(1);
                                inverse = true;
                            }

                            let propValue = null;

                            if (Object.hasOwn(process, key))
                            {
                                propValue = process[key];
                            }

                            else if (Object.hasOwn(process.rpc_info.server_info, key))
                            {
                                propValue = process.rpc_info.server_info[key];

                                if (key === 'endpoints')
                                {
                                    propValue = [];

                                    for (const endpoint of process.rpc_info.server_info[key])
                                    {
                                        propValue.push(`${endpoint.protocol}:${endpoint.name}`);
                                    }
                                }
                            }

                            else if (process.rpc_info.interface_infos.length > 0)
                            {
                                if (Object.hasOwn(process.rpc_info.interface_infos[0], key))
                                {
                                    propValue = [];

                                    for (const intf of process.rpc_info.interface_infos)
                                    {
                                        if (key === 'methods')
                                        {
                                            propValue = propValue.concat(intf.methods.flatMap((method) => method.name));
                                        }

                                        else
                                        {
                                            propValue.push(intf[key]);
                                        }
                                    }
                                }
                            }

                            else
                            {
                                return false;
                            }

                            if (propValue !== null)
                            {
                                if (Array.isArray(propValue) && propValue.length > 0)
                                {
                                    let found = false;

                                    for (const item of propValue)
                                    {
                                        if (String(item).toLowerCase().includes(value))
                                        {
                                            found = true;
                                            break;
                                        }
                                    }

                                    if (!found != inverse)
                                    {
                                        return false;
                                    }
                                }

                                else
                                {
                                    if (String(propValue).toLowerCase().includes(value) == inverse)
                                    {
                                        return false;
                                    }
                                }
                            }
                        }
                    }
                }

                return true;
            }
        },
    }
</script>

<template>
    <tr :id="`ProcessTableRow${process.pid}`" v-if="applyFilter(filter, process)" @click='selectRow(process)' :class="{ Selected: (selectedProcess && selectedProcess.pid == process.pid),
        Rpc: process.rpc_info.rpc_type == 'rpc', Dcom: process.rpc_info.rpc_type == 'dcom', Hybrid: process.rpc_info.rpc_type == 'hybrid', WrongArch: process.rpc_info.rpc_type ==
        'wrong_arch', 'Added': process.added, 'Changed': process.changed, 'Removed': process.removed }">
        <td class="ProcessTableData pr-7" :style="`text-indent: ${indent}px;`">
            <button class="ChildButton d-inline-block" v-if="process.childs.length > 0 && !hideChilds" @click="hideChilds = true">-</button>
            <button class="ChildButton d-inline-block" v-else-if="process.childs.length > 0 && hideChilds" @click="hideChilds = false">+</button>
            <div class="ChildIcon d-inline-block" v-else></div>
            <img class="ProcessIcon" v-if="process.icon && process.icon.startsWith('Qk')" :src="`data:image/bmp;base64,${process.icon}`" />
            <div class="ProcessIcon d-inline-block" v-else></div>
            {{process.name}}
        </td>
        <td class="ProcessTableData pr-7">{{process.pid}}</td>
        <td class="ProcessTableData pr-7">{{process.user}}</td>
        <td class="ProcessTableData pr-7">{{process.path}}</td>
        <td class="ProcessTableData pr-7">{{process.cmdline}}</td>
    </tr>
    <ProcessTableRow v-if="!hideChilds || filter" v-for="child in process.childs" :process="child" :indent="Number(indent) + 20" :filter="filter"/>
</template>

<style>
    .ProcessIcon {
        height: 15px;
        width: 15px;
        vertical-align: middle;
    }

    .ChildIcon {
        height: 10px;
        width: 10px;
        margin-right: 3px;
    }

    .ChildButton {
        height: 10px;
        width: 10px;
        font-size: 10px;
        text-align: center;
        line-height: 5px;
        vertical-align: middle;
        background-color: darkgrey;
        margin-right: 3px;
        padding: 0;
    }

    .ProcessTableData {
        padding-top: 2px;
        vertical-align: middle;
        cursor: pointer;
    }

    .Added {
        border: solid 3px;
        border-color: green;
    }

    .Changed {
        border: solid 3px;
        border-color: orange;
    }

    .Removed {
        border: solid 3px;
        border-color: red;
    }
</style>
