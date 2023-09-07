<script>
    export default
    {
        props: ['error', 'class'],
    }
</script>

<template>
    <p v-if="error !== null && !error" :class="class" style="color: green;">Success.</p>
    <p v-if="error !== null && error" :class="class" style="color: red;">Error.</p>
</template>
