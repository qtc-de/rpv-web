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
            const { selectedProcess, selectedInterface, tabs, selectedTab } = storeToRefs(store);
            return { tabs, selectedTab, selectedInterface, selectedProcess, store }
        },

        methods:
        {
            enableEditing(addr, ref, value)
            {
                this[`edit${ref}`] = addr;

                this.$nextTick(() => {
                    this.$refs[`${addr}${ref}`][0].value = value;
                    this.$refs[`${addr}${ref}`][0].focus();
                });
            },

            async changeMethodName(event, index)
            {
                const methodName = event.target.value;
                this.editMethod = null;

                let method = this.selectedInterface.methods[index];
                this.store.addMethodName(methodName, method.addr, this.selectedInterface.location)

                if (method.origName === undefined)
                {
                    method.origName = method.name;
                }

                method.name = methodName;
            },

            async saveNotes(event, index)
            {
                const notes = event.target.value;
                this.editNotes = null;

                this.store.addMethodNotes(notes, index, this.selectedInterface.id)
                this.selectedInterface.methods[index].notes = notes;
            },

            jumpDecompiled(method)
            {
                for (const tab of this.tabs)
                {
                    if (tab.origName === this.selectedInterface.id)
                    {
                        this.selectedTab = tab.name;
                        const tabComponent = document.getElementById(tab.origName);

                        if(tabComponent != null)
                        {
                            const tabElement = tabComponent.children[0];

                            for (const child of tabElement.children)
                            {
                                if (child.textContent.includes(` ${method.name}(`) || child.textContent.includes(` ${method.origName}(`))
                                {
                                    child.scrollIntoView();
                                }
                            }
                        }
                    }
                }
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
                <th>Address</th>
                <th>Offset</th>
                <th>Notes</th>
                <th>Format Address</th>
            </tr>
            <tr style="cursor: pointer" v-if="selectedInterface" v-for="(method, index) in selectedInterface.methods" @click="selectedMethod = method; jumpDecompiled(method)"
                :class="{ Selected: selectedMethod == method }">
                <td>{{ index }}</td>
                <td v-if="selectedInterface && editMethod != method.addr" @dblclick="enableEditing(method.addr, 'Method', method.name)">{{ method.name }}</td>
                <td v-if="selectedInterface && editMethod == method.addr"><input :ref="method.addr + 'Method'" class="DynamicInput" v-on:keyup.enter="changeMethodName($event, index)"
                v-on:blur="changeMethodName($event, index)"/></td>
                <td>{{ method.addr }}</td>
                <td>{{ method.offset }}</td>
                <td v-if="selectedInterface && editNotes != method.addr" @dblclick="enableEditing(method.addr, 'Notes', method.notes)">{{ method.notes }}</td>
                <td v-if="selectedInterface && editNotes == method.addr"><input :ref="method.addr + 'Notes'" class="DynamicInput" v-on:keyup.enter="saveNotes($event, index)"
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
