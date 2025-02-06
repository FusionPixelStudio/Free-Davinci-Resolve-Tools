// All of the Node.js APIs are available in the preload process.
// It has the same sandbox as a Chrome extension.
const { contextBridge, ipcRenderer } = require('electron/renderer')

const API = {
  // Resolve
  trackCount: (trackType) => ipcRenderer.invoke('resolve:trackCount', (trackType)), // Function Found in Main. Can be used in app.js
}

contextBridge.exposeInMainWorld('appAPI', API);

window.addEventListener('DOMContentLoaded', () => {
  const replaceText = (selector, text) => {
    const element = document.getElementById(selector)
    if (element) element.innerText = text
  }

  for (const dependency of ['chrome', 'node', 'electron']) {
    replaceText(`${dependency}-version`, process.versions[dependency])
  }
})