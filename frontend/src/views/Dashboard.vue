<script setup>
    import MethodPane from '../components/MethodPane.vue'
    import ServerPane from '../components/ServerPane.vue'
    import ProcessPane from '../components/ProcessPane.vue'
    import EndpointPane from '../components/EndpointPane.vue'
    import InterfacePane from '../components/InterfacePane.vue'
    import InterfaceDetailPane from '../components/InterfaceDetailPane.vue'
</script>

<template>
    <div class="LeftPane">
        <ProcessPane />
    </div>

    <div class="RightPane">

        <div class="SubPane1">
            <div class="LeftPane">
                <ServerPane />
            </div>

            <div class="RightPane">
                <EndpointPane />
            </div>
        </div>

        <InterfacePane />

        <div class="SubPane2">
            <div class="LeftPane">
                <InterfaceDetailPane />
            </div>

            <div class="RightPane">
                <MethodPane />
            </div>
        </div>
    </div>
</template>

<style>
    .LeftPane {
        float: left;
        width: 45%;
        height: 85%;
        margin-right: 2%;
    }

    .RightPane {
        float: right;
        width: 53%;
        height: 85%;
    }

    .SubPane1 {
        width: 100%;
        height: 30%;
        margin-bottom: 2%;
    }

    .SubPane2 {
        width: 100%;
        height: 39%;
    }
</style>
