//
//  DessertsViewModel.swift
//  FetchRewardsTests
//
//  Created by Viktoria Puchko on 15.02.24.
//

import Foundation

protocol DessertsCellViewModelProtocol {
    var dessertsCellViewModel: DessertsTableViewCell.DessertCellViewModel { get set }
}

class DessertsListViewModel: NSObject {
    
    let urlString = "https://www.themealdb.com/api/json/v1/1/filter.php?c=Dessert"
    let dessertDetailURLString = "https://www.themealdb.com/api/json/v1/1/lookup.php?i="
    
    var reloadTableView: (() -> Void)?
    var errorHadling: ((String) -> Void)?
    private var apiService = APIService()
    private var dessertsModel: DessertsListModel!
    private var dessertModel: DessertModel!
    private var imageData = Data()
    //private var errorString = String()
    
    var dessertCellViewModel = [DessertsTableViewCell.DessertCellViewModel]() {
        didSet {
            self.reloadTableView?()
        }
    }
    
    var dessertDetailViewModel: DessertDetailView.DessertDetailViewModel!
    
    func loadDessertsList() {
        self.apiService.getData(urlString: urlString) { dessertsModel in
            let dessertsSortedByName = dessertsModel.desserts.sorted { $0.dessertName < $1.dessertName }
            self.dessertsModel = DessertsListModel(desserts: dessertsSortedByName)
            self.updateData(dessertsModel: self.dessertsModel)
        } onError: { errorString in
            self.errorHadling?(errorString)
        }
    }
    
    func getDessertDetailInfo(dessertID: String) {
        self.apiService.getData(urlString: "\(dessertDetailURLString)\(dessertID)") { dessertsModel in
            let getDessert = dessertsModel.desserts.filter { $0.dessertID == dessertID }
            self.dessertsModel = DessertsListModel(desserts: getDessert)
            self.updateDetailViewData(dessertModel: self.dessertsModel.desserts.first!)
        } onError: { errorString in
            self.errorHadling?(errorString)
        }
    }
    
    func updateData(dessertsModel: DessertsListModel) {
        var cellViewModel = [DessertsTableViewCell.DessertCellViewModel]()
        for dessert in dessertsModel.desserts {
            cellViewModel.append(self.createCellModel(dessert: dessert))
        }
        self.dessertCellViewModel = cellViewModel
    }
    
    func updateDetailViewData(dessertModel: DessertModel) {
        let detailViewModel = self.createDetailViewModel(dessert: dessertModel)
        self.dessertDetailViewModel = detailViewModel
    }
    
    func createCellModel(dessert: DessertModel) -> DessertsTableViewCell.DessertCellViewModel {
        let id = dessert.dessertID
        let name = dessert.dessertName
        let image = dessert.dessertImage
        return DessertsTableViewCell.DessertCellViewModel(dessertName: name, dessertImage: image, dessertID: id)
    }
    
    func createDetailViewModel(dessert: DessertModel) -> DessertDetailView.DessertDetailViewModel {
        let id = dessert.dessertID
        let name = dessert.dessertName
        let instructions = dessert.dessertInstruction
        let ingredientsAndMeasure = dessert.ingredientsAndMeasure
        return DessertDetailView.DessertDetailViewModel(dessertID: id, dessertName: name, dessertInstructions: instructions ?? "", ingredientsAndMeasure: ingredientsAndMeasure)
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> DessertsTableViewCell.DessertCellViewModel {
        return dessertCellViewModel[indexPath.row]
    }
    
    func downloadImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        session.downloadTask(with: url)
            .resume()
    }
}

// MARK: - URLSessionDownloadDelegate for download image
extension  DessertsListViewModel: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let imageData = readDownloadedData(of: location) else { return }
        self.imageData = imageData
    }
    
    // MARK: read downloaded data
    func readDownloadedData(of url: URL) -> Data? {
        do {
            let reader = try FileHandle(forReadingFrom: url)
            let data = reader.readDataToEndOfFile()
                
            return data
        } catch {
            print(error)
            return nil
        }
    }
}


