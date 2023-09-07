<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'

    export default
    {
        data()
        {
            return {
                selectedTab: 'Process'
            }
        },

        setup()
        {
            const store = processStore();
            const { selectedProcess } = storeToRefs(store);
            return { selectedProcess }
        },

        methods:
        {
            switchTab(event)
            {
                this.selectedTab = event.target.innerText;
            }
        }
    }
</script>

<template>
    <h3 class="mb-2">RPC Server Information</h3>

    <div class="tabnav">
        <nav class="tabnav-tabs" aria-label="ServerNav">
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'Process') ? true : null" @click="switchTab($event)">Process</button>
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'General') ? true : null" @click="switchTab($event)">General</button>
            <button class="tabnav-tab ServerNavTab" :aria-current="(selectedTab == 'Auth') ? true : null" @click="switchTab($event)">Auth</button>
        </nav>
    </div>

    <div id="ServerPane">
        <table class="ml-1 mt-2 ServerTable" v-if="selectedTab == 'Process'">
            <tr>
                <td>Process Name</td>
                <td v-if="selectedProcess" class="pl-2">{{ selectedProcess.name }}</td>
            </tr>
            <tr>
                <td>Commandline</td>
                <td v-if="selectedProcess" class="pl-2">{{ selectedProcess.cmdline }}</td>
            </tr>
            <tr>
                <td>Path</td>
                <td v-if="selectedProcess" class="pl-2">{{ selectedProcess.path }}</td>
            </tr>
            <tr>
                <td>PID</td>
                <td v-if="selectedProcess" class="pl-2">{{ selectedProcess.pid }}</td>
            </tr>
            <tr>
                <td>PPID</td>
                <td v-if="selectedProcess" class="pl-2">{{ selectedProcess.ppid }}</td>
            </tr>
            <tr>
                <td>User</td>
                <td v-if="selectedProcess" class="pl-2">{{ selectedProcess.user }}</td>
            </tr>
        </table>

        <table class="ml-1 mt-2 ServerTable" v-if="selectedTab == 'General'">
            <tr>
                <td>RPC Type</td>
                <td v-if="selectedProcess">{{ selectedProcess.rpc_info.rpc_type }}</td>
            </tr>
            <tr>
                <td>Base Address</td>
                <td v-if="selectedProcess">{{ selectedProcess.rpc_info.server_info.base }}</td>
            </tr>
            <tr>
                <td>Endpoint Count</td>
                <td v-if="selectedProcess">{{ selectedProcess.rpc_info.server_info.endpoints.length }}</td>
            </tr>
            <tr>
                <td>Interface Count</td>
                <td v-if="selectedProcess">{{ selectedProcess.rpc_info.server_info.intf_count }}</td>
            </tr>
            <tr>
                <td>In Calls</td>
                <td v-if="selectedProcess">{{ selectedProcess.rpc_info.server_info.in_calls }}</td>
            </tr>
            <tr>
                <td>Out Calls</td>
                <td v-if="selectedProcess">{{ selectedProcess.rpc_info.server_info.in_calls }}</td>
            </tr>
        </table>

        <table class="ml-1 mt-2 ServerTable" v-if="selectedTab == 'Auth'">
            <tr>
                <th>Auth Type</th>
                <th>DLL</th>
                <th>Principal</th>
            </tr>
            <tr v-if="selectedProcess" v-for="info in selectedProcess.rpc_info.server_info.auth_info">
                <td>{{ info.name }}</td>
                <td>{{ info.dll }}</td>
                <td>{{ info.principal }}</td>
            </tr>
        </table>
    </div>
</template>

<style>
    #ServerPane {
        overflow: auto;
        height: 80%;
    }

    .ServerTable {
        width: 98%;
        text-align: left;
        white-space: nowrap;
    }
</style>
