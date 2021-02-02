//
//  SImpleTaskViewController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/28.
//

import UIKit

class SimpleTaskViewController: UIViewController {
    var viewModel: SimpleTaskViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    var count: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func buttonPressed() {
        viewModel?.clearTask()
    }
}

extension SimpleTaskViewController: SimpleTaskViewModelDelegate {
    func finishSimpleTask() {
        dismiss(animated: true, completion: nil)
    }
}
