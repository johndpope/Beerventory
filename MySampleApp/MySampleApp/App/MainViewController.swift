//
//  MainViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.18
//

import UIKit
import AWSDynamoDB
import AWSMobileHubHelper
import SwiftyJSON

class MainViewController: UIViewController  {
    // MARK: - variables/constants
    var mainBeerStore = [AWSBeer]()
    
    var alertTextField = UITextField()
//    var filterAllBeers: Variable<[Beer]> = Variable([])
//    var tableViewBeers: Variable<[Beer]> = Variable([])
    var currentAWSBeer: AWSBeer!
    var currentBeer: Beer!
    var currentBeerIndexPath: IndexPath!
    var pickerQuantity = "1"
    let searchDispCont = UISearchController(searchResultsController: nil)
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    // MARK: Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet var settingsButton: UIBarButtonItem!
    
    // MARK: Actions
    
    
    // MARK: - Initializers
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        let logo = UIImage(named: "logo2.png")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        presentSignInViewController()
//        if AWSSignInManager.sharedInstance().isLoggedIn {
//            mainBeerStore = [AWSBeer]()
//            queryWithPartitionKeyWithCompletionHandler { (response, error) in
//                if let erro = error {
//                    //self.NoSQLResultLabel.text = String(erro)
//                    print("error: \(erro)")
//                } else if response?.items.count == 0 {
//                    //self.NoSQLResultLabel.text = String("0")
//                    print("No items")
//                } else {
//                    //self.NoSQLResultLabel.text = String(response!.items)
//                    print("success: \(response!.items)")
//                    self.updateItemstoStore(items: response!.items) {
//                        DispatchQueue.main.async(execute: {
//                            self.tableView.reloadData()
//                        })
//                    }
//                }
//            }
//        }
        // tableview
        tableView.delegate = self
        tableView.dataSource = self
        tableView.insertSubview(self.refreshControl, at: 1)
        // status bar
        let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
        statusBarView.backgroundColor = UIColor(red: 235/255, green: 171/255, blue: 28/255, alpha: 1)
        // search results tableview
        searchDispCont.searchResultsUpdater = self
        searchDispCont.searchBar.delegate = self
        searchDispCont.dimsBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        searchDispCont.hidesNavigationBarDuringPresentation = false
        tableView.tableHeaderView = searchDispCont.searchBar
        searchDispCont.searchBar.backgroundColor = UIColor(red: 235/255, green: 171/255, blue: 28/255, alpha: 1)
        searchDispCont.searchBar.searchBarStyle = .minimal
        searchDispCont.searchBar.placeholder = "Filter"
        searchDispCont.searchBar.returnKeyType = UIReturnKeyType.search
        // ui stuff
        let searchbarBackground = UIView()
        searchbarBackground.backgroundColor = UIColor(red: 235/255, green: 171/255, blue: 28/255, alpha: 1)
        tableView.backgroundView = searchbarBackground

        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        print("MainViewController will appear")
        presentSignInViewController()
        if AWSSignInManager.sharedInstance().isLoggedIn {
            mainBeerStore = [AWSBeer]()
            queryWithPartitionKeyWithCompletionHandler { (response, error) in
                if let erro = error {
                    //self.NoSQLResultLabel.text = String(erro)
                    print("error: \(erro)")
                } else if response?.items.count == 0 {
                    //self.NoSQLResultLabel.text = String("0")
                    print("No items")
                } else {
                    //self.NoSQLResultLabel.text = String(response!.items)
                    print("success: \(response!.items.count) items")
                    self.updateItemstoStore(items: response!.items) {
                        DispatchQueue.main.async(execute: {
                            self.tableView.reloadData()
                        })
                    }
                }
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //mainBeerStore.saveChanges()
    }
    
    //MARK: Imperative methods
    func queryWithPartitionKeyDescription() -> String {
        let partitionKeyValue = AWSIdentityManager.default().identityId!
        return "Find all items with userId = \(partitionKeyValue)."
    }
    func queryWithPartitionKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        if let userId = AWSIdentityManager.default().identityId {
            let objectMapper = AWSDynamoDBObjectMapper.default()
            let queryExpression = AWSDynamoDBQueryExpression()
            
            queryExpression.keyConditionExpression = "#userId = :userId"
            queryExpression.expressionAttributeNames = ["#userId": "userId",]
            queryExpression.expressionAttributeValues = [":userId": userId,]
            
            objectMapper.query(AWSBeer.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
                DispatchQueue.main.async(execute: {
                    completionHandler(response, error as? NSError)
                })
            }
        }
    }
    func updateItemstoStore(items: [AWSDynamoDBObjectModel], onCompletion: () -> Void) {
        for item in items {
            let awsBeer = item as! AWSBeer
            mainBeerStore.append(awsBeer)
            var sortedMainBeerStore = [Beer]()
            for item in mainBeerStore {sortedMainBeerStore.append(item.returnBeerObject())}
            sortedMainBeerStore.sort() { $0.name < $1.name }
            mainBeerStore = [AWSBeer]()
            for beerItem in sortedMainBeerStore { mainBeerStore.append(beerItem.awsBeer()) }
            //print("\(mainBeerStore.count) items in beer store")
        }
        onCompletion()
    }
    func handleRefresh(refreshControl: UIRefreshControl) {
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...
        if AWSSignInManager.sharedInstance().isLoggedIn {
            mainBeerStore = [AWSBeer]()
            queryWithPartitionKeyWithCompletionHandler { (response, error) in
                if let erro = error {
                    //self.NoSQLResultLabel.text = String(erro)
                    print("error: \(erro)")
                } else if response?.items.count == 0 {
                    //self.NoSQLResultLabel.text = String("0")
                    print("No items")
                } else {
                    //self.NoSQLResultLabel.text = String(response!.items)
                    print("success: \(response!.items.count) items")
                    self.updateItemstoStore(items: response!.items) {
                        DispatchQueue.main.async(execute: {
                            self.tableView.reloadData()
                        })
                    }
                }
            }
        }
        refreshControl.endRefreshing()
    }
    func handleCancel(alertView: UIAlertAction!) {
        // do cancel stuff here
    }
//    func filterContentForSearchText(searchText: String) {
//        // Filter the array using the filter method
//        if self.mainBeerStore.allBeers.value == [] {
//            self.filterAllBeers.value = []
//            return
//        }
//        self.filterAllBeers.value = self.mainBeerStore.allBeers.value.filter({( beer: Beer) -> Bool in
//            // to start, let's just search by name
//            return beer.name.lowercased().range(of: searchText.lowercased()) != nil
//        })
//        print(filterAllBeers.value)
//    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "detailsViewController") {
            let yourNextViewController = (segue.destination as! DetailsController)
            yourNextViewController.beer = currentBeer
        }
    }
    func checkButtonTapped(sender:AnyObject) {
        let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: buttonPosition)
        currentBeerIndexPath = indexPath!
    }
    func configureTextField(alertTextField: UITextField?) {
        if let textField = alertTextField {
            textField.placeholder = "Enter quantity"
            textField.text = "1"
            textField.keyboardType = UIKeyboardType.numberPad
            self.alertTextField = textField
        }
    }
//    func updateBeerQuantity(indexPath: IndexPath){
//        tableViewBeers.value[indexPath.row] = currentBeer
//        self.mainBeerStore.updateBeerQuantity(updatedBeer: self.currentBeer)
//        self.mainBeerStore.saveChanges()
//        self.searchDisplayController!.searchResultsTableView.reloadData()
//        tableView.reloadData()
//    }
//    func removeBeerFromStore(indexPath: IndexPath) {
//        tableViewBeers.value[indexPath.row] = currentBeer
//        self.mainBeerStore.removeBeer(beer: self.currentBeer)
//        self.mainBeerStore.saveChanges()
//        self.searchDisplayController!.searchResultsTableView.reloadData()
//        tableView.reloadData()
//    }
    func showPickerInActionSheet(sender: AnyObject) {
        pickerQuantity = "1"
        checkButtonTapped(sender: sender)
        //print(tableViewBeers.value)
        print(currentBeerIndexPath.row)
        currentAWSBeer = mainBeerStore[currentBeerIndexPath.row]
        currentBeer = currentAWSBeer.returnBeerObject()
        var actionType: String
        var actionTitle: String
        if sender.tag == 1 {
            actionType = "add"
            actionTitle = "Add"
        } else {
            actionType = "remove"
            actionTitle = "Remove"
        }
        print("\(actionTitle) \(currentBeer.name)")
        var title = "\(actionTitle) \(currentBeer.name)"
        var message = "Enter quantity of beers to \(actionType)\n\n\n\n\n\n\n\n\n\n"
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.isModalInPopover = true
        //Create a frame (placeholder/wrapper) for the picker and then create the picker
        var pickerFrame: CGRect = CGRect(x: 17, y: 52, width: 270, height: 160); // CGRectMake(left), top, width, height) - left and top are like margins
        var picker: UIPickerView = UIPickerView(frame: pickerFrame);
        //set the pickers datasource and delegate
        picker.delegate = self
        picker.dataSource = self
        //Add the picker to the alert controller
        alert.view.addSubview(picker)
        //add buttons to the view
        var buttonCancelFrame: CGRect = CGRect(x: 0, y: 200, width: 100, height: 30) //size & position of the button as placed on the toolView
        //Create the cancel button & set its title
        var buttonCancel: UIButton = UIButton(frame: buttonCancelFrame)
        buttonCancel.setTitle("Cancel", for: UIControlState.normal)
        buttonCancel.setTitleColor(UIColor(red: 200/255, green: 147/255, blue: 49/255, alpha: 1), for: UIControlState.normal)
        //Add the target - target, function to call, the event witch will trigger the function call
        buttonCancel.addTarget(self, action: #selector(cancelSelection), for: UIControlEvents.touchDown)
        //add buttons to the view
        var buttonOkFrame: CGRect = CGRect(x: 170, y:  200, width: 100, height: 30); //size & position of the button as placed on the toolView
        //Create the Select button & set the title
        var buttonOk: UIButton = UIButton(frame: buttonOkFrame)
        if sender.tag == 1 {
            buttonOk.addTarget(self, action: #selector(addBeers), for: UIControlEvents.touchDown);
            buttonOk.setTitle("Add", for: UIControlState.normal);
            buttonOk.setTitleColor(UIColor(red: 200/255, green: 147/255, blue: 49/255, alpha: 1), for: UIControlState.normal)
        } else {
            buttonOk.addTarget(self, action: #selector(removeBeers), for: UIControlEvents.touchDown);
            buttonOk.setTitle("Remove", for: UIControlState.normal);
            buttonOk.setTitleColor(UIColor(red: 200/255, green: 147/255, blue: 49/255, alpha: 1), for: UIControlState.normal)
        }
        alert.view.addSubview(buttonOk)
        alert.view.addSubview(buttonCancel)
        self.present(alert, animated: true, completion: nil);
    }
    func addBeers(sender: UIButton){
        guard let quantity = Int(pickerQuantity) else {
            // handle bad no value or text entry
            return
        }
        self.currentBeer.quantity += quantity
        // update the current aws beer
        self.currentAWSBeer._beer = currentBeer.beerObjectMap()
        let objectMapper = AWSDynamoDBObjectMapper.default()
        objectMapper.save(currentAWSBeer, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("Item saved.")
        })
        self.dismiss(animated: true, completion: {
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        })
    }
    
    func removeBeers(sender: UIButton){
        guard let quantity = Int(pickerQuantity) else {
            // handle bad no value or text entry
            return
        }
        var removedBeer = false
        self.currentBeer.quantity -= quantity
        // Remove if <1
        let objectMapper = AWSDynamoDBObjectMapper.default()
        if self.currentBeer.quantity < 1 {
            removedBeer = true
            objectMapper.remove(self.currentAWSBeer, completionHandler:  {(error: Error?) -> Void in
                if let error = error {
                    print("Amazon DynamoDB Save Error: \(error)")
                    return
                }
                print("Item deleted.")
                self.queryWithPartitionKeyWithCompletionHandler { (response, error) in
                    if let erro = error {
                        //self.NoSQLResultLabel.text = String(erro)
                        print("error: \(erro)")
                    } else if response?.items.count == 0 {
                        //self.NoSQLResultLabel.text = String("0")
                        print("No items")
                    } else {
                        //self.NoSQLResultLabel.text = String(response!.items)
                        print("success: \(response!.items)")
                        self.mainBeerStore = [AWSBeer]()
                        self.updateItemstoStore(items: response!.items) {
                            DispatchQueue.main.async(execute: {
                                self.tableView.reloadData()
                            })
                        }
                    }
                }
            })
        // Update if just different
        } else {
            self.currentAWSBeer._beer = self.currentBeer.beerObjectMap()
            objectMapper.save(currentAWSBeer, completionHandler: {(error: Error?) -> Void in
                if let error = error {
                    print("Amazon DynamoDB Save Error: \(error)")
                    return
                }
                print("Item saved.")
            })
        }
        self.dismiss(animated: true, completion: {
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            if removedBeer {
                let alertController2 = UIAlertController(title: "\(self.currentBeer.name) removed", message: "You drank all of your \(self.currentBeer.name). Go get some more!", preferredStyle: UIAlertControllerStyle.alert)
                alertController2.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                self.present(alertController2, animated: true, completion: nil)
            }
        })
    }
    
    func cancelSelection(sender: UIButton){
        print("Cancel");
        self.dismiss(animated: true, completion: nil);
        // We dismiss the alert. Here you can add your additional code to execute when cancel is pressed
    }
    
    func insertData(beer: Beer) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let itemToCreate: AWSBeer = AWSBeer()
        itemToCreate._userId = AWSIdentityManager.default().identityId!
        itemToCreate._beerEntryId = beer.brewerydb_id
        itemToCreate._beer = beer.beerObjectMap()
        objectMapper.save(itemToCreate, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("Item saved.")
        })
    }
    func onSignIn (_ success: Bool) {
        // handle successful sign in
        if (success) {
            //self.setupRightBarButtonItem()
        } else {
            // handle cancel operation from user
        }
    }
    func presentSignInViewController() {
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            mainBeerStore = [AWSBeer]()
            let loginStoryboard = UIStoryboard(name: "SignIn", bundle: nil)
            let loginController: SignInViewController = loginStoryboard.instantiateViewController(withIdentifier: "SignIn") as! SignInViewController
            loginController.canCancel = false
            loginController.didCompleteSignIn = onSignIn
            let navController = UINavigationController(rootViewController: loginController)
            navigationController?.present(navController, animated: true, completion: nil)
        } else {
            //
        }
    }
}

// MARK: - UIPicker delegate
extension MainViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerQuantity = String(row + 1)
    }
}

// MARK: - UIPicker delegate
extension MainViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 30
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        print(row)
        return String(row + 1)
    }
}

// MARK: - tableView data source
extension MainViewController: UITableViewDataSource {
    //    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        // not implemented
    //    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mainBeerStore.count // add 1 here if want the No More Beers thing
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.tableView.estimatedRowHeight = 135
        // handle all beers
        if indexPath.row < mainBeerStore.count {
            let cell = self.tableView!.dequeueReusableCell(withIdentifier: "MainBeerTableCell", for: indexPath) as! MainBeerTableCell
            let awsBeer = mainBeerStore[indexPath.row]
            let beer = awsBeer.returnBeerObject()
            // cell details
            cell.beerNameLabel.text = beer.name
            cell.beerStyle.text = beer.style_name
            cell.breweryNameLabel.text = beer.brewery_name
            cell.abvLabel.text = "\(beer.abv)%"
            cell.beerQuantity.text = String(beer.quantity)
            cell.addBeerButton.tag = 1
            cell.removeBeerButton.tag = 2
            cell.addBeerButton.addTarget(self, action: #selector(showPickerInActionSheet), for: .touchUpInside)
            cell.removeBeerButton.addTarget(self, action: #selector(showPickerInActionSheet), for: .touchUpInside)
            return cell
        } else {
            let cell = self.tableView!.dequeueReusableCell(withIdentifier: "MainLastCell", for: indexPath) as! MainLastCell
            cell.lastCellLabel.text = "🍻 No more Beers! 🍻"
            return cell
        }
    }
}


// MARK: - tableView delegate
extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 135.0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentAWSBeer = mainBeerStore[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "detailsViewController", sender: self)
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let myCell = cell as? MainBeerTableCell {
            // cell formatting
            myCell.mainBackground.layer.cornerRadius = 8
            //myCell.mainBackground.layer.masksToBounds = true
            myCell.totalBackground.layer.cornerRadius = 8
            //myCell.totalBackground.layer.masksToBounds = true
            myCell.shadowLayer.layer.masksToBounds = false
            myCell.shadowLayer.layer.shadowOffset = CGSize.zero
            myCell.shadowLayer.layer.shadowColor = UIColor.black.cgColor
            myCell.shadowLayer.layer.shadowOpacity = 0.5
            myCell.shadowLayer.layer.shadowRadius = 2
            myCell.shadowLayer.layer.shadowPath = UIBezierPath(roundedRect: myCell.shadowLayer.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8, height: 8)).cgPath
            myCell.shadowLayer.layer.shouldRasterize = false
            myCell.shadowLayer.layer.rasterizationScale = UIScreen.main.scale
        }
    }
}

extension MainViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("search")
        //self.tableView.isScrollEnabled = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel")
        //self.searchDispCont.isActive = false
        //self.searchResultsBeer.value = []
        //self.tableView.reloadData()
    }
}

extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        print("text changed")
        //self.filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

