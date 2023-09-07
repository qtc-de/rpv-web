<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'

    export default
    {
        data()
        {
            return {
                editMethod: null,
                editNotes: null,
                selectedMethod: null,
            }
        },

        setup()
        {
            const store = processStore();
            const { selectedProcess, selectedInterface } = storeToRefs(store);
            return { selectedInterface, selectedProcess, store }
        },

        methods:
        {
            enableEditing(base, ref, value)
            {
                this[`edit${ref}`] = base;

                this.$nextTick(() => {
                    this.$refs[`${base}${ref}`][0].value = value;
                    this.$refs[`${base}${ref}`][0].focus();
                });
            },

            async changeMethodName(event, index)
            {
                const methodName = event.target.value;
                this.editMethod = null;

                let method = this.selectedInterface.methods[index];

                this.store.addMethodName(methodName, method.base, this.selectedInterface.location)
                method.name = methodName;
            },

            async saveNotes(event, index)
            {
                const notes = event.target.value;
                this.editNotes = null;

                this.store.addMethodNotes(notes, index, this.selectedInterface.id)
                this.selectedInterface.methods[index].notes = notes;
            }
        }
    }
</script>

<template>
    <h3 class="ml-2">RPC Methods</h3>
    <aside id="MethodPane" class="SmallBorder">
        <table id="MethodTable" class="GenericTable">
            <tr>
                <th>Id</th>
                <th>Name</th>
                <th>Base Address</th>
                <th>Notes</th>
                <th>Format Address</th>
            </tr>
            <tr style="cursor: pointer" v-if="selectedInterface" v-for="(method, index) in selectedInterface.methods" @click="selectedMethod = method"
                :class="{ Selected: selectedMethod == method }">
                <td>{{ index }}</td>
                <td v-if="selectedInterface && editMethod != method.base" @dblclick="enableEditing(method.base, 'Method', method.name)">{{ method.name }}</td>
                <td v-if="selectedInterface && editMethod == method.base"><input :ref="method.base + 'Method'" class="DynamicInput" v-on:keyup.enter="changeMethodName($event, index)"
                v-on:blur="changeMethodName($event, index)"/></td>
                <td>{{ method.base }}</td>
                <td v-if="selectedInterface && editNotes != method.base" @dblclick="enableEditing(method.base, 'Notes', method.notes)">{{ method.notes }}</td>
                <td v-if="selectedInterface && editNotes == method.base"><input :ref="method.base + 'Notes'" class="DynamicInput" v-on:keyup.enter="saveNotes($event, index)"
                v-on:blur="saveNotes($event, index)"/></td>
                <td>{{ method.fmt }}</td>
            </tr>
        </table>
    </aside>
</template>

<style>
    #MethodPane {
        height: 100%;
        width: 90%;
    }

    #MethodTable td {
        padding-right: 15px;
    }

    #MethodTable th {
        padding-right: 15px;
    }
</style>
