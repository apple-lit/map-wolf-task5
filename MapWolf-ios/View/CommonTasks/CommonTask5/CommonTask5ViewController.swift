//
//  CommonTask5ViewController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/02/01.
//

import UIKit

class CommonTask5ViewController: UIViewController {
    @IBOutlet var label: UILabel!
    var count: Float = 0.0
    var timer = Timer()
    var timerDisplayed = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func start() {
        if !timer.isValid {
            print("start")
            // タイマーが動いてなかったら動かす
            timer = Timer.scheduledTimer(
                timeInterval: 0.01, target: self, selector: #selector(self.up), userInfo: nil,
                repeats: true)
            label.text = String(count)
        }
    }
    @IBAction func stop() {
        if timer.isValid {
            timer.invalidate()
            label.isHidden = false
            if count > 4.90 && count < 5.10 {
                viewModel?.clearTask()
                print("clear")
            }
        }
    }
    @IBAction func reset() {
        timer.invalidate()
        count = 0
        label.text = String(count)
        //        viewModel?.clearTask()
    }
    @objc func up() {
        count = count + 0.01
        label.text = String(format: "%.2f", count)
        if count > 3.00 {
            label.isHidden = true
        }
    }

    var viewModel: SimpleTaskViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }
}

extension CommonTask5ViewController: SimpleTaskViewModelDelegate {
    func finishSimpleTask() {
        dismiss(animated: true, completion: nil)
    }
}
