<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'

    export default
    {
        data()
        {
            return {
                selectedEndpoint: null,
            }
        },

        setup()
        {
            const store = processStore();
            const { selectedProcess } = storeToRefs(store);
            return { selectedProcess }
        }
    }
</script>

<template>
    <h3 class="ml-2">RPC Endpoints</h3>
    <aside id="EndpointPane" class="SmallBorder mt-2">
        <table id="EndpointTable">
            <tr>
                <th id="ProtocolColumn">Protocol</th>
                <th id="EndpointColumn">Endpoint</th>
            </tr>
            <tr style="cursor: pointer" v-if="selectedProcess" v-for="endpoint in selectedProcess.rpc_info.server_info.endpoints"
                :class="{ Selected: selectedEndpoint == endpoint }" @click="selectedEndpoint = endpoint">
                <td>{{ endpoint.protocol }}</td>
                <td>{{ endpoint.name }}</td>
            </tr>
        </table>
    </aside>
</template>

<style>
    #EndpointPane {
        height: 100%;
        width: 90%;
    }

    #EndpointTable {
        width: 100%;
        text-align: left;
        white-space: nowrap;
    }

    #ProtocolColumn {
        width: 20%;
    }
</style>
