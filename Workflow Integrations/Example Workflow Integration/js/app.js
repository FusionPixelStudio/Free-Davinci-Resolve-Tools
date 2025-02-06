window.onload = async function () {
    const trackCount = await window.appAPI.trackCount('video')
    console.log(trackCount)
}