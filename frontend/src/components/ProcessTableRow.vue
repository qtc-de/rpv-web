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

            applyFilter(filter, process)
            {
                if (!filter)
                {
                    return true;
                }

                filter = filter.toLowerCase();

                if (!filter.includes(':'))
                {
                    return process.path.toLowerCase().includes(filter) || process.cmdline.toLowerCase().includes(filter) ||
                           process.user.toLowerCase().includes(filter) || process.pid == filter;
                }

                let result = true;
                const filterArray = filter.split(/\s*\|\s*/);

                for (const entry of filterArray)
                {
                    let key, value;
                    [key, value] = entry.split(':', 2);

                    if (value === undefined)
                    {
                        key = key.toLowerCase();
                        result = result && (process.path.toLowerCase().includes(key) || process.cmdline.toLowerCase().includes(key) ||
                               process.user.toLowerCase().includes(key) || process.pid == key);
                        continue;
                    }

                    else if (key === 'uuid' || key === 'id' || key == 'location')
                    {
                        let found = false;

                        if (key === 'uuid')
                        {
                            key = 'id';
                        }

                        for (const intf of process.rpc_info.interface_infos)
                        {
                            if (String(intf[key]).toLowerCase().includes(value))
                            {
                                found = true
                            }
                        }

                        result = result && found;
                        continue;
                    }

                    else if (key === 'endpoint')
                    {
                        let found = false;

                        for (const endpoint of process.rpc_info.server_info.endpoints)
                        {
                            if (endpoint.name.toLowerCase().includes(value))
                            {
                                found = true
                            }
                        }

                        result = result && found;
                        continue;
                    }

                    result = result && (Object.hasOwn(process, key) && String(process[key]).toLowerCase().includes(value));
                }

                return result;
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
