//
//  ClientCredentialsTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/16/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Houston
import MBProgressHUD
import UIKit

class AddClientViewController: UITableViewController, Storyboarded {

    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var relativePathTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var portTableViewCell: UITableViewCell!
    @IBOutlet weak var networkSecurityControl: UISegmentedControl!
    
    /// Custom HTTP headers to be sent with all requests
    var customHeaders: [(key: String, value: String)] = []

    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        if let onConfigAdded = onConfigAdded, let config = config {
            onConfigAdded(config)
        }
    }

    @IBAction func changeSSL(_ sender: UISegmentedControl) {
        sslEnabled = sender.selectedSegmentIndex == 1
    }

    @IBAction func testConnectionAction(_ sender: Any) {
        
        sslEnabled = networkSecurityControl.selectedSegmentIndex == 1
        
        guard
            let nickname = nicknameTextField.text,
            let hostname = hostnameTextField.text,
            let password = passwordTextField.text,
            let portString = portTextField.text,
            let relativePath = relativePathTextField.text
        else { return }
        
        if nickname.isEmpty {
            showAlert(target: self, title: "Nickname cannot be left empty")
            return
        }
        if hostname.isEmpty {
            showAlert(target: self, title: "Hostname cannot be empty")
            return
        }
        if portString.isEmpty {
            showAlert(target: self, title: "Port cannot be empty")
            return
        }
        
        guard let port = Int(portString) else {
            showAlert(target: self, title: "Port must be a numeric type")
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        // Convert headers array to dictionary
        var headersDict: [String: String] = [:]
        for header in customHeaders {
            if !header.key.isEmpty {
                headersDict[header.key] = header.value
            }
        }
        
        guard let tempConfig = ClientConfig(nickname: nickname, hostname: hostname,
                                            relativePath: relativePath, port: port,
                                            password: password, isHTTP: !sslEnabled,
                                            customHeaders: headersDict)
        else {
            MBProgressHUD.hide(for: self.view, animated: true)
            showAlert(target: self, title: "Invalid Config", message: "Unable to parse a valid URL from the config")
            return
        }
        
        tempClient = DelugeClient(config: tempConfig)
        tempClient?.authenticateAndConnect()
            .done { [weak self] in
                guard let self = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                self.view.showHUD(title: "Valid Configuration")
                self.config = tempConfig
            }.catch { [weak self] error in
                guard let self = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                if let error = error as? ClientError {
                    Logger.error(error)
                    showAlert(target: self, title: "Connection failure", message: error.localizedDescription)
                } else {
                    Logger.error(error)
                    showAlert(target: self, title: "Connection failure", message: error.localizedDescription)
                }
            }
    }

    var sslEnabled: Bool = false

    static let storyboardIdentifier = "AddClientVC"

    public var onConfigAdded: ((ClientConfig) -> Void)?

    var config: ClientConfig? {
        didSet {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    var tempClient: DelugeClient?

    deinit {
        Logger.debug("Destroyed")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem?.isEnabled = config != nil

        if let config = config {
            self.title = "Edit Client"
            nicknameTextField.text = config.nickname
            hostnameTextField.text = config.hostname
            relativePathTextField.text = config.relativePath
            portTextField.text = "\(config.port)"
            networkSecurityControl.selectedSegmentIndex = config.isHTTP ? 0 : 1
            passwordTextField.text = config.password
            // Load existing custom headers
            customHeaders = config.customHeaders.map { (key: $0.key, value: $0.value) }
        }
    }
    
    // MARK: - Custom Headers Management
    
    func addHeader() {
        let alert = UIAlertController(title: "Add Custom Header", message: "Enter the header name and value", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Header Name (e.g., X-Custom-Header)"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Header Value"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let headerName = alert.textFields?[0].text, !headerName.isEmpty,
                  let headerValue = alert.textFields?[1].text else { return }
            
            self.customHeaders.append((key: headerName, value: headerValue))
            self.tableView.reloadData()
            // Invalidate the current config since headers changed
            self.config = nil
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func editHeader(at index: Int) {
        let header = customHeaders[index]
        
        let alert = UIAlertController(title: "Edit Custom Header", message: "Modify the header name and value", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = header.key
            textField.placeholder = "Header Name"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { textField in
            textField.text = header.value
            textField.placeholder = "Header Value"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let headerName = alert.textFields?[0].text, !headerName.isEmpty,
                  let headerValue = alert.textFields?[1].text else { return }
            
            self.customHeaders[index] = (key: headerName, value: headerValue)
            self.tableView.reloadData()
            // Invalidate the current config since headers changed
            self.config = nil
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.customHeaders.remove(at: index)
            self.tableView.reloadData()
            // Invalidate the current config since headers changed
            self.config = nil
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0: return 1  // Nickname
            case 1: return 5  // Credentials
            case 2: return 1  // Test Connection
            case 3: return customHeaders.count + 1  // Custom headers + Add button
            default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 3 {
            return "Custom HTTP Headers"
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 3 {
            return "Add custom headers to be sent with all requests to the Deluge server. Useful for authentication proxies."
        }
        return super.tableView(tableView, titleForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // For sections 0-2, use the static cells from storyboard
        if indexPath.section < 3 {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        
        // Section 3: Custom Headers
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HeaderCell")
        
        if indexPath.row < customHeaders.count {
            // Display existing header
            let header = customHeaders[indexPath.row]
            cell.textLabel?.text = header.key
            cell.detailTextLabel?.text = header.value
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.accessoryType = .disclosureIndicator
        } else {
            // "Add Header" row
            cell.textLabel?.text = "Add Header"
            cell.textLabel?.textColor = .systemBlue
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 3 else { return }
        
        if indexPath.row < customHeaders.count {
            editHeader(at: indexPath.row)
        } else {
            addHeader()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only allow editing (swipe to delete) for existing headers
        return indexPath.section == 3 && indexPath.row < customHeaders.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == 3 && indexPath.row < customHeaders.count {
            customHeaders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            // Invalidate the current config since headers changed
            config = nil
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if indexPath.section == 3 {
            return 0
        }
        return super.tableView(tableView, indentationLevelForRowAt: indexPath)
    }
}
