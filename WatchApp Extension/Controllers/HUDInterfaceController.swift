//
//  HUDInterfaceController.swift
//  WatchApp Extension
//
//  Created by Bharat Mediratta on 6/29/18.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import WatchKit

class HUDInterfaceController: WKInterfaceController {
    private var activeContextObserver: NSObjectProtocol?

    @IBOutlet weak var loopHUDImage: WKInterfaceImage!
    @IBOutlet weak var glucoseLabel: WKInterfaceLabel!
    @IBOutlet weak var eventualGlucoseLabel: WKInterfaceLabel!

    var loopManager = ExtensionDelegate.shared().loopManager

    override func willActivate() {
        super.willActivate()

        update()

        if activeContextObserver == nil {
            activeContextObserver = NotificationCenter.default.addObserver(forName: LoopDataManager.didUpdateContextNotification, object: loopManager, queue: nil) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.update()
                }
            }
        }
    }

    override func didDeactivate() {
        super.didDeactivate()

        if let observer = activeContextObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        activeContextObserver = nil
    }

    func update() {
        guard let activeContext = loopManager.activeContext,
            let date = activeContext.loopLastRunDate
        else {
            loopHUDImage.setLoopImage(.unknown)
            return
        }

        glucoseLabel.setHidden(true)
        eventualGlucoseLabel.setHidden(true)
        if let glucose = activeContext.glucose, let unit = activeContext.preferredGlucoseUnit {
            let formatter = NumberFormatter.glucoseFormatter(for: unit)

            if let glucoseValue = formatter.string(from: glucose.doubleValue(for: unit)) {
                let trend = activeContext.glucoseTrend?.symbol ?? ""
                glucoseLabel.setText(glucoseValue + trend)
                glucoseLabel.setHidden(false)
            }

            if let eventualGlucose = activeContext.eventualGlucose {
                let glucoseValue = formatter.string(from: eventualGlucose.doubleValue(for: unit))
                eventualGlucoseLabel.setText(glucoseValue)
                eventualGlucoseLabel.setHidden(false)
            }
        }

        loopHUDImage.setLoopImage({
            switch date.timeIntervalSinceNow {
            case let t where t > .minutes(-6):
                return .fresh
            case let t where t > .minutes(-20):
                return .aging
            default:
                return .stale
            }
        }())
    }

    @IBAction func addCarbs() {
        presentController(withName: AddCarbsInterfaceController.className, context: nil)
    }

    @IBAction func setBolus() {
        var context = loopManager.activeContext?.bolusSuggestion ?? BolusSuggestionUserInfo(recommendedBolus: nil)

        if context.maxBolus == nil {
            context.maxBolus = loopManager.settings.maximumBolus
        }

        presentController(withName: BolusInterfaceController.className, context: context)
    }

}
