<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'
    import VueSimpleContextMenu from 'vue-simple-context-menu';
    import 'vue-simple-context-menu/dist/vue-simple-context-menu.css';

    export default
    {
        data()
        {
            return {
                contextOptions: [{name: 'Decompile'}],
            }
        },

        setup()
        {
            const store = processStore();
            const { interfaceFilter, selectedProcess, selectedInterface } = storeToRefs(store);
            return { store, interfaceFilter, selectedProcess, selectedInterface }
        },

        components:
        {
            VueSimpleContextMenu,
        },

        methods:
        {
            selectRow(intf)
            {
                this.selectedInterface = intf;
            },

            applyFilter(filter, intf)
            {
                if (!filter)
                {
                    return true;
                }

                filter = filter.toLowerCase();

                if (!filter.includes(':'))
                {
                    let inverse = false;

                    if (filter.startsWith('!'))
                    {
                        filter = filter.substring(1);
                        inverse = true;
                    }

                    return (intf.uuid.toLowerCase().includes(filter) || intf.location.toLowerCase().includes(filter) ||
                            intf.decs.toLowerCase().includes(filter) || intf.name.toLowerCase().includes(filter) ||
                            intf.annotation.toLowerCase().includes(filter)) != inverse;
                }

                return true;
            },

            interfaceClick(e, item)
            {
                if (item.typ != 'rpc')
                {
                    console.log('Not implemented yet.');
                    return;
                }

                this.options = [{name: `Decompile ${item.id}`}];
                this.$refs.contextMenu.showMenu(e, item);
            },

            contextMenuClick(e)
            {
                if (e.option.name != 'Decompile' || e.item.typ != 'rpc')
                {
                    console.log('Not implemented yet.');
                    return;
                }

                const uuid = e.item.id;
                const pid = this.selectedProcess.pid;
                const snapshotID = this.selectedProcess.snapshotID;

                this.store.decompile(pid, uuid, snapshotID);
            }
        },
    }
</script>

<template>
    <h3 class="ml-2">RPC Interfaces</h3>

    <input v-model="interfaceFilter" class="form-control mb-1" style="width: 95%" placeholder="filter: (<str> | type:<str> | uuid:<str> | location:<str> | desc:<str> | name:<str> | flags:<str> | annotation:<str> | epregistered:<str> | ...)"/>

    <aside id="InterfacePane" class="SmallBorder">
        <table class="GenericTable">
            <tr>
                <th class="InterfaceColumn">Type</th>
                <th class="InterfaceColumn">UUID</th>
                <th class="InterfaceColumn">Location</th>
                <th class="InterfaceColumn">Procs</th>
                <th class="InterfaceColumn">Desc</th>
                <th class="InterfaceColumn">Name</th>
                <th class="InterfaceColumn">Annotation</th>
                <th class="InterfaceColumn">EpRegistred</th>
            </tr>
            <tr v-if="selectedProcess && applyFilter(interfaceFilter, intf)" v-for="intf in selectedProcess.rpc_info.interface_infos" @contextmenu.prevent.stop="interfaceClick($event, intf)"
                :class="{ Selected: (selectedInterface && selectedInterface.id == intf.id), Rpc: intf.typ == 'rpc',
                          Dcom: intf.typ == 'dcom', Hybrid: intf.typ == 'hybrid' }" @click='selectRow(intf)'>
                <td class="InterfaceColumn">{{ intf.typ.toUpperCase() }}</td>
                <td class="InterfaceColumn">{{ intf.id }}</td>
                <td class="InterfaceColumn">{{ intf.location }}</td>
                <td class="InterfaceColumn">{{ intf.methods.length }}</td>
                <td class="InterfaceColumn">{{ intf.description }}</td>
                <td class="InterfaceColumn">{{ intf.name }}</td>
                <td class="InterfaceColumn">{{ intf.annotation }}</td>
                <td class="InterfaceColumn">{{ intf.ep_registered }}</td>
            </tr>
        </table>
    </aside>
    <VueSimpleContextMenu elementId="contextMenu" :options="contextOptions" ref="contextMenu" @option-clicked="contextMenuClick"/>
</template>

<style>
    #InterfacePane {
        height: 22%;
        width: 95%;
        margin-bottom: 2%;
    }

    .InterfaceColumn {
        padding-right: 10px;
        cursor: pointer;
    }
</style>
