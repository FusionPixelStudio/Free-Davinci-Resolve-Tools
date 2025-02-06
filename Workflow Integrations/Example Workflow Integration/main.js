// NOTE: Follow the security guide while implementing plugin app https://www.electronjs.org/docs/tutorial/security
const {app, BrowserWindow, ipcMain, shell, Menu} = require('electron')
const path = require('path');

const PLUGIN_ID = 'com.AsherRoland.TestWorkflow'

if (process.platform === "darwin") {
    WorkflowIntegration = require(path.join(__dirname, "WorkflowIntegration_Mac.node"));
} else {
    WorkflowIntegration = require(path.join(__dirname, 'WorkflowIntegration_Win.node'));
}

// Cached objects
let resolveObj = null;
let projectManagerObj = null;

// Initialize Resolve interface and returns Resolve object.
async function initResolveInterface() {
    // Initialize resolve interface
    const isSuccess = await WorkflowIntegration.Initialize(PLUGIN_ID);
    if (!isSuccess) {
        logToFile('Error: Failed to initialize Resolve interface!');
        return null;
    }

    // Get resolve interface object
    resolveInterfacObj = await WorkflowIntegration.GetResolve();
    if (!resolveInterfacObj) {
        logToFile('Error: Failed to get Resolve object!');
        return null;
    }

    return resolveInterfacObj
}

// Cleanup Resolve interface.
function cleanup() {
    const isSuccess = WorkflowIntegration.CleanUp();
    if (!isSuccess) {
        logToFile('Error: Failed to cleanup Resolve interface!');
    }

    resolveObj = null;
    projectManagerObj = null;
}

// Gets Resolve object.
async function getResolve() {
    if (!resolveObj) {
        resolveObj = await initResolveInterface();
    }

    return resolveObj;
}

// Gets project manager object.
async function getProjectManager() {
    if (!projectManagerObj) {
        resolve = await getResolve();
        if (resolve) {
            projectManagerObj = await resolve.GetProjectManager();
            if (!projectManagerObj) {
                logToFile('Error: Failed to get ProjectManager object!');
            }
        }
    }

    return projectManagerObj;
}

// Gets current project object.
async function getCurrentProject() {
    curProjManager = await getProjectManager();
    if (curProjManager) {
        currentProject = await curProjManager.GetCurrentProject();
        if (!currentProject) {
            logToFile('Error: Failed to get current project object!');
        }

        return currentProject;
    }

    return null;
}

// Gets media pool object.
async function getMediaPool() {
    currentProject = await getCurrentProject();
    if (currentProject) {
        mediaPool = await currentProject.GetMediaPool();
        if (!mediaPool) {
            logToFile('Error: Failed to get MediaPool object!');
        }

        return mediaPool;
    }

    return null;
}

// Gets the current timeline object
async function getCurrentTimeline() {
    currentProject = await getCurrentProject();
    if (currentProject) {
        timeline = await currentProject.GetCurrentTimeline();
        if (!timeline) {
            logToFile('Error: Failed to get Current Timeline object!')
        }

        return timeline;
    }

    return null;
}

// Gets the current timeline track count
async function getTrackCount(event, trackType) {
    if (typeof trackType !== "string" && trackType) {
        throw new Error("Track Type must be a string!")
        return null;
    } else if (!trackType) {
        throw new Error("Track Type must be provided!")
        return null;
    }
    timeline = await getCurrentTimeline()
    if (timeline) {
        return await timeline.GetTrackCount(trackType);
    }

    return null;
}

// Register resolve event handler functions.
function registerResolveEventHandlers() {
    // Resolve
    ipcMain.handle('resolve:trackCount', getTrackCount);
}

const createWindow = () => {
    const win = new BrowserWindow ({
        height: 500,
        width: 300,
        useContentSize: true,
        show: false,
        icon: path.join(__dirname, 'img/logo.png'),
        webPreferences: {
            preload: path.join(__dirname, 'preload.js')
        }
    });

    // Show the main window once the content is ready and close the loading window
    win.once('ready-to-show', () => {
        win.show()
    })

    win.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
      });
    
    // Hide the menu bar (enable below code to hide menu bar)
    //win.setMenu(null);

    win.on('close', function(e) {
        cleanup();
        app.quit();
    });

    // Load index.html on the window.
    win.loadFile('index.html');

    // Open the DevTools (enable below code to show DevTools)
    //win.webContents.openDevTools();
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
    registerResolveEventHandlers();
    createWindow();
});

// Quit when all windows are closed.
app.on('window-all-closed', function () {
    // On macOS it is common for applications and their menu bar
    // to stay active until the user quits explicitly with Cmd + Q
    if (process.platform !== 'darwin') {
        cleanup();
        app.quit();
    }
});

app.on('activate', function () {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
});