<script>
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'
    import ProcessTree from './ProcessTree.vue'
    import 'highlight.js/styles/github.css'
    import 'highlight.js/lib/common';
    import hljsVuePlugin from '@highlightjs/vue-plugin';

    export default
    {
        data()
        {
            return {
                lastTabLength: 0,
                selectedTab: 'Processes',
                timer: null,
                editTab: null,
            }
        },

        setup()
        {
            const store = processStore();
            const { processTree, refreshTimer, tabs } = storeToRefs(store)

            const offlineMode = (import.meta.env.VITE_OFFLINE_MODE != 0) ? true : false;

            return { store, processTree, refreshTimer, tabs, offlineMode }
        },

        components: {
            ProcessTree,
            highlightjs: hljsVuePlugin.component,
        },

        watch: {
            refreshTimer: function(value)
            {
                clearInterval(this.timer);

                this.timer = setInterval(() => {
                    this.store.updateProcessTree()
                }, this.refreshTimer * 1000);
            },

            tabs: {
                handler(val)
                {
                    if (val.length > this.lastTabLength)
                    {
                        this.selectedTab = val[val.length - 1].name;
                    }

                    this.lastTabLength = val.length;
                },
                deep: true
            }
        },

        created()
        {
            this.store.updateProcessTree();

            this.timer = setInterval(() => {
                this.store.updateProcessTree()
            }, this.refreshTimer * 1000);
        },

        methods:
        {
            switchTab(name)
            {
                this.selectedTab = name;
            },

            closeTab(name)
            {
                const index = this.store.remove_tab(name);

                if (index != 0)
                {
                    this.selectedTab = this.tabs[index - 1].name;
                }

                else
                {
                    this.selectedTab = 'Processes';
                }
            },

            selectIdl(e, name)
            {
                var range = document.createRange();

                range.selectNode(document.getElementById(name));
                window.getSelection().addRange(range);

                e.preventDefault();
            },

            saveTabName(tab)
            {
                let new_name = this.$refs[`${tab.name}`][0].value;

                for (const other of this.tabs)
                {
                    if (other.name === new_name)
                    {
                        console.log(`Tab with name ${new_name} already exists.`);
                        new_name = tab.name;
                        break;
                    }
                }

                if (tab.name === this.selectedTab)
                {
                    this.selectedTab = new_name;
                }

                if (tab.oldName === undefined)
                {
                    tab.oldName = tab.name;
                }

                tab.name = new_name;

                this.editTab = null;
            },

            enableEditing(tab)
            {
                this.editTab = tab.name;

                this.$nextTick(() => {
                    this.$refs[`${tab.name}`][0].value = tab.name;
                    this.$refs[`${tab.name}`][0].focus();
                });
            },

            async loadSnapshot()
            {
                if (this.$refs.SnapshotUpload.files[0] === null)
                {
                    console.log('Nothing to load.');
                    return;
                }

                const file = this.$refs.SnapshotUpload.files[0];
                file.text().then( (snapshotData) =>
                    {
                        try
                        {
                            const snapshot = JSON.parse(snapshotData);
                            const filename = this.$refs.SnapshotUpload.value.replace(/^.*[\\\/]/, '');

                            this.store.loadSnapshot(filename, snapshot);
                        }

                        catch (e)
                        {
                            console.log('Snapshot contains invalid JSON.');
                            console.log(e);
                        }
                    }
                );
            },
        }
    }
</script>

<template>
    <div class="tabnav">
        <nav class="tabnav-tabs ml-2" aria-label="ServerNav">
            <button class="tabnav-tab ServerNavTab" v-if="!offlineMode" :aria-current="(selectedTab == 'Processes') ? true : null" @click="switchTab('Processes')">Processes</button>
            <button class="tabnav-tab ServerNavTab" v-for="tab in tabs" :aria-current="(selectedTab == tab.name) ? true : null" @click="switchTab(tab.name)">
                <input v-if="editTab == tab.name" :ref="tab.name" class="DynamicInput" v-on:keyup.enter="saveTabName(tab)" v-on:blur="saveTabName(tab)" />
                <template v-else>
                    <div class="float-left mr-1" @dblclick="enableEditing(tab)">
                        {{ tab.name }}
                    </div>
                    <a id="CloseTab" @click.stop="closeTab(tab.name)">X</a>
                </template>
            </button>
        </nav>
    </div>

    <ProcessTree v-if="selectedTab == 'Processes' && !offlineMode" :processTree="processTree" />
    <div v-if="offlineMode && selectedTab == 'Processes'" class="WH-100">

        <div id="SnapshotPane" class="SmallBorder ml-3 mb-2">
            <label for="SnapshotUpload">
                <div id="SnapshotBox">
                    <img class="d-inline-block" id="SnapshotButton" src="/src/assets/icons/button.png"/>
                    <div class="d-inline-block" id="SnapshotText">Load Snapshot</div>
                </div>
            </label>
            <input type="file" ref="SnapshotUpload" id="SnapshotUpload" @change="loadSnapshot()"/>
        </div>
    </div>

    <template v-for="tab in tabs">
        <highlightjs v-if="tab.type == 'idl' && tab.name == selectedTab" :id="tab.name" class="IdlPane SmallBorder ml-3" @keydown.ctrl.a="selectIdl($event, tab.name)" tabindex="0" language="cpp" :code="tab.data" />
        <ProcessTree v-if="tab.type == 'snapshot' && tab.name == selectedTab" :processTree="tab.data.processes" />
    </template>
</template>

<style>
    #CloseTab {
        color: grey;
    }

    #SnapshotPane {
        height: 95%;
        width: 95%;
    }

    #SnapshotBox {
        margin-top: 35%;
        margin-left: 30%;
        height: 10%;
        cursor: pointer;
    }

    #SnapshotText {
        padding-left: 5%;
        height: 100%;
        vertical-align: top;
        font-size: 18pt;
        padding-top: 3%;
    }

    #SnapshotButton {
        height: 100%;
    }

    #SnapshotUpload {
        display: none;
    }

    .IdlPane {
        height: 90%;
        width: 95%;
        padding: 20px;
    }
</style>
