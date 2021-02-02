//
//  SpotTaskHandler.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/27.
//

import Foundation

struct SpotTaskHandler {
    func validate(tasks: [SpotTask], completedTaskIDList: [Int], clearedTask: SpotTask) -> Bool {
        if clearedTask.isSabotaged {
            return true
        }

        guard
            let previous = tasks.sorted(by: { $0.id < $1.id }).filter({
                completedTaskIDList.contains($0.id)
            }).last
        else {
            return true
        }

        if previous.id == clearedTask.id {
            return true
        }

        return false
    }

    func getNextSpotTask(tasks: [SpotTask], completedIDList: [Int]) -> SpotTask? {
        guard
            let previous = tasks.sorted(by: { $0.id < $1.id }).filter({
                completedIDList.contains($0.id)
            })
            .last
        else {
            return tasks.first
        }
        return tasks.first(where: { $0.id == previous.next })
    }

    func getSabotagedIDAndNewTasks(from tasks: [SpotTask], completedTaskIDList: [Int]) -> (
        [SpotTask], Int
    ) {
        let tasks = tasks.sorted(by: { $0.id < $1.id })
        var result: Int = 0

        if let previous = tasks.sorted(by: { $0.id < $1.id }).filter({
            completedTaskIDList.contains($0.id)
        }).last {
            result = previous.next
        }

        var greaterIDTasks = tasks.filter { $0.id >= result }
        greaterIDTasks = greaterIDTasks.map { task in
            var task = task
            task.id += 1
            task.preivous += 1
            task.next += 1
            return task
        }
        return (greaterIDTasks, result)
    }
}
