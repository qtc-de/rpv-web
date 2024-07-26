<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'

    import ProcessTableRow from './ProcessTableRow.vue'

    export default
    {
        props: ['processTree'],

        components:
        {
            ProcessTableRow,
        },

        setup()
        {
            const store = processStore();
            const { processFilter } = storeToRefs(store);

            return { processFilter }
        },

        methods:
        {
            isDiff()
            {
                for (const process of this.processTree)
                {
                    return process.added || process.changed || process.removed;
                }
            }
        }
    }
</script>

<template>
        <input v-model="processFilter" class="W-90 form-control ml-5 mb-2" placeholder="filter: (<str> | name:<str> | user:<str> | pid:<str> | id:<str> | endpoints:<str> | location:<str> | ...)"/>

        <div id="ProcessPane" class="SmallBorder ml-3 mb-2">
            <table class="GenericTable">
                <tr>
                    <th class="NameColumn">Name</th>
                    <th class="PidColumn">PID</th>
                    <th class="UserColumn">User</th>
                    <th class="PathColumn">Path</th>
                    <th class="CommandColumn">Commandline</th>
                </tr>
                <ProcessTableRow v-for="process in processTree" :process="process" indent="0" :filter="processFilter"/>
            </table>
        </div>

        <p class="ml-4 mt-1 mb-0 float-left">Legend:</p>
        <table id="Legend" class="ml-4 float-right">
            <tr>
                <template v-if="isDiff()">
                    <td class="pr-2"><div class="ColorSample Added"> </div></td>
                    <td class="pr-5">New</td>

                    <td class="pr-2"><div class="ColorSample Removed"> </div></td>
                    <td class="pr-5">Del</td>

                    <td class="pr-2"><div class="ColorSample Changed"> </div></td>
                    <td class="pr-5">Mod</td>
                </template>

                <td class="pr-2"><div class="ColorSample Rpc"> </div></td>
                <td class="pr-5">RPC</td>

                <td class="pr-2"><div class="ColorSample Dcom"> </div></td>
                <td class="pr-5">DCOM</td>

                <td class="pr-2"><div class="ColorSample Hybrid"> </div></td>
                <td class="pr-5">Hybrid</td>

                <td class="pr-2"><div class="ColorSample WrongArch"> </div></td>
                <td class="pr-5">Wrong Architecture</td>
            </tr>
        </table>
</template>

<style>
    #ProcessPane {
        height: 80%;
        width: 95%;
    }

    #Legend {
        height: 25px;
    }

    .ColorSample {
        width: 15px;
        height: 15px;
    }
</style>
