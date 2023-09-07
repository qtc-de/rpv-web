import './init'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'

import './assets/css/main.css'

import hljs from 'highlight.js/lib/core';
import cpp from 'highlight.js/lib/languages/cpp';
import hljsVuePlugin from "@highlightjs/vue-plugin";

const app = createApp(App)
hljs.registerLanguage('cpp', cpp);

app.use(createPinia())
app.use(hljsVuePlugin)
app.use(router)

app.mount('#app')
