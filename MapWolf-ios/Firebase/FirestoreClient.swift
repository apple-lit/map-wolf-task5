//
//  FirestoreClient.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

public protocol FirestoreModel: Codable {
    static var collectionName: String { get }
    var ref: DocumentReference? { get }
    static var identifier: String { get }
}

public protocol SubCollectionModel {
    static var parentCollectionName: String { get }
}

public protocol FirestoreFilterModel {
    func buildQuery(from ref: Query) -> Query
}

public struct FirestoreFilterEqualModel: FirestoreFilterModel {
    public var fieldPath: String
    public var value: Any

    public func buildQuery(from ref: Query) -> Query {
        ref.whereField(fieldPath, isEqualTo: value)
    }
}

public enum FirestoreClientError: Error {
    case failedToDecode
}

public class FirestoreClient {
    private let firestore = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]

    public func writeTransaction<Model: FirestoreModel>(
        _ model: Model, handler: @escaping ((Model, Model)) -> Model,
        success: @escaping (DocumentReference) -> Void, failure: @escaping (Error) -> Void
    ) {
        guard let ref = model.ref else {
            return
        }
        firestore.runTransaction { transaction, errorPointeer -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard let data = try snapshot.data(as: Model.self) else {
                    return nil
                }
                let newModel = handler((data, model))
                try transaction.setData(from: newModel, forDocument: ref)
            } catch {
                errorPointeer?.pointee = error as NSError
            }
            return nil
        } completion: { _, error in
            if let error = error {
                failure(error)
                return
            }
            success(ref)
        }
    }

    public func write<Model: FirestoreModel>(
        _ model: Model, merge: Bool, success: @escaping (DocumentReference) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        do {
            let ref: DocumentReference
            if let modelRef = model.ref {
                ref = modelRef
            } else {
                ref = firestore.collection(Model.collectionName).document()
            }
            try ref.setData(from: model, merge: merge) { error in
                if let error = error {
                    failure(error)
                    return
                }
                success(ref)
            }
        } catch {
            failure(error)
        }
    }

    public func listen<Model: FirestoreModel>(
        filter: [FirestoreFilterEqualModel], includeCache: Bool = false,
        success: @escaping ([Model]) -> Void, failure: @escaping (Error) -> Void
    ) {
        let listener = createQuery(modelType: Model.self, filter: filter).addSnapshotListener(
            includeMetadataChanges: false
        ) { snapshots, error in
            if let error = error {
                failure(error)
                return
            }
            guard let snapshots = snapshots else {
                return
            }
            if snapshots.metadata.isFromCache, includeCache == false {
                return
            }
            let documents = snapshots.documents
            do {
                let models = try documents.map { document -> Model in
                    guard let model = try document.data(as: Model.self) else {
                        throw FirestoreClientError.failedToDecode
                    }
                    return model
                }
                success(models)
            } catch {
                failure(error)
            }
        }
        listeners[Model.identifier + "s"]?.remove()
        listeners[Model.identifier + "s"] = listener
    }

    public func listen<Model: FirestoreModel>(
        docID: String, includeCache: Bool = false, success: @escaping (Model) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        let listener = firestore.collection(Model.collectionName).document(docID)
            .addSnapshotListener(
                includeMetadataChanges: false
            ) { snapshots, error in
                if let error = error {
                    failure(error)
                    return
                }
                guard let snapshots = snapshots else {
                    return
                }
                if snapshots.metadata.isFromCache, includeCache == false {
                    return
                }
                do {
                    guard let model = try snapshots.data(as: Model.self) else {
                        throw FirestoreClientError.failedToDecode
                    }
                    success(model)
                } catch {
                    failure(error)
                }
            }
        listeners[Model.identifier]?.remove()
        listeners[Model.identifier] = listener
    }

    public func get<Model: FirestoreModel>(
        filter: [FirestoreFilterEqualModel], includeCache: Bool = false,
        success: @escaping ([Model]) -> Void, failure: @escaping (Error) -> Void
    ) {
        createQuery(modelType: Model.self, filter: filter).getDocuments { snapshots, error in
            if let error = error {
                failure(error)
                return
            }
            guard let snapshots = snapshots else {
                return
            }
            if snapshots.metadata.isFromCache, includeCache == false {
                return
            }
            let documents = snapshots.documents
            do {
                let models = try documents.map { document -> Model in
                    guard let model = try document.data(as: Model.self) else {
                        throw FirestoreClientError.failedToDecode
                    }
                    return model
                }
                success(models)
            } catch {
                failure(error)
            }
        }
    }

    public func delete<Model: FirestoreModel>(
        _ model: Model, success: @escaping () -> Void, failure: @escaping (Error) -> Void
    ) {
        guard let ref = model.ref else {
            return
        }
        ref.delete { error in
            if let error = error {
                failure(error)
                return
            }
            success()
        }
    }

    private func createQuery<Model: FirestoreModel>(
        modelType: Model.Type, filter: [FirestoreFilterModel]
    ) -> Query {
        var query: Query = firestore.collection(modelType.collectionName)
        for element in filter {
            query = element.buildQuery(from: query)
        }
        return query
    }

    public func stopListening<Model: FirestoreModel>(type: Model.Type, isDocuments: Bool = false) {
        let key = Model.identifier + (isDocuments ? "s" : "")
        listeners[key]?.remove()
    }

    public func delete<Model: FirestoreModel>(
        id: String, type: Model.Type, completion: ((Error?) -> Void)? = nil
    ) {
        firestore.collection(Model.collectionName).document(id).delete(completion: completion)
    }

    public func batch<Model: FirestoreModel>(
        models: [Model], completion: @escaping (Error?) -> Void
    ) {
        let batch = firestore.batch()
        for model in models {
            let ref: DocumentReference
            if let _ref = model.ref {
                ref = _ref
            } else {
                ref = firestore.collection(Model.collectionName).document()
            }
            do {
                try batch.setData(from: model, forDocument: ref)
            } catch {
                completion(error)
            }
        }
        batch.commit { error in
            if let error = error {
                completion(error)
            }
        }
    }
}

// MARK: SubCollection
extension FirestoreClient {
    public func write<Model: FirestoreModel & SubCollectionModel>(
        _ model: Model, parent parentUid: String, merge: Bool,
        success: @escaping (DocumentReference) -> Void, failure: @escaping (Error) -> Void
    ) {
        do {
            let ref: DocumentReference
            if let modelRef = model.ref {
                ref = modelRef
            } else {
                ref = firestore.collection(Model.parentCollectionName).document(parentUid)
                    .collection(
                        Model.collectionName
                    ).document()
            }
            try ref.setData(from: model, merge: merge) { error in
                if let error = error {
                    failure(error)
                    return
                }
                success(ref)
            }
        } catch {
            failure(error)
        }
    }

    public func get<Model: FirestoreModel & SubCollectionModel>(
        parent parentUid: String, filter: [FirestoreFilterEqualModel], includeCache: Bool = false,
        success: @escaping ([Model]) -> Void, failure: @escaping (Error) -> Void
    ) {
        createQueryOfSubCollection(parent: parentUid, modelType: Model.self, filter: filter)
            .addSnapshotListener(includeMetadataChanges: false) { snapshots, error in
                if let error = error {
                    failure(error)
                    return
                }
                guard let snapshots = snapshots else {
                    return
                }
                if snapshots.metadata.isFromCache, includeCache == false {
                    return
                }
                let documents = snapshots.documents
                do {
                    let models = try documents.map { document -> Model in
                        guard let model = try document.data(as: Model.self) else {
                            throw FirestoreClientError.failedToDecode
                        }
                        return model
                    }
                    success(models)
                } catch {
                    failure(error)
                }
            }
    }

    public func listen<Model: FirestoreModel & SubCollectionModel>(
        parent parentUid: String, filter: [FirestoreFilterEqualModel], includeCache: Bool = false,
        success: @escaping ([Model]) -> Void, failure: @escaping (Error) -> Void
    ) {
        let listener = createQueryOfSubCollection(
            parent: parentUid, modelType: Model.self, filter: filter
        ).addSnapshotListener(includeMetadataChanges: false) { snapshots, error in
            if let error = error {
                failure(error)
                return
            }
            guard let snapshots = snapshots else {
                return
            }
            if snapshots.metadata.isFromCache, includeCache == false {
                return
            }
            let documents = snapshots.documents
            let models = documents.compactMap { document -> Model? in
                guard let model = try? document.data(as: Model.self) else {
                    return nil
                }
                return model
            }
            success(models)
        }
        listeners[Model.identifier + "s"]?.remove()
        listeners[Model.identifier + "s"] = listener
    }

    public func listen<Model: FirestoreModel & SubCollectionModel>(
        parent parentUid: String, docID: String, includeCache: Bool = false,
        success: @escaping (Model) -> Void, failure: @escaping (Error) -> Void
    ) {
        let listener = firestore.collection(Model.parentCollectionName).document(parentUid)
            .collection(
                Model.collectionName
            ).document(docID).addSnapshotListener(includeMetadataChanges: false) {
                snapshot, error in
                if let error = error {
                    failure(error)
                    return
                }
                guard let snapshots = snapshot else {
                    return
                }
                if snapshots.metadata.isFromCache, includeCache == false {
                    return
                }
                do {
                    guard let model = try snapshot?.data(as: Model.self) else {
                        return
                    }
                    success(model)
                } catch {
                    failure(error)
                }
            }
        listeners[Model.identifier]?.remove()
        listeners[Model.identifier] = listener
    }

    public func get<Model: FirestoreModel & SubCollectionModel>(
        parent parentUid: String, docID: String, includeCache: Bool = false,
        success: @escaping (Model) -> Void, failure: @escaping (Error) -> Void
    ) {
        firestore.collection(Model.parentCollectionName).document(parentUid).collection(
            Model.collectionName
        ).document(docID).getDocument { snapshot, error in
            if let error = error {
                failure(error)
                return
            }
            guard let snapshots = snapshot else {
                return
            }
            if snapshots.metadata.isFromCache, includeCache == false {
                return
            }
            do {
                guard let model = try snapshot?.data(as: Model.self) else {
                    return
                }
                success(model)
            } catch {
                failure(error)
            }
        }
    }

    private func createQueryOfSubCollection<Model: FirestoreModel & SubCollectionModel>(
        parent parentUid: String, modelType: Model.Type, filter: [FirestoreFilterModel]
    ) -> Query {
        var query: Query = firestore.collection(modelType.parentCollectionName).document(parentUid)
            .collection(modelType.collectionName)
        for element in filter {
            query = element.buildQuery(from: query)
        }
        return query
    }

    public func batch<Model: FirestoreModel & SubCollectionModel>(
        parent parentUid: String, models: [Model], completion: @escaping (Error?) -> Void
    ) {
        let batch = firestore.batch()
        for model in models {
            let ref: DocumentReference
            if let _ref = model.ref {
                ref = _ref
            } else {
                ref = firestore.collection(Model.parentCollectionName).document(parentUid)
                    .collection(
                        Model.collectionName
                    ).document()
            }
            do {
                try batch.setData(from: model, forDocument: ref)
            } catch {
                completion(error)
            }
        }
        batch.commit { error in
            if let error = error {
                completion(error)
            }
        }
    }
}
