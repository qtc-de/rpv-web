<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'

    export default
    {
        data()
        {
            return {
                selectedTab: 'General',
                editSecCallback: false,
                editInterfaceName: false,
            }
        },

        setup()
        {
            const store = processStore();
            const { selectedProcess, selectedInterface } = storeToRefs(store);

            const offlineMode = import.meta.env.VITE_OFFLINE_MODE;

            return { selectedInterface, selectedProcess, offlineMode, store }
        },

        methods:
        {
            switchTab(tab)
            {
                this.selectedTab = tab;
            },

            enableEditing(event, ref, value)
            {
                this[`edit${ref}`] = true;

                this.$nextTick(() => {
                    this.$refs[ref].value = value;
                    this.$refs[ref].focus();
                });
            },

            async changeCallbackName(event)
            {
                if (!this.selectedInterface)
                {
                    return
                }

                const callbackName = event.target.value;
                this.editSecCallback = false;

                this.store.addCallbackName(callbackName, this.selectedInterface.sec_callback)
                this.selectedInterface.sec_callback.name = callbackName;
            },

            async changeInterfaceName(event)
            {
                if (!this.selectedInterface) {
                    return
                }

                const interfaceName = event.target.value;
                this.editInterfaceName = false;

                this.store.addInterfaceName(interfaceName, this.selectedInterface.id)
                this.selectedInterface.name = interfaceName;
            },

            async saveNotes()
            {
                if (!this.selectedInterface) {
                    return
                }

                const notes = this.$refs.Notes.value

                this.store.addInterfaceNotes(notes, this.selectedInterface.id)
                this.selectedInterface.notes = notes;
            }
        }
    }
</script>

<template>
    <h3 class="mb-2">Interface Information</h3>

    <div class="tabnav">
        <nav class="tabnav-tabs" aria-label="ServerNav">
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'General') ? true : null" @click="switchTab('General')">General</button>
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'RPC') ? true : null" @click="switchTab('RPC')">RPC</button>
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'Security') ? true : null" @click="switchTab('Security')">Security</button>
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'NDR') ? true : null" @click="switchTab('NDR')">NDR</button>
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'Notes') ? true : null" @click="switchTab('Notes')">Notes</button>
        </nav>
    </div>

    <table class="ml-1 mt-2 InterfaceDetailedTable" v-if="selectedTab == 'General'">
        <tr>
            <td>ID</td>
            <td v-if="selectedInterface">{{ selectedInterface.id }}</td>
        </tr>
        <tr>
            <td>Name</td>
            <td v-if="selectedInterface && !editInterfaceName" @dblclick="enableEditing($event, 'InterfaceName', selectedInterface.name)">{{ selectedInterface.name }}</td>
            <td v-if="selectedInterface && editInterfaceName"><input ref="InterfaceName" class="DynamicInput" v-on:keyup.enter="changeInterfaceName($event)"
                v-on:blur="changeInterfaceName($event)"/></td>
        </tr>
        <tr>
            <td>DLL</td>
            <td v-if="selectedInterface">{{ selectedInterface.location }}</td>
        </tr>
        <tr>
            <td>Description</td>
            <td v-if="selectedInterface">{{ selectedInterface.description }}</td>
        </tr>
        <tr>
            <td>Method Count</td>
            <td v-if="selectedInterface">{{ selectedInterface.methods.length }}</td>
        </tr>
    </table>

    <table class="ml-1 mt-2 InterfaceDetailedTable" v-if="selectedTab == 'RPC'">
        <tr>
            <td>EP Registered</td>
            <td v-if="selectedInterface">{{ selectedInterface.ep_registered }}</td>
        </tr>
        <tr>
            <td>Base Addr</td>
            <td v-if="selectedInterface">{{ selectedInterface.base }}</td>
        </tr>
        <tr>
            <td>Dispatch Table</td>
            <td v-if="selectedInterface">{{ selectedInterface.dispatch_table_addr }}</td>
        </tr>
        <tr>
            <td>Annotation</td>
            <td v-if="selectedInterface">{{ selectedInterface.annotation }}</td>
        </tr>
        <tr>
            <td>Flags</td>
        </tr>
        <tr v-if="selectedInterface" v-for="flag in selectedInterface.flags">
            <td></td>
            <td v-if="selectedInterface">{{ flag }}</td>
        </tr>
    </table>

    <table class="ml-1 mt-2 InterfaceDetailedTable" v-if="selectedTab == 'Security'">
        <tr>
            <td>Security Callback</td>
            <td v-if="selectedInterface">{{ selectedInterface.sec_callback.addr }}</td>
        </tr>
        <tr>
            <td>Callback Name</td>
            <td v-if="selectedInterface && !editSecCallback" @dblclick="enableEditing($event, 'SecCallback', selectedInterface.sec_callback.name)">{{ selectedInterface.sec_callback.name }}</td>
            <td v-if="selectedInterface && editSecCallback"><input ref="SecCallback" class="DynamicInput" v-on:keyup.enter="changeCallbackName($event)"
                v-on:blur="changeCallbackName($event)"/></td>
        </tr>
        <tr>
            <td>Module</td>
            <td v-if="selectedInterface">{{ selectedInterface.sec_callback.location }}</td>
        </tr>
        <tr>
            <td>Offset</td>
            <td v-if="selectedInterface">{{ selectedInterface.sec_callback.offset }}</td>
        </tr>
        <tr>
            <td>Description</td>
            <td v-if="selectedInterface">{{ selectedInterface.sec_callback.description }}</td>
        </tr>
    </table>

    <table class="ml-1 mt-2 InterfaceDetailedTable" v-if="selectedTab == 'NDR'">
        <tr>
            <td>Transfer Syntax</td>
            <td v-if="selectedInterface">{{ selectedInterface.ndr_info.syntax }}</td>
        </tr>
        <tr>
            <td>NDR Version</td>
            <td v-if="selectedInterface">0x{{ selectedInterface.ndr_info.ndr_version.toString(16) }}</td>
        </tr>
        <tr>
            <td>MIDL Version</td>
            <td v-if="selectedInterface">0x{{ selectedInterface.ndr_info.midl_version.toString(16) }}</td>
        </tr>
        <tr>
            <td>Flags</td>
        </tr>
        <tr v-if="selectedInterface" v-for="flag in selectedInterface.ndr_info.flags">
            <td></td>
            <td v-if="selectedInterface">{{ flag }}</td>
        </tr>
    </table>

    <textarea ref="Notes" id="NotesArea" class="ml-1 mt-2" v-if="selectedInterface && selectedTab == 'Notes'" v-on:keyup.enter="saveNotes()" v-on:blur="saveNotes()">{{selectedInterface.notes}} </textarea>
</template>

<style>
    #NotesArea {
        width: 100%;
        height: 70%;
    }

    .InterfaceDetailedTable {
        width: 100%;
        text-align: left;
        white-space: nowrap;
    }

    .DynamicInput {
        border: 0;
        width: 100%;
    }
</style>
