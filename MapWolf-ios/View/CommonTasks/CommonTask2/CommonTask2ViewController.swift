//
//  CommonTask2ViewController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/02/01.
//

import UIKit

class CommonTask2ViewController: UIViewController {
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

extension CommonTask2ViewController: SimpleTaskViewModelDelegate {
    func finishSimpleTask() {
        dismiss(animated: true, completion: nil)
    }
}
