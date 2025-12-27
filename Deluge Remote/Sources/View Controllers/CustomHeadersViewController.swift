//
//  CustomHeadersViewController.swift
//  Deluge Remote
//
//  Created for custom HTTP headers support
//

import UIKit

class CustomHeadersViewController: UITableViewController {
    
    /// The headers being edited (array of key-value tuples for ordering)
    var headers: [(key: String, value: String)] = []
    
    /// Callback when headers are modified
    var onHeadersChanged: (([String: String]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Custom Headers"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HeaderCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddCell")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addHeader))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Convert to dictionary and notify
        var dict: [String: String] = [:]
        for header in headers where !header.key.isEmpty {
            dict[header.key] = header.value
        }
        onHeadersChanged?(dict)
    }
    
    // MARK: - Actions
    
    @objc func addHeader() {
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
            
            self.headers.append((key: headerName, value: headerValue))
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func editHeader(at index: Int) {
        let header = headers[index]
        
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
            
            self.headers[index] = (key: headerName, value: headerValue)
            self.tableView.reloadData()
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.headers.remove(at: index)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HeaderCell")
        let header = headers[indexPath.row]
        cell.textLabel?.text = header.key
        cell.detailTextLabel?.text = header.value
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editHeader(at: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            headers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Add custom HTTP headers to be sent with all requests to the Deluge server. Useful for authentication proxies."
    }
}
