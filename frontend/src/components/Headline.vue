<script>
    import { toRaw } from 'vue'
    import { storeToRefs } from 'pinia'
    import { processStore } from '@/stores/processStore.js'
    import ErrorSuccessLabels from './ErrorSuccessLabels.vue'

    export default
    {
        data()
        {
            return {
                loading: false,
                showSettings: false,
                showSnapshot: false,
                snapshotError: null,
                settingsError: null,
                symbolsError: null,
            }
        },

        components: {
            ErrorSuccessLabels
        },

        setup()
        {
            const store = processStore();
            const { refreshTimer, symbols, symbolExport } = storeToRefs(store)

            const offlineMode = (import.meta.env.VITE_OFFLINE_MODE != 0) ? true : false;

            return { refreshTimer, store, offlineMode, symbols, symbolExport }
        },

        methods:
        {
            showMenu(name)
            {
                if (name == 'settings')
                {
                    this.showSettings = true;
                    this.showSnapshot = false;
                }

                else if (name == 'snapshot')
                {
                    this.showSnapshot = true;
                    this.showSettings = false;
                }

                else
                {
                    return;
                }

                this.$nextTick(() => {
                    const pane = document.getElementsByClassName('FloatingPane')[0];
                    pane.focus();
                });
            },

            async saveSettings()
            {
                this.settingsError = null;

                if (/^\d+$/.test(this.$refs['RefreshInterval'].value))
                {
                    this.refreshTimer = this.$refs['RefreshInterval'].value;
                }

                const data = {
                    "symbol_path": this.$refs['SymbolFolder'].value,
                }

                fetch('/api/settings', {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(data)

                }).then(response =>
                {

                    if (response.ok)
                    {
                        response.json().then(settings =>
                        {
                            this.$refs['SymbolFolder'].value = settings.symbol_path;
                            this.settingsError = false;
                        }).catch(err =>
                        {
                            console.log(err);
                            this.settingsError = true;
                        });
                    }

                    else
                    {
                        console.log(response);
                        this.settingsError = true;
                    }

                }).catch(error =>
                {
                    console.log(error);
                    this.settingsError = true;
                });
            },

            async loadSettings()
            {
                if (this.offlineMode)
                {
                    console.log('Loading settings is not supported in offline mode.');
                    return;
                }

                fetch('/api/settings').then(response =>
                {
                    if (response.ok)
                    {
                        response.json().then(settings =>
                        {
                            this.$refs['SymbolFolder'].value = settings.symbol_path;
                        }).catch(err =>
                        {
                            console.log(err);
                        });
                    }

                    else
                    {
                        console.log(response);
                    }

                }).catch(error =>
                {
                    console.log(error);
                });
            },

            blobToBase64(blob)
            {
                return new Promise((resolve, _) =>
                {
                    const reader = new FileReader();
                    reader.onloadend = () => resolve(reader.result);
                    reader.readAsDataURL(blob);
                });
            },

            createDownload(blob, name)
            {
                const url = URL.createObjectURL(blob);

                const a = document.createElement('a');
                a.setAttribute('href', url);
                a.setAttribute('download', name);

                a.click();
            },

            async createSnapshot()
            {
                this.loading = true;
                this.snapshotError = null;

                fetch('/api/snapshot').then((response) =>
                {
                    if (response.ok)
                    {
                        response.json().then((jsonResponse) =>
                        {
                            const today = new Date();

                            const mm = String(today.getMinutes()).padStart(2, '0');
                            const hh = String(today.getHours()).padStart(2, '0');

                            const DD = String(today.getDate()).padStart(2, '0');
                            const MM = String(today.getMonth() + 1).padStart(2, '0');
                            const YYYY = today.getFullYear();

                            const filename = `${YYYY}.${MM}.${DD}-${hh}:${mm}-rpv-web-snapshot.json`;

                            const blob = new Blob([JSON.stringify(jsonResponse)], { type: 'application/json' });
                            this.createDownload(blob, filename);

                            this.loading = false;
                            this.snapshotError = false;
                        }

                        ).catch( (error) =>
                        {
                            console.log('Snapshot API returned invalid JSON.');
                            console.log(error);

                            this.loading = false;
                            this.snapshotError = true;
                        });
                    }

                    else
                    {
                        console.log('Creating snapshot failed.');

                        this.loading = false;
                        this.snapshotError = true;
                    }
                });
            },

            async restoreSnapshot()
            {
                if (this.$refs.LoadSnapshot.files[0] === null)
                {
                    console.log('Nothing to load.');
                    return;
                }

                const file = this.$refs.LoadSnapshot.files[0];
                file.text().then(snapshotData =>
                {
                    try
                    {
                        const snapshot = JSON.parse(snapshotData);
                        const filename = this.$refs.LoadSnapshot.value.replace(/^.*[\\\/]/, '');

                        this.store.loadSnapshot(filename, snapshot);
                        this.showSnapshot = false;
                    }

                    catch (e)
                    {
                        console.log('Snapshot contains invalid JSON.');
                        console.log(e);
                    }
                });
            },

            async compareSnapshots()
            {
                if (this.$refs.CompareSnapShotOne.files[0] === null || this.$refs.CompareSnapShotTwo.files[0] === null)
                {
                    console.log('Missing snapshot.');
                    return;
                }

                let file = this.$refs.CompareSnapShotOne.files[0];
                const filename = this.$refs.CompareSnapShotOne.value.replace(/^.*[\\\/]/, '');

                file.text().then( (snapshotData) =>
                {
                    try
                    {
                        const snapshot_one = JSON.parse(snapshotData);

                        file = this.$refs.CompareSnapShotTwo.files[0];
                        file.text().then( (snapshotData) =>
                        {
                            try
                            {
                                const snapshot_two = JSON.parse(snapshotData);
                                this.store.compareSnapshots(`diff-${filename}`, snapshot_one, snapshot_two);
                            }

                            catch (e)
                            {
                                console.log('Snapshot two contains invalid JSON.');
                                console.log(e);
                                return;
                            }
                        });

                        this.showSnapshot = false;
                    }

                    catch (e)
                    {
                        console.log('Snapshot one contains invalid JSON.');
                        console.log(e);
                        return;
                    }
                });
            },

            exportSymbols()
            {
                let symbols = this.store.exportSymbols();

                const blob = new Blob([symbols], { type: 'application/toml' });
                this.createDownload(blob, 'rpv-web-symbols.toml');

                this.symbolExport = structuredClone(toRaw(this.symbols));
            },

            async loadSymbols()
            {
                if (this.$refs.LoadSymbols.files[0] === null)
                {
                    console.log("No symbol file found");
                    return;
                }

                const file = this.$refs.LoadSymbols.files[0];
                const data = await file.text();

                this.store.loadSymbols(data);
                this.showSettings = false;
            },

            syncSymbols()
            {
                this.symbolsError = null;

                const data = {
                    "symbols": this.store.exportSymbols()
                }

                fetch('/api/symbols', {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(data)
                }).then(response =>
                {
                    if (response.ok)
                    {
                        this.symbolsError = false;
                        this.symbolExport = structuredClone(toRaw(this.symbols));
                        console.log(response);
                    }

                    else
                    {
                        this.symbolsError = true;
                        console.log(response);
                    }
                }).catch(error =>
                {
                    this.symbolsError = true;
                    console.log(error);
                })
            },

            unsavedSymbolCheck(e)
            {
                const current = JSON.stringify(this.symbols);
                const exported = JSON.stringify(this.symbolExport);

                if (current !== exported)
                {
                    e.preventDefault();
                }
            }
        },

        created()
        {
            window.addEventListener('beforeunload', this.unsavedSymbolCheck);
        },

        beforeDestroy()
        {
            window.removeEventListener('beforeunload', this.unsavedSymbolCheck);
        },
    }
</script>

<template>
    <div id="RpvHeadline" class="d-inline-block Header">
        <div id="LeftHeadline">
            <p id="Logo" class="d-inline-block">RP</p>
            <img id="LogoPng" src="../assets/icons/rpv-web.png"/>
            <p id="Web" class="d-inline-block">WEB</p>
            <p class="Fs-8 mb-0 ml-4">v1.3.0</p>
        </div>

        <div id="RightHeadline">
            <button class="btn HeadlineButton" @click="loadSettings(); showMenu('settings')">Settings</button>
            <button class="btn HeadlineButton mr-2" @click="showMenu('snapshot')">Snapshots</button>
            <button class="btn HeadlineButton mr-2" @click="store.updateProcessTree()" v-if="!offlineMode">Refresh</button>
        </div>
    </div>

    <div v-if="showSettings && !offlineMode" class="FloatingPane" @keydown.esc="showSettings = false" tabindex="0">
        <p class="FloatingPaneHeadline d-inline-block">rpv-web Settings</p>
        <button class="FloatingPaneExit btn float-right" @click="showSettings = false;">X</button>
        <button class="FloatingPaneExit btn" @click="saveSettings();">Save</button>
        <ErrorSuccessLabels class="mt-4 mr-3 float-right" :error="settingsError"/>

        <p class="PaneOption ml-4">Refresh Interval</p>
        <p class="PaneText">The number of seconds rpv-web waits before refreshing the currently available RPC information.</p>
        <input ref="RefreshInterval" class="W-90 ml-4" :value="refreshTimer"/>
        <hr/>

        <p class="PaneOption ml-4">PDB Folder Path</p>
        <p class="PaneText">Absolute file system path to a folder containing PDB files that are used for displaying symbol
        names within the RPC information (prefix with srv*).</p>
        <input ref="SymbolFolder" class="W-90 ml-4" />
        <hr/>

        <p class="PaneOption ml-4">Load Symbols</p>
        <p class="PaneText">Load an rpv symbol file. Contained symbols are applied immediately to all currently available
        and all in future available RPC data.</p>
        <input ref="LoadSymbols" class="ml-4" style="color: white;" type="file" @change="loadSymbols()">
        <hr/>

        <p class="PaneOption ml-4">Save Symbol File</p>
        <p class="PaneText">Save symbol name changes you performed in this instance to an rpv symbol file. This file can
        later be imported on other instances.</p>
        <button class="mr-4 btn float-right" @click="exportSymbols()">Save</button>
        <hr class="mt-8"/>

        <p class="PaneOption ml-4">Sync Symbols</p>
        <p class="PaneText">Upload the currently used client side rpv symbols to the server and merge them with the server
        side rpv symbols.</p>
        <button class="btn float-right mr-4 mb-5" @click="syncSymbols();">Sync</button>
        <ErrorSuccessLabels class="mt-2 mr-3 float-right" :error="symbolsError"/>
    </div>

    <div v-if="showSettings && offlineMode" class="FloatingPane" @keydown.esc="showSettings = false" tabindex="0">
        <p class="FloatingPaneHeadline d-inline-block">rpv-web Settings</p>
        <button class="FloatingPaneExit btn float-right" @click="showSettings = false;">X</button>

        <p class="PaneOption ml-4">Offline Mode</p>
        <p class="PaneText">This instance of rpv-web runs in offline mode. It can only be used to view or compare snapshots
        and does not automatically display any RPC data. To create a new snapshot, download the latest release of
        <a href="https://github.com/qtc-de/rpv-web">rpv-web</a> and follow the instructions from the
        <a href="https://github.com/qtc-de/rpv-web/wiki/snapshots">snapshot documentation</a>.</p>
        <hr class="mt-2"/>

        <p class="PaneOption ml-4">Save Symbol File</p>
        <p class="PaneText">Save symbol name changes you performed in this instance to an rpv symbol file. This file can
        later be imported on other instances.</p>
        <button class="mr-4 btn float-right" @click="exportSymbols()">Save</button>
        <hr class="mt-8"/>

        <p class="PaneOption ml-4">Load Symbol File</p>
        <p class="PaneText">Load an rpv symbol file. Stored symbols are immediately applied to the currently available
        RPC data. Also RPC data that is loaded afterwards should be affected.</p>
        <input ref="LoadSymbols" class="ml-4" style="color: white;" type="file" @change="loadSymbols()">
    </div>

    <div v-else-if="showSnapshot" class="FloatingPane" @keydown.esc="showSnapshot = false" tabindex="0">
        <p class="FloatingPaneHeadline d-inline-block">Snapshot Menu</p>
        <button class="FloatingPaneExit btn float-right" @click="showSnapshot = false">X</button>

        <p class="PaneText">Snapshots allow you to save the currently available RPC information to a file for later processing.
           Creating a snapshots involves decompilation of all available RPC interfaces, which takes some time.
           Snapshots can be imported and compared against each other within this menu.</p>

        <hr/>
        <p class="PaneOption ml-4">Create Snapshot</p>
        <div v-if="!offlineMode">
            <p  class="PaneText">Create a new snapshot from the currently available RPC information. After clicking
            the button, rpv-web will decompile all available RPC interfaces which may takes some time. Afterwards, the
            snapshot will be available for download.</p>
            <button class="btn float-right mr-5" @click="createSnapshot()">Create Snapshot</button>
            <ErrorSuccessLabels class="mt-2 mr-2 float-right" :error="snapshotError"/>
            <span class="color-fg-success float-right mr-2 mt-2" v-if="loading"><span>Processing</span><span class="AnimatedEllipsis"></span></span>
            <hr class="mt-8"/>
        </div>

        <div v-else>
            <p class="PaneText">Creating new snapshots isn't supported on this instance as it runs in <em>offline mode</em>.
            To create a new snapshot, download the latest release of <a href="https://github.com/qtc-de/rpv-web">rpv-web</a> and follow
            the instructions from the <a href="https://github.com/qtc-de/rpv-web/wiki/snapshots">snapshot documentation</a>.
            </p>
            <hr class="mt-2"/>
        </div>

        <p class="PaneOption ml-4 mt-2">Restore Snapshot</p>
        <p class="PaneText">Loads an rpv-web snapshot from file. The snapshot is visible within a separate process pane
        and will not overwrite currently available RPC information.</p>
        <input ref="LoadSnapshot" class="ml-4" style="color: white;" type="file" @change="restoreSnapshot()">
        <hr class="mt-4"/>

        <p class="PaneOption ml-4 mt-4">Compare Snapshot</p>
        <p class="PaneText">Compare an rpv-web snapshot to another one. The diff is opened in a separate pane and does not
        overwrite the currently available RPC information.</p>
        <input ref="CompareSnapShotOne" class="ml-4" style="color: white;" type="file">
        <input ref="CompareSnapShotTwo" class="d-inline-block ml-4 mb-2" style="color: white;" type="file">
        <button class="btn float-right mr-5" @click="compareSnapshots()">Compare</button>
    </div>
</template>

<style>
    #RpvHeadline {
        padding-left: 20px !important;
        margin-bottom: 1% !important;
        width: 100%;
        min-height: 10%;
    }

    #LeftHeadline {
        width: 50%;
        float: left;
    }

    #RightHeadline {
        width: 50%;
        float: right;
    }

    #Logo {
        font-size: 33pt;
        max-height: 60px;
        margin-bottom: 0;
    }

    #LogoPng {
        width: 32px;
        height: 32px;
    }

    #Web {
        font-size: 8pt;
        max-height: 60px;
        margin-bottom: 0;
    }

    .FloatingPane {
        width: 30%;
        height: 80%;
        position: absolute;
        top: 10%;
        left: 35%;
        background-color: #24292f;
        border-radius: 25px;
        border: solid white;
        box-shadow: 0 0 20px;
        overflow: auto;
    }

    .PaneOption {
        margin-top: 2%;
        color: white;
        font-size: 12pt;
    }

    .PaneText {
        margin-top: 2%;
        color: white;
        padding: 0 5% 2% 5%;
        font-size: 10pt;
    }

    .HeadlineButton {
        margin-top: 2%;
        margin-right: 5%;
        float: right;
    }

    .FloatingPaneHeadline {
        margin-top: 2%;
        margin-left: 4%;
        color: white;
        font-size: 20pt;
    }

    .FloatingPaneExit {
        float: right;
        margin-top: 3%;
        margin-right: 4%;
        font-size: 10pt;
    }
</style>
