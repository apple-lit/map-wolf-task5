//
//  CommonTask4ViewController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/02/01.
//

import UIKit

class CommonTask4ViewController: UIViewController {
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

extension CommonTask4ViewController: SimpleTaskViewModelDelegate {
    func finishSimpleTask() {
        dismiss(animated: true, completion: nil)
    }
}
