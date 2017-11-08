//
//  ViewController.swift
//  BluetoothConnect
//
//  Created by Rafael Goncalves on 06/11/17.
//  Copyright © 2017 Rafael Goncalves. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var manager:CBCentralManager!
    var peripherals = Array<CBPeripheral>()
    var peri: CBPeripheral!
    fileprivate let data = NSMutableData()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        manager?.stopScan()
    }
    
    func connectBluetooth(peripheral: CBPeripheral){
        manager?.connect(peripheral, options: nil)
    }
    
    
    

}

extension ViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not available.")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil {
            peripherals.append(peripheral)
        }
        print(peripheral)
        tableView.reloadData()
        
    }
    
    /** If the connection fails for whatever reason, we need to deal with it.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        
      //  cleanup()
    }
    /** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        // Stop scanning
        manager?.stopScan()
        print("Scanning stopped")
        
        // Clear the data that we may already have
        data.length = 0
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices(nil)
    }
}

extension ViewController: CBPeripheralDelegate{
    /** The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
          //  cleanup()
            return
        }
        
        guard peripheral.services != nil else {
            return
        }

        if let services = peripheral.services {
            for service in services {
                // 1
                if (service.uuid == CBUUID(string: Device.NOVUS_SERVICE_UUID)) {
                    // 2
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
        
     
    }
    
    /** The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let characteristics = service.characteristics {
            // 1
            var enableValue:UInt8 = 1
            let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
            
            
            // 2
            for characteristic in characteristics {
                // Temperature Data Characteristic
                if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID1) {
                    // 3a
                    // novus characteristic 1
                    let charac = characteristic
                    peri?.setNotifyValue(true, for: charac)
                }
                
                if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID2) {
                    // 3a
                    // novus characteristic 2 FLOW CONTROL???
                   // let charac = characteristic
                   // peri?.setNotifyValue(true, for: charac)
                }
                
                if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID3) {
                    // 3a
                    // novus characteristic 1
                    let charac = characteristic
                    peri?.writeValue(enableBytes as Data, for: charac, type: .withResponse)
                }
            }
        }
        
    }
    
    
    /** This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
       
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        // 1
        // Extract the data from the Characteristic's value property
        // and display the value based on the Characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID1) {
                // 1
                displayTemperature(data: dataBytes as NSData)
            } else if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID2) {
                // 2
                displayTemperature(data: dataBytes as NSData)
            }else if characteristic.uuid == CBUUID(string: Device.NOVUS_CHARACTERISTIC_UUID3){
                // 3
                displayTemperature(data: dataBytes as NSData)
            }
        }
        
    }
    
    
    func displayTemperature(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<UInt16>.size
        
        // 1
        // create an array to contain the 16-bit values
        var dataArray = [UInt16](repeating: 0, count:dataLength)
        
        // 2
        // extract the data from the dataBytes object
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<UInt16>.size)
        
        // 3
        // get the value of the of the ambient temperature element
    //    let rawAmbientTemp:UInt16 = dataArray[Device.SensorDataIndexTempAmbient]
        
        // 4
        // convert the ambient temperature
     //   let ambientTempC = Double(rawAmbientTemp) / 128.0
       // let ambientTempF = convertCelciusToFahrenheit(ambientTempC)
        
        // 5
        // Use the Ambient Temperature reading for our label
        //let temp = Int(ambientTempF)
        //lastTemperature = temp
        
        // If the application is active and in the foreground, update the UI
       // if UIApplication.sharedApplication().applicationState == .Active {
        //    updateTemperatureDisplay()
       // }
    }
    
    /** The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Error changing notification state: \(String(describing: error?.localizedDescription))")
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid.isEqual(transferCharacteristicUUID) else {
            return
        }
        
        // Notification has started
        if (characteristic.isNotifying) {
            print("Notification began on \(characteristic)")
        } else { // Notification has stopped
            print("Notification stopped on (\(characteristic))  Disconnecting")
            manager?.cancelPeripheralConnection(peripheral)
        }
    }
}

extension ViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectPeripheral = self.peripherals[indexPath.row]
    //    self.peri = selectPeripheral
        connectBluetooth(peripheral: selectPeripheral)
        
        self.performSegue(withIdentifier: "goConnect", sender: selectPeripheral)
    }
}

extension ViewController: UITableViewDataSource{
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
}



struct Device {
    //...
    
    static let NOVUS_SERVICE_UUID = "0783B03E-8535-B5A0-7140-A304D2495CB7"//service
    static let NOVUS_CHARACTERISTIC_UUID1 = "0783B03E-8535-B5A0-7140-A304D2495CB7"//ReadData, Notify
    static let NOVUS_CHARACTERISTIC_UUID2 = "0783B03E-8535-B5A0-7140-A304D2495CB7"//FlowControl
    static let NOVUS_CHARACTERISTIC_UUID3 = "0783B03E-8535-B5A0-7140-A304D2495CB7"//WriteData
    
    
    // Temperature UUIDs
    static let TemperatureServiceUUID = "F000AA00-0451-4000-B000-000000000000"
    static let TemperatureDataUUID = "F000AA01-0451-4000-B000-000000000000"
    static let TemperatureConfig = "F000AA02-0451-4000-B000-000000000000"
    
    // Humidity UUIDs
    static let HumidityServiceUUID = "F000AA20-0451-4000-B000-000000000000"
    static let HumitidyDataUUID = "F000AA21-0451-4000-B000-000000000000"
    static let HumidityConfig = "F000AA22-0451-4000-B000-000000000000"
    
    //...
}

