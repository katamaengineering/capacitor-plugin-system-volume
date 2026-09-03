import Foundation
import AVFoundation
import Capacitor

/// Bridges the JS `VolumeSlider` wrapper to native `SystemVolume` instances.
///
/// Note for host apps: `MPVolumeView` reflects and controls the system output
/// volume, which requires an active `AVAudioSession`. Apps that play audio
/// normally already have one; a silent app may need to activate a `.playback`
/// (or `.ambient`) session for the slider to track real volume.
@objc(CapacitorSystemVolumePlugin)
public class CapacitorSystemVolumePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CapacitorSystemVolumePlugin"
    public let jsName = "CapacitorSystemVolume"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "create", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "destroy", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setStyle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "onResize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "onDisplay", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "onScroll", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getVolume", returnType: CAPPluginReturnPromise)
    ]

    private var sliders: [String: SystemVolume] = [:]

    @objc func create(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("id is required")
            return
        }
        guard let rectObj = call.getObject("rect") else {
            call.reject("rect is required")
            return
        }
        let styleObj = call.getObject("style")
        let rect = CGRect.fromJSObject(rectObj)

        DispatchQueue.main.async {
            self.sliders[id]?.teardown()
            let slider = SystemVolume(id: id, plugin: self, style: styleObj)
            slider.onVolumeChange = { [weak self] value in
                self?.notifyListeners("volumeChange", data: ["value": value])
            }
            slider.mount(rect: rect)
            self.sliders[id] = slider
            call.resolve()
        }
    }

    @objc func destroy(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("id is required")
            return
        }
        DispatchQueue.main.async {
            self.sliders[id]?.teardown()
            self.sliders.removeValue(forKey: id)
            call.resolve()
        }
    }

    @objc func setStyle(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let slider = sliders[id] else {
            call.reject("slider not found")
            return
        }
        slider.updateStyle(call.getObject("style"))
        call.resolve()
    }

    @objc func onResize(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let slider = sliders[id] else {
            call.reject("slider not found")
            return
        }
        guard let rectObj = call.getObject("rect") else {
            call.reject("rect is required")
            return
        }
        slider.updateRender(rect: CGRect.fromJSObject(rectObj))
        call.resolve()
    }

    @objc func onDisplay(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let slider = sliders[id] else {
            call.reject("slider not found")
            return
        }
        guard let rectObj = call.getObject("rect") else {
            call.reject("rect is required")
            return
        }
        slider.rebindTargetContainer(rect: CGRect.fromJSObject(rectObj))
        call.resolve()
    }

    @objc func onScroll(_ call: CAPPluginCall) {
        // The slider is a subview inside the webview's own scroll view, so it
        // tracks page scrolling automatically. Nothing to do.
        call.resolve()
    }

    @objc func getVolume(_ call: CAPPluginCall) {
        call.resolve(["value": AVAudioSession.sharedInstance().outputVolume])
    }
}
