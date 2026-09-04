import Foundation
import AVFoundation
import Capacitor

/// Bridges the JS wrappers to native overlays: `VolumeSlider` → `SystemVolume`
/// (an `MPVolumeView`) and `RoutePicker` → `RoutePicker` (an `AVRoutePickerView`
/// AirPlay button). Both are positioned and torn down through one `overlays` map;
/// only the create + type-specific styling differ.
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
        CAPPluginMethod(name: "createRoutePicker", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "destroy", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setStyle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setRoutePickerStyle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "onResize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "onDisplay", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "onScroll", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getVolume", returnType: CAPPluginReturnPromise)
    ]

    private var overlays: [String: WebOverlay] = [:]

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
            self.overlays[id]?.teardown()
            let slider = SystemVolume(id: id, plugin: self, style: styleObj)
            slider.onVolumeChange = { [weak self] value in
                self?.notifyListeners("volumeChange", data: ["value": value])
            }
            slider.setFrame(rect: rect)
            self.overlays[id] = slider
            call.resolve()
        }
    }

    @objc func createRoutePicker(_ call: CAPPluginCall) {
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
            self.overlays[id]?.teardown()
            let picker = RoutePicker(plugin: self, style: styleObj)
            picker.setFrame(rect: rect)
            self.overlays[id] = picker
            call.resolve()
        }
    }

    @objc func destroy(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("id is required")
            return
        }
        DispatchQueue.main.async {
            self.overlays[id]?.teardown()
            self.overlays.removeValue(forKey: id)
            call.resolve()
        }
    }

    @objc func setStyle(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let slider = overlays[id] as? SystemVolume else {
            call.reject("slider not found")
            return
        }
        slider.updateStyle(call.getObject("style"))
        call.resolve()
    }

    @objc func setRoutePickerStyle(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let picker = overlays[id] as? RoutePicker else {
            call.reject("route picker not found")
            return
        }
        picker.applyStyle(call.getObject("style"))
        call.resolve()
    }

    // Overlays are direct webview subviews, so every position hook — resize,
    // re-show, and page scroll — just repositions to the element's new rect.
    @objc func onResize(_ call: CAPPluginCall) { reposition(call) }
    @objc func onDisplay(_ call: CAPPluginCall) { reposition(call) }
    @objc func onScroll(_ call: CAPPluginCall) { reposition(call) }

    private func reposition(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let overlay = overlays[id] else {
            call.reject("overlay not found")
            return
        }
        guard let rectObj = call.getObject("rect") else {
            call.reject("rect is required")
            return
        }
        overlay.setFrame(rect: CGRect.fromJSObject(rectObj))
        call.resolve()
    }

    @objc func getVolume(_ call: CAPPluginCall) {
        call.resolve(["value": AVAudioSession.sharedInstance().outputVolume])
    }
}
