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

class BeerventoryViewController: UIViewController  {
    // MARK: - variables/constants
    var filterHandler: ((String?) -> Void)?
    var beerventoryBeers = [AWSBeer]() {
        didSet {
            applyFilter()
        }
    }
    var filteredBeerventoryBeers = [AWSBeer]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    var selectedAWSBeer: AWSBeer!
    var currentBeer: Beer!
    var selectedIndexPath: IndexPath!
    var pickerQuantity = "1"
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    // MARK: Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var searchBar: UISearchBar!

    // MARK: Actions
    
    //MARK: View Lifecycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        let logo = UIImage(named: "BeerventoryLogo.png")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        presentSignInViewController()
        fetchBeerventoryBeers()
        // tableview
        tableView.insertSubview(self.refreshControl, at: 1)
        // ui stuff
        let searchbarBackground = UIView()
        searchbarBackground.backgroundColor = UIColor(red: 235/255, green: 171/255, blue: 28/255, alpha: 1)
        tableView.backgroundView = searchbarBackground
        applyFilter()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchBeerventoryBeers()
        applyFilter()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    //MARK: - Methods
    func fetchBeerventoryBeers() {
        if AWSSignInManager.sharedInstance().isLoggedIn {
            DynamodbAPI.sharedInstance.queryWithPartitionKeyWithCompletionHandler { (response, error) in
                if let erro = error {
                    print("error: \(erro)")
                } else if response?.items.count == 0 {
                    print("No items")
                    self.beerventoryBeers = []
                } else {
                    print("success: \(response!.items.count) items")
                    self.beerventoryBeers = response!.items.map { $0 as! AWSBeer }
                    .sorted(by: { $0.beer().name < $1.beer().name })
                }
            }
        }
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        fetchBeerventoryBeers()
        refreshControl.endRefreshing()
    }
    
    func handleCancel(alertView: UIAlertAction!) {
        // do cancel stuff here
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailsViewController = (segue.destination as? DetailsController) {
            detailsViewController.beer = currentBeer
        }
    }
    
    func checkButtonTapped(sender: AnyObject) {
        let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: buttonPosition)
        selectedIndexPath = indexPath!
    }

    func showPickerInActionSheet(sender: AnyObject) {
        pickerQuantity = "1"
        checkButtonTapped(sender: sender)
        selectedAWSBeer = beerventoryBeers[selectedIndexPath.row]
        currentBeer = selectedAWSBeer.beer()
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
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        //Create a frame (placeholder/wrapper) for the picker and then create the picker
        var pickerFrame: CGRect = CGRect(x: 10, y: 52, width: screenWidth - 40, height: 160) 
        var picker: UIPickerView = UIPickerView(frame: pickerFrame)
        //set the pickers datasource and delegate
        picker.delegate = self
        picker.dataSource = self
        //Add the picker to the alert controller
        alert.view.addSubview(picker)
        //add buttons to the view
        var buttonCancelFrame: CGRect = CGRect(x: 10, y: 200, width: 100, height: 30) //size & position of the button as placed on the toolView
        //Create the cancel button & set its title
        var buttonCancel: UIButton = UIButton(frame: buttonCancelFrame)
        buttonCancel.setTitle("Cancel", for: UIControlState.normal)
        buttonCancel.setTitleColor(UIColor(red: 200/255, green: 147/255, blue: 49/255, alpha: 1), for: UIControlState.normal)
        //Add the target - target, function to call, the event witch will trigger the function call
        buttonCancel.addTarget(self, action: #selector(cancelSelection), for: UIControlEvents.touchDown)
        //add buttons to the view
        var buttonOkFrame: CGRect = CGRect(x: screenWidth - 120, y:  200, width: 100, height: 30) 
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
        self.selectedAWSBeer._beer = currentBeer.beerData
        DynamodbAPI.sharedInstance.updateBeer(awsBeer: selectedAWSBeer, completioHandler: {
            self.dismiss(animated: true, completion: {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
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
        // Remove if <1 and fetch updated AWS beers
        if self.currentBeer.quantity < 1 {
            DynamodbAPI.sharedInstance.removeBeer(awsBeer: selectedAWSBeer, completioHandler: {
                self.dismiss(animated: true, completion: {
                    self.fetchBeerventoryBeers()
                })
            })
            let alertController2 = UIAlertController(title: "\(self.currentBeer.name) removed", message: "You drank all of your \(self.currentBeer.name). Go get some more!", preferredStyle: UIAlertControllerStyle.alert)
            alertController2.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController2, animated: true, completion: nil)
        // Update if just different and save AWS beer
        } else {
            self.selectedAWSBeer._beer = currentBeer.beerData
            DynamodbAPI.sharedInstance.updateBeer(awsBeer: selectedAWSBeer, completioHandler: {
                self.dismiss(animated: true, completion: {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
            })
        }
    }
    
    func cancelSelection(sender: UIButton){
        print("Cancel");
        self.dismiss(animated: true, completion: nil);
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
            beerventoryBeers = [AWSBeer]()
            let loginStoryboard = UIStoryboard(name: "SignIn", bundle: nil)
            let loginController: SignInViewController = loginStoryboard.instantiateViewController(withIdentifier: "SignIn") as! SignInViewController
            loginController.didCompleteSignIn = onSignIn
            let navController = UINavigationController(rootViewController: loginController)
            navigationController?.present(navController, animated: true, completion: nil)
        } else {
            //
        }
    }
    
    func applyFilter() {
        guard let searchText = searchBar.text?.lowercased(), !searchText.isEmpty, beerventoryBeers.count > 0 else {
            filteredBeerventoryBeers = beerventoryBeers.sorted(by: { $0.beer().name < $1.beer().name })
            filterHandler?(nil)
            return
        }
        filteredBeerventoryBeers = beerventoryBeers.filter { $0.beer().name.lowercased().contains(searchText)}
            .sorted(by: { $0.beer().name < $1.beer().name })
        filterHandler?(searchText)
    }
}

// MARK: - UIPicker delegate
extension BeerventoryViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerQuantity = String(row + 1)
    }
}

// MARK: - UIPicker delegate
extension BeerventoryViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row + 1)
    }
}

// MARK: - tableView data source
extension BeerventoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredBeerventoryBeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let beerventoryTableCell = self.tableView!.dequeueReusableCell(withIdentifier: "BeerventoryTableCell", for: indexPath) as! BeerventoryTableCell
        let awsBeer = filteredBeerventoryBeers[indexPath.row]
        let beer = awsBeer.beer()
        // cell details
        beerventoryTableCell.beerNameLabel.text = beer.name
        beerventoryTableCell.beerStyle.text = beer.style_name
        beerventoryTableCell.breweryNameLabel.text = beer.brewery_name
        beerventoryTableCell.abvLabel.text = "\(beer.abv)%"
        beerventoryTableCell.beerQuantity.text = String(beer.quantity)
        beerventoryTableCell.addBeerButton.tag = 1
        beerventoryTableCell.removeBeerButton.tag = 2
        beerventoryTableCell.addBeerButton.addTarget(self, action: #selector(showPickerInActionSheet), for: .touchUpInside)
        beerventoryTableCell.removeBeerButton.addTarget(self, action: #selector(showPickerInActionSheet), for: .touchUpInside)
        return beerventoryTableCell
    }
}


// MARK: - tableView delegate
extension BeerventoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAWSBeer = filteredBeerventoryBeers[indexPath.row]
        currentBeer = selectedAWSBeer.beer()
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "DetailsViewController", sender: self)
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if let beerventoryTableCell = cell as? BeerventoryTableCell {
//            // cell formatting
//            beerventoryTableCell.mainBackground.layer.cornerRadius = 8
//            //myCell.mainBackground.layer.masksToBounds = true
//            beerventoryTableCell.totalBackground.layer.cornerRadius = 8
//            //myCell.totalBackground.layer.masksToBounds = true
//            beerventoryTableCell.shadowLayer.layer.masksToBounds = false
//            beerventoryTableCell.shadowLayer.layer.shadowOffset = CGSize.zero
//            beerventoryTableCell.shadowLayer.layer.shadowColor = UIColor.black.cgColor
//            beerventoryTableCell.shadowLayer.layer.shadowOpacity = 0.5
//            beerventoryTableCell.shadowLayer.layer.shadowRadius = 2
//            beerventoryTableCell.shadowLayer.layer.shadowPath = UIBezierPath(roundedRect: beerventoryTableCell.shadowLayer.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8, height: 8)).cgPath
//            beerventoryTableCell.shadowLayer.layer.shouldRasterize = false
//            beerventoryTableCell.shadowLayer.layer.rasterizationScale = UIScreen.main.scale
//        }
//    }
}

// MARK: - Search bar delegate
extension BeerventoryViewController: UISearchBarDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter()
        //tableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - BeerventoryTableCell
class BeerventoryTableCell: UITableViewCell {
    
    @IBOutlet var beerNameLabel: UILabel!
    @IBOutlet var beerStyle: UILabel!
    @IBOutlet var breweryNameLabel: UILabel!
    @IBOutlet var abvLabel: UILabel!
    @IBOutlet var gravityLabel: UILabel!
    @IBOutlet var beerQuantity: UILabel!
    
    @IBOutlet var shadowLayer: UIView!
    @IBOutlet var mainBackground: UIView!
    @IBOutlet var totalBackground: UIView!
    
    @IBOutlet var addBeerButton: UIButton!
    @IBOutlet var removeBeerButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

